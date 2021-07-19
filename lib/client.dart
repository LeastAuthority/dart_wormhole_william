import 'dart:io' show Platform, Directory;
import 'dart:ffi';

import 'package:stack_trace/stack_trace.dart' show Frame;
import 'package:ffi/ffi.dart';
import 'package:dart_wormhole_william/dart_wormhole_william.dart';
import 'package:path/path.dart' as path;

typedef NewClientFunc = Int32 Function();
typedef NewClient = int Function();

typedef ClientSendTextFunc = Int32 Function(
    Uint32 goClient, Pointer<Utf8> msg, Pointer<Pointer<Utf8>> codePtr);

typedef ClientSendText = int Function(
    int, Pointer<Utf8>, Pointer<Pointer<Utf8>>);

typedef ClientRecvTextFunc = Int32 Function(
    Uint32 goClient, Pointer<Utf8> code, Pointer<Pointer<Utf8>> msgPtr);

typedef ClientRecvText = int Function(
    int, Pointer<Utf8> goClientIndex, Pointer<Pointer<Utf8>> msg);

class ClientNative {
  late final DynamicLibrary? _dylib;

  late final NewClient newClient;

  late final ClientSendText clientSendText;

  late final ClientRecvText clientRecvText;

  String get dylibPath {
    String libraryPath = path.join('libdart_wormhole_william_plugin.so');
    if (Platform.isMacOS) {
      libraryPath = path.join('libdart_wormhole_william_plugin.dylib');
    }
    if (Platform.isWindows) {
      libraryPath = path.join('libdart_wormhole_william_plugin.dll');
    }
    return libraryPath;
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
}
