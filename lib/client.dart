import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform, Directory;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:stack_trace/stack_trace.dart' show Frame;
import 'package:dart_wormhole_william/dart_wormhole_william.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';
// import 'dart:logging';

typedef NewClientNative = IntPtr Function();
typedef NewClient = int Function();

typedef ClientSendTextNative = Int32 Function(Uint32 goClientId,
    Pointer<Utf8> msg, Pointer<Pointer<Utf8>> codePtr, IntPtr callbackPortId);

typedef ClientSendText = int Function(int goClientId, Pointer<Utf8> msg,
    Pointer<Pointer<Utf8>> codePtr, int callbackPortId);

typedef ClientSendFileNative = Int32 Function(
    Uint32 goClient,
    Pointer<Utf8> fileName,
    Uint32 length,
    Pointer<Int8> fileBytes,
    Pointer<Pointer<Utf8>> codePtr,
    IntPtr callback_port);

typedef ClientSendFile = int Function(int goClientId, Pointer<Utf8> fileName,
    int, Pointer<Utf8>, Pointer<Pointer<Utf8>> codePtr, IntPtr callback_port);

typedef ClientRecvTextNative = Int32 Function(
    Uint32 goClient, Pointer<Utf8> code, Pointer<Pointer<Utf8>> msgPtr);

typedef ClientRecvText = int Function(
    int, Pointer<Utf8> goClientIndex, Pointer<Pointer<Utf8>> msg);

class NativeClient {
  late final DynamicLibrary _wormholeWilliamLib;
  late final DynamicLibrary _asyncCallbackLib;

   NativeClient() {
     _wormholeWilliamLib =
         DynamicLibrary.open(libName("dart_wormhole_william_plugin"));
     _asyncCallbackLib =
         DynamicLibrary.open(libName("bindings", version: "1.0.0"));
   }

   static String libName(String libraryName, {String? version}) {
       final String baseName;

       if (Platform.isMacOS) {
         baseName = "lib$libraryName.dylib";
       } else if (Platform.isWindows) {
         baseName = "lib$libraryName.dll";
       } else {
         baseName = "lib$libraryName.so";
       }

       if (version != null) {
         return "$baseName.$version";
       } else {
         return "$baseName";
       }
     }


  NewClient get newClient {
    return _wormholeWilliamLib
        .lookup<NativeFunction<NewClientNative>>('NewClient')
        .asFunction();
  }

  ClientSendText get clientSendText {
    return _asyncCallbackLib
        .lookup<NativeFunction<ClientSendTextNative>>('client_send_text')
        .asFunction();
  }

  ClientRecvText get clientRecvText {
    return _wormholeWilliamLib
        .lookup<NativeFunction<ClientRecvTextNative>>('ClientRecvText')
        .asFunction();
  }

// ClientRecvText get clientRecvText {
//   return _wormholeWilliamLib
//       .lookup<NativeFunction<ClientSendFileNative>>("ClientSendFile")
//       .asFunction();
// }
}

class SendResult {
  String code;
  Future<void> done;

  SendResult(this.code, this.done);
}

class Client {
  // TODO: should be private but how to test?
  late int goClientId;

  late NativeClient _native;

  Client() {
    _native = NativeClient();
    goClientId = _native.newClient();
  }

  Future<SendResult> sendText(String msg) {
    final done = Completer<void>();
    // TODO: much much is it allocating?
    Pointer<Pointer<Utf8>> codeOut = calloc();

    final rxPort = ReceivePort()
      ..listen((_) => done.complete());

    final statusCode = _native.clientSendText(
        goClientId,
        msg.toNativeUtf8(),
        codeOut,
        rxPort.sendPort.nativePort);

    if (statusCode != 0) {
      throw "Failed to send text. Error code: $statusCode";
    }

    final Pointer<Utf8> code = codeOut.value;
    calloc.free(codeOut);

    final result = SendResult(code.toDartString(), done.future);
    return Future.value(result);
  }

  String recvText(String code) {
    Pointer<Pointer<Utf8>> _msgOut = calloc();
    final int errCode =
        _native.clientRecvText(goClientId, code.toNativeUtf8(), _msgOut);
    // TODO: error handling (errCode != 0)

    final Pointer<Utf8> _msg = _msgOut.value;
    calloc.free(_msgOut);

    // TODO: error handling
    return _msg.toDartString();
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
