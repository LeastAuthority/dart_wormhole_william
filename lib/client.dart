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

typedef NewClientFunc = Int32 Function();
typedef NewClient = int Function();

typedef ClientSendTextNative = Int32 Function(
    Uint32 goClient, Pointer<Utf8> msg, Pointer<Pointer<Utf8>> codePtr, IntPtr);

typedef ClientSendText = int Function(
    int, Pointer<Utf8>, Pointer<Pointer<Utf8>>, int);

typedef ClientSendFileNative = Int32 Function(
    Uint32 goClient,
    Pointer<Utf8> fileName,
    Uint32 length,
    Pointer<Int8> fileBytes,
    Pointer<Pointer<Utf8>> codePtr,
    IntPtr callback_port);

typedef ClientSendFile = int Function(
    int,
    Pointer<Utf8>,
    int,
    Pointer<Int8>,
    Pointer<Pointer<Utf8>>,
    IntPtr callback_port);

typedef ClientRecvTextFunc = Int32 Function(
    Uint32 goClient, Pointer<Utf8> code, Pointer<Pointer<Utf8>> msgPtr);

typedef ClientRecvText = int Function(
    int, Pointer<Utf8> goClientIndex, Pointer<Pointer<Utf8>> msg);

class ClientNative {
  late final DynamicLibrary? _dylib;

  late final NewClient newClient;

  late final Pointer<NativeFunction<ClientSendTextNative>> clientSendText;

  late final ClientRecvText clientRecvText;

  late final ClientSendFile clientSendFile;

  String get dylibPath {
    var libraryName = "dart_wormhole_william_plugin";
    if (Platform.isMacOS) {
      return "lib${libraryName}.dylib";
    } else if (Platform.isWindows) {
      return "lib${libraryName}.dll";
    } else {
      return "lib${libraryName}.so";
    }
  }

  ClientNative() {
    _dylib = DynamicLibrary.open(dylibPath);

    newClient =
        _dylib!.lookup<NativeFunction<NewClientFunc>>('NewClient').asFunction();

    clientSendText = _dylib!
        .lookup<NativeFunction<ClientSendTextNative>>('ClientSendText');
        // .asFunction();

    clientRecvText = _dylib!
        .lookup<NativeFunction<ClientRecvTextFunc>>('ClientRecvText')
        .asFunction();

    // clientSendFile = _dylib!
    //     .lookup<NativeFunction<ClientSendFileNative>>("ClientSendFile")
    //     .asFunction();
  }
}

class SendResult {
  String code;
  Future<void> done;

  SendResult(this.code, this.done);
}

class Client {
  // TODO: should be private but how to test?
  late int goClient;

  late ClientNative _native;

  Client() {
    _native = ClientNative();
    this.goClient = _native.newClient.call();
  }

  Future<SendResult> sendText(String msg) {
    final done = Completer<void>();
    final callbackPort = ReceivePort()
    ..listen((dynamic msg) {
      done.complete(msg);
    });

    Pointer<Pointer<Utf8>> _codeOut = calloc();
    // final Future<SendResult> = _native.clientSendText(...)
    // final int statusCode =
    //     _native.clientSendText(goClient, msg.toNativeUtf8(), _codeOut, callbackPort.sendPort.nativePort);
    // TODO: use facy functional combinators to make this suck less.
    // call something in async_callback that takes _native.clientSendText, the args, the nativeSendPort.

    // callbackPort.sendPort.nativePort
    // also need to pass N args..

    // _native.async(_native.clientSendText.address, watever.sendPort.NativePort);
    final rxPort = ReceivePort()..listen();

    _native.client_send_text(goClient, msg.toNativeUtf8(), _codeOut, rxPort.sendPort.NativePort);

    if (statusCode != 0) {
      throw "Failed to send text. Error code: $statusCode";
    }

    final Pointer<Utf8> _code = _codeOut.value;
    calloc.free(_codeOut);

    final result = SendResult(_code.toDartString(), done.future);
    return Future.value(result);
  }

  String recvText(String code) {
    Pointer<Pointer<Utf8>> _msgOut = calloc();
    final int statusCode =
        _native.clientRecvText(goClient, code.toNativeUtf8(), _msgOut);
    // TODO: error handling (statusCode != 0)

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
