import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'c_structs.dart';

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

typedef ClientSendTextNative = Pointer<CodeGenerationResult> Function(
    Uint32 goClientId, Pointer<Utf8> msg, Int32 callbackPortId);

typedef ClientSendText = Pointer<CodeGenerationResult> Function(
    int goClientId, Pointer<Utf8> msg, int callbackPortId);

typedef ClientSendFileNative = Pointer<CodeGenerationResult> Function(
    Uint32 goClientId,
    Pointer<Utf8> fileName,
    Uint32 length,
    Pointer<Uint8> fileBytes,
    Int32 callbackPortId);

typedef ClientSendFile = Pointer<CodeGenerationResult> Function(
    int goClientId,
    Pointer<Utf8> fileName,
    int length,
    Pointer<Uint8> fileBytes,
    int callbackPortId);

typedef ClientRecvTextNative = Int32 Function(
    Uint32 goClientId, Pointer<Utf8> code, Int32 callbackPortId);

typedef ClientRecvText = int Function(
    int goClientId, Pointer<Utf8> code, int callbackPortId);

typedef ClientRecvFileNative = Int32 Function(
    Uint32 goClientId, Pointer<Utf8> code, Int32 callbackPortId);

typedef ClientRecvFile = int Function(
    int goClientId, Pointer<Utf8> code, int callbackPortId);

typedef FreeResultNative = Void Function(Pointer<CallbackResult> result);
typedef FreeResult = void Function(Pointer<CallbackResult> result);

typedef FreeCodegenResultNative = Void Function(
    Pointer<CodeGenerationResult> result);
typedef FreeCodegenResult = void Function(Pointer<CodeGenerationResult> result);

class Config {
  final String appId;
  final String rendezvousUrl;
  final String transitRelayUrl;
  final int passPhraseComponentLength;

  static const DEFAULT_APP_ID = "lothar.com/wormhole/text-or-file-xfer";
  static const DEFAULT_RENDEZVOUS_URL = "ws://relay.magic-wormhole.io:4000/v1";
  static const DEFAULT_TRANSIT_RELAY_URL = "tcp:transit.magic-wormhole.io:4001";
  static const DEFAULT_PASSPHRASE_COMPONENT_LENGTH = 2;

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

  NativeClient({Config? config}) {
    _wormholeWilliamLib =
        DynamicLibrary.open(libName("dart_wormhole_william_plugin"));
    _asyncCallbackLib = DynamicLibrary.open(libName("bindings"));
    _initDartApi(NativeApi.initializeApiDLData);

    Config effectiveConfig = config ?? Config();

    _goClientId = _newClient(
        effectiveConfig.appId.toNativeUtf8(),
        effectiveConfig.rendezvousUrl.toNativeUtf8(),
        effectiveConfig.transitRelayUrl.toNativeUtf8(),
        effectiveConfig.passPhraseComponentLength);
  }

  NewClient get _newClient {
    return _wormholeWilliamLib
        .lookup<NativeFunction<NewClientNative>>('NewClient')
        .asFunction();
  }

  Pointer<CodeGenerationResult> clientSendText(
      Pointer<Utf8> msg, int callbackPortId) {
    return _clientSendText(_goClientId, msg, callbackPortId);
  }

  Pointer<CodeGenerationResult> clientSendFile(
      Pointer<Utf8> fileName,
      int length,
      Pointer<Uint8> fileBytes,
      Pointer<Pointer<Utf8>> codeOut,
      int callbackPortId) {
    return _clientSendFile(
        _goClientId, fileName, length, fileBytes, callbackPortId);
  }

  int clientRecvText(Pointer<Utf8> code, int callbackPortId) {
    return _clientRecvText(_goClientId, code, callbackPortId);
  }

  int clientRecvFile(Pointer<Utf8> code, int callbackPortId) {
    return _clientRecvFile(_goClientId, code, callbackPortId);
  }

  void freeResult(int result) {
    _freeResult(Pointer.fromAddress(result));
  }

  void freeCodegenResult(int codegenResult) {
    _freeCodegenResult(Pointer.fromAddress(codegenResult));
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

  FreeResult get _freeResult {
    return _asyncCallbackLib
        .lookup<NativeFunction<FreeResultNative>>('free_result')
        .asFunction();
  }

  FreeCodegenResult get _freeCodegenResult {
    return _asyncCallbackLib
        .lookup<NativeFunction<FreeCodegenResultNative>>('free_codegen_result')
        .asFunction();
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
