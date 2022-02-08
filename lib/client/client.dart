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

class ReceivedFile {
  String fileName;
  Uint8List data;
  ReceivedFile(this.fileName, this.data);
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
            callbackResult.ref.errorString.toDartString(),
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

  Client({Config? config}) {
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

  Future<ReceivedFile> recvFile(String code,
      [void Function(dynamic) optProgressFunc = defaultProgressHandler]) async {
    final done = Completer<ReceivedFile>();

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, _native, (callbackResult) {
          return ReceivedFile(
              callbackResult.file.ref.fileName.toDartString(),
              callbackResult.file.ref.data
                  .asTypedList(callbackResult.file.ref.length));
        });
      });

    final progressPort = ReceivePort()
      ..listen((message) {
        (optProgressFunc)(message);
      });

    final int errCode = _native.clientRecvFile(code.toNativeUtf8(),
        rxPort.sendPort.nativePort, progressPort.sendPort.nativePort);
    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      throw Exception('Failed to send text. Error code: $errCode');
    }

    return done.future;
  }
}
