import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'c_structs.dart';
import 'file.dart';
import 'native_client.dart';

typedef CancelFunc = void Function();

class SendResult {
  String code;
  Future<CallbackResult> done;
  CancelFunc cancel;

  SendResult(this.code, this.done, this.cancel);
}

class PendingDownload {
  int size;
  String fileName;
  CancelFunc Function(File) accept;
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

void defaultErrorHandler(ClientError error) {
  print("Error: ${error.errorCode}, ${error.error}");
}

extension ResultHandling<T> on Completer<T> {
  Future<void> handleResult(dynamic result, Pointer<Void> context,
      NativeClient nativeClient, Future<T> Function(CallbackResult) success,
      {void Function(ClientError) failure = defaultErrorHandler}) async {
    if (result is int) {
      var callbackResult = Pointer<CallbackResult>.fromAddress(result);

      if (callbackResult.ref.errorCode != 0) {
        final error = ClientError(
            callbackResult.ref.errorString == nullptr
                ? "Unknown error"
                : callbackResult.ref.errorString.toDartString(),
            callbackResult.ref.errorCode);
        this.completeError(error);
        failure(error);
      } else {
        this.complete(success(callbackResult.ref));
      }

      this.future.whenComplete(() {
        nativeClient.finalize(context);
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
    final codegeneration = Completer<String>();
    late final Pointer<Void> context;

    final resultPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, context, _native, (callbackResult) async {
          return callbackResult;
        });
      });

    final codegenResultPort = ReceivePort()
      ..listen((dynamic result) {
        if (result is int) {
          Pointer<CodeGenerationResult> resultRef = Pointer.fromAddress(result);
          if (resultRef.ref.resultType == 0) {
            codegeneration
                .complete(resultRef.ref.generated.code.toDartString());
          } else {
            codegeneration.completeError(ClientError(
                resultRef.ref.error.errorString.toDartString(),
                resultRef.ref.resultType));
          }
        }
      });

    context = _native.clientSendText(msg, resultPort.sendPort.nativePort,
        codegenResultPort.sendPort.nativePort);

    return codegeneration.future
        .then((code) => SendResult(code, done.future, () {
              _native.cancelTransfer(context);
            }));
  }

  Future<String> recvText(String code) async {
    final done = Completer<String>();

    late final Pointer<Void> context;

    final resultPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, context, _native, (callbackResult) async {
          return callbackResult.receivedText.toDartString();
        });
      });

    context = _native.clientRecvText(code, resultPort.sendPort.nativePort);

    return done.future;
  }

  static void defaultProgressHandler(dynamic message) {
    if (message is int) {
      var progress = Pointer<Progress>.fromAddress(message);

      print(
          "Transfer progress: ${progress.ref.transferredBytes}/${progress.ref.totalBytes}");
    }
  }

  static Future<int> seekf(File openFile, int offset, int whence) async {
    const SeekStart = 0;
    const SeekCurrent = 1;
    const SeekEnd = 2;

    final position = await openFile.getPosition();
    final int length = (await openFile.metadata()).fileSize!;
    var newPosition;

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
      await openFile.setPosition(newPosition);
      return newPosition;
    } else {
      return position;
    }
  }

  Future<SendResult> sendFile(File file,
      [void Function(dynamic) optProgressFunc = defaultProgressHandler]) async {
    final fileName = (await file.metadata()).fileName!;
    final done = Completer<CallbackResult>();
    late final Pointer<Void> context;

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, context, _native, (callbackResult) async {
          await file.close();
          return callbackResult;
        });
      });

    final progressPort = ReceivePort()..listen(optProgressFunc);

    final readCalls = ReceivePort()
      ..listen((dynamic message) async {
        if (message is int) {
          Pointer<ReadArgs> args = Pointer.fromAddress(message);
          try {
            final bytesRead =
                await file.read(args.ref.buffer.asTypedList(args.ref.length));
            _native.readDone(args.ref.context, bytesRead, null);
          } catch (error) {
            _native.readDone(args.ref.context, -1, error.toString());
          }
        }
      });

    final seekCalls = ReceivePort()
      ..listen((dynamic message) async {
        if (message is int) {
          Pointer<SeekArgs> args = Pointer.fromAddress(message);
          try {
            final newOffset =
                await seekf(file, args.ref.newOffset, args.ref.whence);
            _native.seekDone(args.ref.context, newOffset, null);
          } catch (error) {
            _native.seekDone(args.ref.context, -1, error.toString());
          }
        } else {
          throw Exception("Invalid message sent on seek arguments port");
        }
      });

    final sendResult = Completer<SendResult>();

    final codeGenerationResult = ReceivePort()
      ..listen((dynamic message) async {
        Pointer<CodeGenerationResult> codeGenResult =
            Pointer.fromAddress(message);

        if (codeGenResult.ref.resultType != 0) {
          sendResult.completeError(ClientError(
              codeGenResult.ref.error.errorString.toDartString(),
              codeGenResult.ref.resultType));
        } else {
          sendResult.complete(SendResult(
              codeGenResult.ref.generated.code.toDartString(), done.future, () {
            _native.cancelTransfer(context);
          }));
        }
      });

    context = _native.clientSendFile(
        fileName,
        codeGenerationResult.sendPort.nativePort,
        rxPort.sendPort.nativePort,
        progressPort.sendPort.nativePort,
        readCalls.sendPort.nativePort,
        seekCalls.sendPort.nativePort);
    return sendResult.future;
  }

  Future<ReceiveFileResult> recvFile(String code,
      [void Function(dynamic) optProgressFunc = defaultProgressHandler]) {
    final done = Completer<CallbackResult>();
    final destinationFile = Completer<File>();
    final pendingDownload = Completer<PendingDownload>();
    late final Pointer<Void> context;

    final resultPort = ReceivePort()
      ..listen((dynamic result) async {
        await done.handleResult(result, context, _native,
            (callbackResult) async {
          await destinationFile.future.then((file) async {
            await file.close();
          });
          return callbackResult;
        }, failure: (error) {
          pendingDownload.completeError(error);
        });
      });

    final progressPort = ReceivePort()
      ..listen((message) {
        (optProgressFunc)(message);
      });

    final metadataPort = ReceivePort()
      ..listen((dynamic result) {
        if (result is int) {
          Pointer<FileMetadataStruct> received = Pointer.fromAddress(result);
          pendingDownload.complete(PendingDownload(
              received.ref.size, received.ref.fileName.toDartString(),
              (File destination) {
            destinationFile.complete(destination);
            _native.acceptDownload(context);
            return () {
              _native.cancelTransfer(context);
            };
          }, () {
            _native.rejectDownload(context);
          }));
        }
      });

    final writeBytesPort = ReceivePort()
      ..listen((dynamic msg) async {
        if (msg is int) {
          Pointer<WriteArgs> args = Pointer.fromAddress(msg);
          try {
            await destinationFile.future.then((file) async {
              await file.write(args.ref.buffer.asTypedList(args.ref.length));
            });
            _native.writeDone(args.ref.context, null);
          } catch (error) {
            _native.writeDone(args.ref.context, error.toString());
          }
        }
      });

    context = _native.clientRecvFile(
        code,
        resultPort.sendPort.nativePort,
        progressPort.sendPort.nativePort,
        metadataPort.sendPort.nativePort,
        writeBytesPort.sendPort.nativePort);

    return pendingDownload.future.then((metadata) {
      return ReceiveFileResult(metadata, done.future);
    });
  }
}
