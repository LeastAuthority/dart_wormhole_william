import 'dart:io' show Platform, Directory;
import 'dart:ffi';

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

  ClientNative() {
    String _libraryPath =
        path.join(Directory.current.path, 'wormhole-william', 'wormhole.so');
    if (Platform.isMacOS) {
      _libraryPath = path.join(
          Directory.current.path, 'wormhole-william', 'wormhole.dylib');
    }
    if (Platform.isWindows) {
      _libraryPath =
          path.join(Directory.current.path, 'wormhole-william', 'wormhole.dll');
    }
    _dylib = DynamicLibrary.open(_libraryPath);

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

class Client extends ClientNative {
  late int goClient;

  Client() {
    // TODO: config
    this.goClient = ClientNative().newClient();
  }

  String sendText(String msg) {
    Pointer<Pointer<Utf8>> _codeOut = calloc();
    final int statusCode =
        ClientNative().clientSendText(goClient, msg.toNativeUtf8(), _codeOut);
    // TODO: error handling (statusCode != 0)

    final Pointer<Utf8> _code = _codeOut.value;
    calloc.free(_codeOut);

    // TODO: error handling
    return _code.toDartString();
  }
}
