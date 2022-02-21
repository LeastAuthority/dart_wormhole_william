import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'c_structs.dart';
import 'native_client.dart';

class SendResult {
  String code;
  Future<CallbackResult> done;

  SendResult(this.code, this.done);
}

class PendingDownload {
  int size;
  String fileName;
  void Function(File) accept;
  void Function() reject;

  PendingDownload(this.size, this.fileName, this.accept, this.reject);
}

class ReceiveFileResult {
  PendingDownload pendingDownload;
  Future<CallbackResult> done;

  ReceiveFileResult(this.pendingDownload, this.done);
}

class ClientError {
  String error;
  int errorCode;
  ClientError(this.error, this.errorCode);
  String toString() {
    return "Error code: $errorCode. $error";
  }
}

extension ResultHandling<T> on Completer<T> {
  void handleResult(dynamic result, NativeClient nativeClient,
      T Function(CallbackResult) success) {
    if (result is int) {
      var callbackResult = Pointer<CallbackResult>.fromAddress(result);

      if (callbackResult.ref.errorCode != 0) {
        this.completeError(ClientError(
            callbackResult.ref.errorString == nullptr
                ? "Unknown error"
                : callbackResult.ref.errorString.toDartString(),
            callbackResult.ref.errorCode));
      } else {
        this.complete(success(callbackResult.ref));
      }

      this.future.whenComplete(() {
        nativeClient.freeResult(result);
      });
    } else {
      this.completeError(
          "Result has wrong type. Expected int got ${result.runtimeType}");
    }
  }
}

class Client {
  late NativeClient _native;

  Client(Config config) {
    _native = NativeClient(config: config);
  }

  Future<SendResult> sendText(String msg) async {
    final done = Completer<CallbackResult>();

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, _native, (callbackResult) {
          return callbackResult;
        });
      });

    final codeGenResult =
        _native.clientSendText(msg.toNativeUtf8(), rxPort.sendPort.nativePort);

    try {
      if (codeGenResult.ref.errorCode != 0) {
        throw Exception(
            'Failed to send text. Error code: ${codeGenResult.ref.errorCode}, Error: ${codeGenResult.ref.errorString}');
      }

      return SendResult(codeGenResult.ref.code.toDartString(), done.future);
    } finally {
      _native.freeCodegenResult(codeGenResult.address);
    }
  }

  Future<String> recvText(String code) async {
    final done = Completer<String>();

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, _native, (callbackResult) {
          return callbackResult.receivedText.toDartString();
        });
      });

    final int errCode =
        _native.clientRecvText(code.toNativeUtf8(), rxPort.sendPort.nativePort);
    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      throw Exception('Failed to send text. Error code: $errCode');
    }

    return done.future;
  }

  static void defaultProgressHandler(dynamic message) {
    if (message is int) {
      var progress = Pointer<Progress>.fromAddress(message);

      print(
          "Transfer progress: ${progress.ref.transferredBytes}/${progress.ref.totalBytes}");
    }
  }

  static int seekf(RandomAccessFile openFile, int offset, int whence) {
    print("Seek from dart called with offset:$offset, whence:$whence");
    const SeekStart = 0;
    const SeekCurrent = 1;
    const SeekEnd = 2;

    final position = openFile.positionSync();
    final int length = openFile.lengthSync();
    var newPosition;

    print("Length of file is: $length. Current position is: $position");

    switch (whence) {
      case SeekStart:
        newPosition = offset;
        break;
      case SeekCurrent:
        newPosition = position + offset;
        break;
      case SeekEnd:
        newPosition = length - offset - 1;
        break;
    }

    if (newPosition < length && newPosition >= 0) {
      openFile.setPositionSync(newPosition);
      return newPosition;
    } else {
      return position;
    }
  }

  Future<SendResult> sendFile(File file,
      [void Function(dynamic) optProgressFunc = defaultProgressHandler]) async {
    final fileName = path.basename(file.path);
    final done = Completer<CallbackResult>();

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, _native, (callbackResult) {
          return callbackResult;
        });
      });

    final progressPort = ReceivePort()..listen(optProgressFunc);

    final openFile = file.openSync();

    final readCalls = ReceivePort()
      ..listen((dynamic message) {
        if (message is int) {
          Pointer<ReadArgs> args = Pointer.fromAddress(message);
          _native.readDone(
              args.ref.context,
              openFile
                  .readIntoSync(args.ref.buffer.asTypedList(args.ref.length)));
        }
      });

    final codeGenResult = _native.clientSendFile(
        fileName.toNativeUtf8(),
        rxPort.sendPort.nativePort,
        progressPort.sendPort.nativePort,
        openFile,
        readCalls.sendPort.nativePort,
        Pointer.fromFunction<SeekNative>(seekf, 0));

    try {
      if (codeGenResult.ref.errorCode != 0) {
        return Future.error(ClientError(
            codeGenResult.ref.errorString.toDartString(),
            codeGenResult.ref.errorCode));
      } else {
        return SendResult(codeGenResult.ref.code.toDartString(), done.future);
      }
    } finally {
      _native.freeCodegenResult(codeGenResult.address);
    }
  }

  Future<ReceiveFileResult> recvFile(String code,
      [void Function(dynamic) optProgressFunc = defaultProgressHandler]) async {
    final done = Completer<CallbackResult>();
    final destinationFile = Completer<IOSink>();

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, _native, (callbackResult) {
          destinationFile.future.then((file) {
            file.flush().then((dynamic v) => {file.close()});
          });
          return callbackResult;
        });
      });

    final progressPort = ReceivePort()
      ..listen((message) {
        (optProgressFunc)(message);
      });

    final pendingDownload = Completer<PendingDownload>();

    final metadataPort = ReceivePort()
      ..listen((dynamic result) {
        if (result is int) {
          Pointer<FileMetadataStruct> received = Pointer.fromAddress(result);
          pendingDownload.complete(PendingDownload(
              received.ref.size, received.ref.fileName.toDartString(),
              (File destination) {
            destinationFile
                .complete(destination.openWrite(mode: FileMode.append));
            _native.acceptDownload(received.ref.context);
          }, () {
            // TODO proper error here
            destinationFile
                .completeError(ClientError("Transfer rejected", 123));
            _native.rejectDownload(received.ref.context);
          }));
        }
      });

    final writeBytesPort = ReceivePort()
      ..listen((dynamic msg) async {
        if (msg is int) {
          Pointer<WriteArgs> args = Pointer.fromAddress(msg);
          try {
            await destinationFile.future.then((sink) async {
              sink.add(args.ref.buffer.asTypedList(args.ref.length));
              await sink.flush();
            });
            _native.writeDone(args.ref.context, true);
          } catch (error) {
            print("Error writing bytes");
            _native.writeDone(args.ref.context, false);
          }
        }
      });

    final int errCode = _native.clientRecvFile(
        code.toNativeUtf8(),
        rxPort.sendPort.nativePort,
        progressPort.sendPort.nativePort,
        metadataPort.sendPort.nativePort,
        writeBytesPort.sendPort.nativePort);

    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      throw Exception('Failed to send text. Error code: $errCode');
    }

    return pendingDownload.future.then((metadata) {
      return ReceiveFileResult(metadata, done.future);
    });
  }
}
