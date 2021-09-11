import 'dart:io' show Platform, Directory;
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:stack_trace/stack_trace.dart' show Frame;
import 'package:dart_wormhole_william/dart_wormhole_william.dart';
import 'package:path/path.dart' as path;
import 'package:ffi/ffi.dart';
// import 'dart:logging';

typedef CallbackNative = Void Function(Pointer<Void> result, Int32 errCode);
// TODO: err codes should eventually be an enum.
typedef Callback = void Function(Pointer<Void> result, int errCode);

typedef NewClientFunc = Int32 Function();
typedef NewClient = int Function();

typedef ClientSendTextFunc = Int32 Function(
    Uint32 goClient, Pointer<Utf8> msg, Pointer<Pointer<Utf8>> codePtr);

typedef ClientSendText = int Function(
    int, Pointer<Utf8>, Pointer<Pointer<Utf8>>);

typedef ClientSendFileNative = Int32 Function(
    Uint32 goClient,
    Pointer<Utf8> fileName,
    Uint32 length,
    Pointer<Int8> fileBytes,
    Pointer<Pointer<Utf8>> codePtr,
    Pointer<NativeFunction<CallbackNative>> callback);

typedef ClientSendFile = int Function(
    int,
    Pointer<Utf8>,
    int,
    Pointer<Int8>,
    Pointer<Pointer<Utf8>>,
    Pointer<NativeFunction<CallbackNative>>);

typedef ClientRecvTextFunc = Int32 Function(
    Uint32 goClient, Pointer<Utf8> code, Pointer<Pointer<Utf8>> msgPtr);

typedef ClientRecvText = int Function(
    int, Pointer<Utf8> goClientIndex, Pointer<Pointer<Utf8>> msg);

class ClientNative {
  late final DynamicLibrary? _dylib;

  late final NewClient newClient;

  late final ClientSendText clientSendText;

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
        .lookup<NativeFunction<ClientSendTextFunc>>('ClientSendText')
        .asFunction();

    clientRecvText = _dylib!
        .lookup<NativeFunction<ClientRecvTextFunc>>('ClientRecvText')
        .asFunction();

    clientSendFile = _dylib!
        .lookup<NativeFunction<ClientSendFileNative>>("ClientSendFile")
        .asFunction();
  }
}

class Client {
  // TODO: should be private but how to test?
  late int goClient;

  late ClientNative _native;

  Client() {
    _native = ClientNative();
    this.goClient = _native.newClient.call();
  }

  String sendText(String msg) {
    Pointer<Pointer<Utf8>> _codeOut = calloc();
    final int statusCode =
        _native.clientSendText(goClient, msg.toNativeUtf8(), _codeOut);

    if (statusCode != 0) {
      throw "Failed to send text. Error code: $statusCode";
    }

    final Pointer<Utf8> _code = _codeOut.value;
    calloc.free(_codeOut);

    return _code.toDartString();
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

  String sendFile(String fileName, int length, Uint8List fileBytes) {
    Pointer<Pointer<Utf8>> codeC = calloc();
    // TODO: use Uint8 instead (?)
    final Pointer<Int8> bytes =
        malloc(length); // Allocator<Int8>.allocate(length);
    // Int8Array(length);

    // TODO: figure out if we can avoid copying data.
    // e.g. Uint8Array
    for (int i = 0; i < fileBytes.length; i++) {
      bytes[i] = fileBytes[i];
    }

    final void Function(Pointer<Void>, int) callback = (Pointer<Void> result, int errCode) {
      final resultInt = result.cast<Int32>();
      print("resultInt: ${resultInt.value}");
    };
    final Pointer<NativeFunction<CallbackNative>> callbackNative = Pointer.fromFunction<CallbackNative>(callback);

    final int statusCode = _native.clientSendFile(
        goClient, fileName.toNativeUtf8(), length, bytes, codeC, callbackNative);
    // TODO: error handling (statusCode != 0)

    final Pointer<Utf8> _msg = codeC.value;
    calloc.free(codeC);

    // TODO: error handling
    return _msg.toDartString();
  }
}
