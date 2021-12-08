import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'file_struct.dart';
import 'native_client.dart';

class SendResult {
  String code;
  Future<void> done;

  SendResult(this.code, this.done);
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
      print("Pointer in dart was: $result");
      var callbackResult = Pointer<CallbackResult>.fromAddress(result);
      print("result was errorCode: ${callbackResult.ref.errorCode}\n"
          "errorString: ${callbackResult.ref.errorString}\n"
          "receivedText: ${callbackResult.ref.receivedText}\n"
          "file: ${callbackResult.ref.file}\n");

      if (callbackResult.ref.errorString != nullptr) {
        print(
            "Error string was ${callbackResult.ref.errorString.toDartString()}");
      }

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
  late Config? _config;

  Client({Config? config}) {
    _native = NativeClient(config: config);
    _config = config;
  }

  Future<SendResult> sendText(String msg) async {
    final done = Completer<void>();
    Pointer<Pointer<Utf8>> codeOut = calloc();

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, _native, (CallbackResult callbackResult) {
          return;
        });
      });

    final errCode = _native.clientSendText(
        msg.toNativeUtf8(), codeOut, rxPort.sendPort.nativePort);

    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      calloc.free(codeOut);
      throw Exception('Failed to send text. Error code: $errCode');
    }

    final Pointer<Utf8> code = codeOut.value;
    calloc.free(codeOut);

    return SendResult(code.toDartString(), done.future);
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

  Future<SendResult> sendFile(File file) async {
    final fileName = path.basename(file.path);
    final length = await file.length();
    final done = Completer<void>();

    Pointer<Pointer<Utf8>> codeOut = calloc();
    // TODO: figure out if we can avoid copying data.
    // e.g. ByteData | ByteBuffer | Uint8Array (?)
    final Pointer<Uint8> nativeBytes =
        malloc(length); // Allocator<Uint8>.allocate(length);
    // Uint8Array(length);

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, _native, (callbackResult) {
          return;
        });
      });

    final fileBytes = await file.readAsBytes();
    for (int i = 0; i < fileBytes.length; i++) {
      nativeBytes[i] = fileBytes[i];
    }

    final int errCode = _native.clientSendFile(fileName.toNativeUtf8(), length,
        nativeBytes, codeOut, rxPort.sendPort.nativePort);
    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      throw Exception(
          'Failed to send file. Error code: $errCode. Config: ${_config.toString()}');
    }

    final Pointer<Utf8> code = codeOut.value;
    calloc.free(codeOut);

    return SendResult(code.toDartString(), done.future);
  }

  Future<Uint8List> recvFile(String code) async {
    final done = Completer<Uint8List>();

    final rxPort = ReceivePort()
      ..listen((dynamic result) {
        done.handleResult(result, _native, (callbackResult) {
          return callbackResult.file.ref.data
              .asTypedList(callbackResult.file.ref.length);
        });
      });

    final int errCode =
        _native.clientRecvFile(code.toNativeUtf8(), rxPort.sendPort.nativePort);
    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      throw Exception('Failed to send text. Error code: $errCode');
    }

    return done.future;
  }
}
