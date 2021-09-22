import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

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
        // // TODO: use error codes enum.
        // if (errCode != 0) {
        //   // TODO: Create exceptions subclass(es) with err code member.
        //   throw Exception('Failed while sending text. Error code: $errCode');
        // }
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
        // TODO: use error codes enum.
        if (errCode != 0) {
          // TODO: Create exceptions subclass(es) with err code member.
          throw Exception('Failed while sending text. Error code: $errCode');
        }
        done.complete();
      });

    final int errCode = _native.clientRecvText(code.toNativeUtf8(), msgOut, rxPort.sendPort.nativePort);
    if (errCode != 0) {
      // TODO: Create exception subclass(es) with err code member.
      throw Exception('Failed to send text. Error code: $errCode');
    }

    final Pointer<Utf8> msg = msgOut.value;
    calloc.free(msgOut);

    // TODO: error handling
    return Future.value(msg.toDartString());
  }

// String sendFile(String fileName, int length, Uint8List fileBytes) {
//   Pointer<Pointer<Utf8>> codeC = calloc();
//   // TODO: use Uint8 instead (?)
//   final Pointer<Int8> bytes =
//       malloc(length); // Allocator<Int8>.allocate(length);
//   // Int8Array(length);
//
//   // TODO: figure out if we can avoid copying data.
//   // e.g. Uint8Array
//   for (int i = 0; i < fileBytes.length; i++) {
//     bytes[i] = fileBytes[i];
//   }
//
//   final void Function(Pointer<Void>, int) callback = (Pointer<Void> result, int errCode) {
//     final resultInt = result.cast<Int32>();
//     print("resultInt: ${resultInt.value}");
//   };
//   final Pointer<NativeFunction<CallbackNative>> callbackNative = Pointer.fromFunction<CallbackNative>(callback);
//
//   final int statusCode = _native.clientSendFile(
//       goClient, fileName.toNativeUtf8(), length, bytes, codeC, callbackNative);
//   // TODO: error handling (statusCode != 0)
//
//   final Pointer<Utf8> _msg = codeC.value;
//   calloc.free(codeC);
//
//   // TODO: error handling
//   return _msg.toDartString();
// }
}
