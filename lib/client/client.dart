import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_wormhole_william/client/exceptions.dart';
import 'package:ffi/ffi.dart';

import 'native_client.dart';

class SendResult {
  String code;
  Future<void> done;

  SendResult(this.code, this.done);
}

class Client {
  late NativeClient _native;

  Client() {
    _native = NativeClient();
  }

  Future<SendResult> sendText(String msg) {
    final done = Completer<void>();
    // TODO: much much is it allocating?
    Pointer<Pointer<Utf8>> codeOut = calloc();

    final rxPort = ReceivePort()
      ..listen((dynamic errCode) {
        if (errCode != 0) {
        // TODO: Create exception implementation(s).
          throw Exception('Failed while sending text. Error code: $errCode');
        }
        done.complete();
      });

    final errCode = _native.clientSendText(
        msg.toNativeUtf8(), codeOut, rxPort.sendPort.nativePort);

    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      throw Exception('Failed to send text. Error code: $errCode');
    }

    final Pointer<Utf8> code = codeOut.value;
    calloc.free(codeOut);

    final result = SendResult(code.toDartString(), done.future);
    return Future.value(result);
  }

  Future<String> recvText(String code) {
    final done = Completer<void>();
    // TODO: much much is it allocating?
    Pointer<Pointer<Utf8>> msgOut = calloc();

    final rxPort = ReceivePort()
      ..listen((dynamic errCode) {
        if (errCode != 0) {
          // TODO: Create exception implementation(s).
          throw Exception('Failed while sending text. Error code: $errCode');
        }
        done.complete();
      });

    final int errCode = _native.clientRecvText(
        code.toNativeUtf8(), msgOut, rxPort.sendPort.nativePort);
    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      throw Exception('Failed to send text. Error code: $errCode');
    }

    final Pointer<Utf8> msg = msgOut.value;
    calloc.free(msgOut);

    return Future.value(msg.toDartString());
  }

  Future<String> sendFile(String fileName, int length, Uint8List fileBytes) {
    final done = Completer<void>();

    Pointer<Pointer<Utf8>> codeC = calloc();
    // TODO: use Uint8 instead (?)
    final Pointer<Uint8> bytes =
        malloc(length); // Allocator<Uint8>.allocate(length);
    // Uint8Array(length);

    // TODO: figure out if we can avoid copying data.
    // e.g. Uint8Array
    for (int i = 0; i < fileBytes.length; i++) {
      bytes[i] = fileBytes[i];
    }

    final rxPort = ReceivePort()
      ..listen((dynamic errCode) {
        if (errCode != 0) {
          // TODO: Create exception implementation(s).
          throw Exception('Failed while sending text. Error code: $errCode');
        }
        done.complete();
      });

    final int errCode = _native.clientSendFile(fileName.toNativeUtf8(),
        length, bytes, codeC, rxPort.sendPort.nativePort);
    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      throw Exception('Failed to send text. Error code: $errCode');
    }

    final Pointer<Utf8> code = codeC.value;
    calloc.free(codeC);

    // TODO: error handling
    return Future.value(code.toDartString());
  }
}
