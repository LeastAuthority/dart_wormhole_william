import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';

typedef InitDartApiNative = IntPtr Function(Pointer<Void>);
typedef InitDartApi = int Function(Pointer<Void>);

typedef NewClientNative = IntPtr Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> rendezvousUrl,
    Pointer<Utf8> transitRelayUrl,
    Int32 passPhraseComponentLength);
typedef NewClient = int Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> rendezvousUrl,
    Pointer<Utf8> transitRelayUrl,
    int passPhraseComponentLength);

typedef ClientSendTextNative = Int32 Function(Uint32 goClientId,
    Pointer<Utf8> msg, Pointer<Pointer<Utf8>> codeOut, Int32 callbackPortId);

typedef ClientSendText = int Function(int goClientId, Pointer<Utf8> msg,
    Pointer<Pointer<Utf8>> codeOut, int callbackPortId);

typedef ClientSendFileNative = Int32 Function(
    Uint32 goClientId,
    Pointer<Utf8> fileName,
    Uint32 length,
    Pointer<Uint8> fileBytes,
    Pointer<Pointer<Utf8>> codeOut,
    Int32 callbackPortId);

typedef ClientSendFile = int Function(
    int goClientId,
    Pointer<Utf8> fileName,
    int length,
    Pointer<Uint8> fileBytes,
    Pointer<Pointer<Utf8>> codePtr,
    int callbackPortId);

typedef ClientRecvTextNative = Int32 Function(
    Uint32 goClientId, Pointer<Utf8> code, Int32 callbackPortId);

typedef ClientRecvText = int Function(
    int goClientId, Pointer<Utf8> code, int callbackPortId);

typedef ClientRecvFileNative = Int32 Function(
    Uint32 goClientId, Pointer<Utf8> code, Int32 callbackPortId);

typedef ClientRecvFile = int Function(
    int goClientId, Pointer<Utf8> code, int callbackPortId);

const DEFAULT_APP_ID = "lothar.com/wormhole/text-or-file-xfer";
const DEFAULT_RENDEZVOUS_URL = "ws://localhost:4000/v1";
const DEFAULT_TRANSIT_RELAY_URL = "tcp:localhost:4001";
const DEFAULT_PASSPHRASE_COMPONENT_LENGTH = 2;

class Config {
  final String appId;
  final String rendezvousUrl;
  final String transitRelayUrl;
  final int passPhraseComponentLength;

  Config(
      {this.appId = DEFAULT_APP_ID,
      this.rendezvousUrl = DEFAULT_RENDEZVOUS_URL,
      this.transitRelayUrl = DEFAULT_TRANSIT_RELAY_URL,
      this.passPhraseComponentLength = DEFAULT_PASSPHRASE_COMPONENT_LENGTH});
}

class NativeClient {
  late final DynamicLibrary _wormholeWilliamLib;
  late final DynamicLibrary _asyncCallbackLib;
  late final _goClientId;

  String _appId = DEFAULT_APP_ID;
  String _rendezvousUrl = DEFAULT_RENDEZVOUS_URL;
  String _transitRelayUrl = DEFAULT_TRANSIT_RELAY_URL;
  int _passPhraseComponentLength = DEFAULT_PASSPHRASE_COMPONENT_LENGTH;

  NativeClient({Config? config}) {
    _wormholeWilliamLib =
        DynamicLibrary.open(libName("dart_wormhole_william_plugin"));
    _asyncCallbackLib = DynamicLibrary.open(libName("bindings"));
    _initDartApi(NativeApi.initializeApiDLData);

    _appId = config?.appId ?? _appId;
    _rendezvousUrl = config?.rendezvousUrl ?? _rendezvousUrl;
    _transitRelayUrl = config?.transitRelayUrl ?? _transitRelayUrl;
    _passPhraseComponentLength =
        config?.passPhraseComponentLength ?? _passPhraseComponentLength;

    _goClientId = _newClient(
        _appId.toNativeUtf8(),
        _rendezvousUrl.toNativeUtf8(),
        _transitRelayUrl.toNativeUtf8(),
        _passPhraseComponentLength);
  }

  NewClient get _newClient {
    return _wormholeWilliamLib
        .lookup<NativeFunction<NewClientNative>>('NewClient')
        .asFunction();
  }

  int clientSendText(
      Pointer<Utf8> msg, Pointer<Pointer<Utf8>> codeOut, int callbackPortId) {
    return _clientSendText(_goClientId, msg, codeOut, callbackPortId);
  }

  int clientSendFile(
      Pointer<Utf8> fileName,
      int length,
      Pointer<Uint8> fileBytes,
      Pointer<Pointer<Utf8>> codeOut,
      int callbackPortId) {
    return _clientSendFile(
        _goClientId, fileName, length, fileBytes, codeOut, callbackPortId);
  }

  int clientRecvText(Pointer<Utf8> code, int callbackPortId) {
    return _clientRecvText(_goClientId, code, callbackPortId);
  }

  int clientRecvFile(Pointer<Utf8> code, int callbackPortId) {
    return _clientRecvFile(_goClientId, code, callbackPortId);
  }

  // -- getters for wrapping native functions in dart --//
  ClientSendText get _clientSendText {
    return _asyncCallbackLib
        .lookup<NativeFunction<ClientSendTextNative>>('async_ClientSendText')
        .asFunction();
  }

  ClientSendFile get _clientSendFile {
    return _asyncCallbackLib
        .lookup<NativeFunction<ClientSendFileNative>>('async_ClientSendFile')
        .asFunction();
  }

  ClientRecvText get _clientRecvText {
    return _asyncCallbackLib
        .lookup<NativeFunction<ClientRecvTextNative>>('async_ClientRecvText')
        .asFunction();
  }

  ClientRecvFile get _clientRecvFile {
    return _asyncCallbackLib
        .lookup<NativeFunction<ClientRecvFileNative>>('async_ClientRecvFile')
        .asFunction();
  }

  InitDartApi get _initDartApi {
    final nativeFnPointer = _asyncCallbackLib
        .lookup<NativeFunction<InitDartApiNative>>('init_dart_api_dl');
    return nativeFnPointer.asFunction<InitDartApi>();
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
}
