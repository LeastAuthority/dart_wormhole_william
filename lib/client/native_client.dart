import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';

import 'native_context.dart';

typedef InitDartApiNative = IntPtr Function(Pointer<Void>);
typedef InitDartApi = int Function(Pointer<Void>);

typedef NewClientNative = IntPtr Function();
typedef NewClient = int Function();

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

typedef ClientRecvTextNative = Int32 Function(Uint32 goClientId,
    Pointer<Utf8> code, Pointer<Pointer<Utf8>> msgOut, Int32 callbackPortId);

typedef ClientRecvText = int Function(int goClientId, Pointer<Utf8> code,
    Pointer<Pointer<Utf8>> msgOut, int callbackPortId);

class NativeClient {
  late final DynamicLibrary _wormholeWilliamLib;
  late final DynamicLibrary _asyncCallbackLib;
  late final goClientId;

  NativeClient() {
    _wormholeWilliamLib =
        DynamicLibrary.open(libName("dart_wormhole_william_plugin"));
    _asyncCallbackLib =
        DynamicLibrary.open(libName("bindings", version: "1.0.0"));
    _initDartApi(NativeApi.initializeApiDLData);
    goClientId = _newClient();
  }

  NewClient get _newClient {
    return _wormholeWilliamLib
        .lookup<NativeFunction<NewClientNative>>('NewClient')
        .asFunction();
  }

  int clientSendText(
      Pointer<Utf8> msg, Pointer<Pointer<Utf8>> codeOut, int callbackPortId) {
    return _clientSendText(goClientId, msg, codeOut, callbackPortId);
  }

  int clientSendFile(
      Pointer<Utf8> fileName,
      int length,
      Pointer<Uint8> fileBytes,
      Pointer<Pointer<Utf8>> codeOut,
      int callbackPortId) {
    return _clientSendFile(
        goClientId, fileName, length, fileBytes, codeOut, callbackPortId);
  }

  int clientRecvText(
      Pointer<Utf8> code, Pointer<Pointer<Utf8>> msgOut, int callbackPortId) {
    return _clientRecvText(goClientId, code, msgOut, callbackPortId);
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