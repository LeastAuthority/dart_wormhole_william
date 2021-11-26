import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'native_client.dart';

class SendResult {
  String code;
  Future<void> done;

  SendResult(this.code, this.done);
}

class Client {
  late NativeClient _native;
  late Config? _config;

  Client({Config? config}) {
    _native = NativeClient(config: config);
    _config = config;
  }

  Future<SendResult> sendText(String msg) {
    final done = Completer<void>();
    // TODO: much much is it allocating?
    Pointer<Pointer<Utf8>> codeOut = calloc();

    final rxPort = ReceivePort()
      ..listen((dynamic errCode) {
        if (errCode is int) {
          // TODO: Create exception implementation(s).
          final exception =
              Exception('Failed to send text. Error code: $errCode');
          done.completeError(exception);
          throw exception;
        }
        done.complete();
      });

    final errCode = _native.clientSendText(
        msg.toNativeUtf8(), codeOut, rxPort.sendPort.nativePort);

    if (errCode != 0) {
      // TODO: Create exception implementation(s).
      calloc.free(codeOut);
      final exception = Exception('Failed to send text. Error code: $errCode');
      done.completeError(exception);
      throw exception;
    }

    final Pointer<Utf8> code = codeOut.value;
    calloc.free(codeOut);

    final result = SendResult(code.toDartString(), done.future);
    return Future.value(result);
  }

  Future<String> recvText(String code) {
    final done = Completer<String>();

    final rxPort = ReceivePort()
      ..listen((dynamic response) {
        if (response is int) {
          // TODO: Create exception implementation(s).
          final exception =
              Exception('Failed while sending text. Error code: $response');
          done.completeError(exception);
          throw exception;
        }

        done.complete(String.fromCharCodes(response));
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
    print("File length was: $length");
    final done = Completer<void>();

    Pointer<Pointer<Utf8>> codeOut = calloc();
    // TODO: figure out if we can avoid copying data.
    // e.g. ByteData | ByteBuffer | Uint8Array (?)
    final Pointer<Uint8> nativeBytes =
        malloc(length); // Allocator<Uint8>.allocate(length);
    // Uint8Array(length);

    final rxPort = ReceivePort()
      ..listen((dynamic errCode) {
        print("Got ${errCode}");
        if (errCode is int) {
          // TODO: Create exception implementation(s).
          throw Exception(
              'Failed while sending file. Error code: $errCode. Config: $_config');
        }
        done.complete();
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

  Future<Uint8List> recvFile(String code) {
    final done = Completer<Uint8List>();

    final rxPort = ReceivePort()
      ..listen((dynamic response) {
        if (response is int) {
          // TODO: Create exception implementation(s).
          final exception =
              Exception('Failed while sending text. Error code: $response');
          done.completeError(exception);
        } else if (response is Uint8List) {
          done.complete(response);
        } else {
          done.completeError(
              Exception("Unknown type: ${response.runtimeType}"));
        }
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
