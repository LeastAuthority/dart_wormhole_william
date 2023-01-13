import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

const ErrCodeSuccess = 0;
const ErrCodeSendFileError = 1;
const ErrCodeReceiveFileError = 2;
const ErrCodeSendTextError = 3;
const ErrCodeReceiveTextError = 4;
const ErrCodeTransferRejected = 5;
const ErrCodeTransferCancelled = 6;
const ErrCodeWrongCode = 7;
const ErrCodeTransferCancelledByReceiver = 8;
const ErrCodeTransferCancelledBySender = 9;
const ErrCodeConnectionRefused = 10;
const ErrCodeFailedToGetClient = 11;
const ErrCodeGenerationFailed = 12;

typedef InitDartApiNative = IntPtr Function(Pointer<Void>);
typedef InitDartApi = int Function(Pointer<Void>);

typedef ClientSendTextNative = Pointer<Void> Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> transitRelayUrl,
    Pointer<Utf8> rendezvousUrl,
    Int32 passPhraseComponentLength,
    Pointer<Utf8> msg,
    Int64 resultPortId,
    Int64 codegenPortId);

typedef ClientSendText = Pointer<Void> Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> transitRelayUrl,
    Pointer<Utf8> rendezvousUrl,
    int passPhraseComponentLength,
    Pointer<Utf8> msg,
    int resultPortId,
    int codegenResultPortId);

typedef ClientSendFileNative = Pointer<Void> Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> transitRelayUrl,
    Pointer<Utf8> rendezvousUrl,
    Int32 passPhraseComponentLength,
    Pointer<Utf8> fileName,
    Int64 codegenResultPortId,
    Int64 callbackPortId,
    Int64 progressPortId,
    Int64 readArgsPort,
    Int64 seekArgsPort);

typedef ClientSendFile = Pointer<Void> Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> transitRelayUrl,
    Pointer<Utf8> rendezvousUrl,
    int passPhraseComponentLength,
    Pointer<Utf8> fileName,
    int codegenResultPortId,
    int callbackPortId,
    int progressPortId,
    int readArgsPort,
    int seekArgsPort);

typedef ClientRecvTextNative = Pointer<Void> Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> transitRelayUrl,
    Pointer<Utf8> rendezvousUrl,
    Int32 passPhraseComponentLength,
    Pointer<Utf8> code,
    Int64 callbackPortId);

typedef ClientRecvText = Pointer<Void> Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> transitRelayUrl,
    Pointer<Utf8> rendezvousUrl,
    int passPhraseComponentLength,
    Pointer<Utf8> code,
    int callbackPortId);

typedef ClientRecvFileNative = Pointer<Void> Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> transitRelayUrl,
    Pointer<Utf8> rendezvousUrl,
    Int32 passPhraseComponentLength,
    Pointer<Utf8> code,
    Int64 callbackPortId,
    Int64 progressPortId,
    Int64 fmdPortId,
    Int64 writeBytesPortId);

typedef ClientRecvFile = Pointer<Void> Function(
    Pointer<Utf8> appId,
    Pointer<Utf8> transitRelayUrl,
    Pointer<Utf8> rendezvousUrl,
    int passPhraseComponentLength,
    Pointer<Utf8> code,
    int callbackPortId,
    int progressPortId,
    int fmdPortId,
    int writeBytesPortId);

typedef ReadDoneNative = Void Function(Pointer<Void>, Int64, Pointer<Utf8>);
typedef ReadDone = void Function(Pointer<Void>, int, Pointer<Utf8>);

typedef WriteDoneNative = Void Function(Pointer<Void>, Pointer<Utf8>);
typedef WriteDone = void Function(Pointer<Void>, Pointer<Utf8>);

typedef SeekDoneNative = Void Function(Pointer<Void>, Int64, Pointer<Utf8>);
typedef SeekDone = void Function(Pointer<Void>, int, Pointer<Utf8>);

typedef AcceptDownloadNative = Void Function(Pointer<Void>);
typedef AcceptDownload = void Function(Pointer<Void>);

typedef RejectDownloadNative = Void Function(Pointer<Void>);
typedef RejectDownload = void Function(Pointer<Void>);

typedef CancelTransferNative = Void Function(Pointer<Void>);
typedef CancelTransfer = void Function(Pointer<Void>);

typedef FinalizeNative = Void Function(Pointer<Void>);
typedef Finalize = void Function(Pointer<Void>);

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

  late final Config config;

  NativeClient({Config? config}) {
    // iOS requires static libraries to load
    if (Platform.isIOS) {
      _wormholeWilliamLib = DynamicLibrary.executable();
      _asyncCallbackLib = DynamicLibrary.process();
    } else {
      _wormholeWilliamLib = DynamicLibrary.open(libName("wormhole_william"));
      _asyncCallbackLib = DynamicLibrary.open(libName("bindings"));
    }

    _initDartApi(NativeApi.initializeApiDLData);

    this.config = config ?? Config();
  }

  Pointer<Void> clientSendText(
      String msg, int resultPortId, int codegenResultPortId) {
    final appIdC = config.appId.toNativeUtf8();
    final transitRelayUrlC = config.transitRelayUrl.toNativeUtf8();
    final rendezvousUrlC = config.rendezvousUrl.toNativeUtf8();
    try {
      return _clientSendText(
          appIdC,
          transitRelayUrlC,
          rendezvousUrlC,
          config.passPhraseComponentLength,
          msg.toNativeUtf8(),
          resultPortId,
          codegenResultPortId);
    } finally {
      calloc.free(appIdC);
      calloc.free(transitRelayUrlC);
      calloc.free(rendezvousUrlC);
    }
  }

  Pointer<Void> clientSendFile(
      String fileName,
      int codegenResultPortId,
      int callbackPortId,
      int progressPortId,
      int readArgsPort,
      int seekArgsPort) {
    final appIdC = config.appId.toNativeUtf8();
    final transitRelayUrlC = config.transitRelayUrl.toNativeUtf8();
    final rendezvousUrlC = config.rendezvousUrl.toNativeUtf8();
    final fileNameC = fileName.toNativeUtf8();
    try {
      return _clientSendFile(
          appIdC,
          transitRelayUrlC,
          rendezvousUrlC,
          config.passPhraseComponentLength,
          fileNameC,
          codegenResultPortId,
          callbackPortId,
          progressPortId,
          readArgsPort,
          seekArgsPort);
    } finally {
      calloc.free(appIdC);
      calloc.free(transitRelayUrlC);
      calloc.free(rendezvousUrlC);
      calloc.free(fileNameC);
    }
  }

  Pointer<Void> clientRecvText(String code, int callbackPortId) {
    final appIdC = config.appId.toNativeUtf8();
    final transitRelayUrlC = config.transitRelayUrl.toNativeUtf8();
    final rendezvousUrlC = config.rendezvousUrl.toNativeUtf8();
    final codeC = code.toNativeUtf8();
    try {
      return _clientRecvText(appIdC, transitRelayUrlC, rendezvousUrlC,
          config.passPhraseComponentLength, codeC, callbackPortId);
    } finally {
      calloc.free(appIdC);
      calloc.free(transitRelayUrlC);
      calloc.free(rendezvousUrlC);
      calloc.free(codeC);
    }
  }

  Pointer<Void> clientRecvFile(String code, int callbackPortId,
      int progressPortId, int fmdPortId, int writeBytesPortId) {
    final appIdC = config.appId.toNativeUtf8();
    final transitRelayUrlC = config.transitRelayUrl.toNativeUtf8();
    final rendezvousUrlC = config.rendezvousUrl.toNativeUtf8();
    final codeC = code.toNativeUtf8();
    try {
      return _clientRecvFile(
          appIdC,
          transitRelayUrlC,
          rendezvousUrlC,
          config.passPhraseComponentLength,
          codeC,
          callbackPortId,
          progressPortId,
          fmdPortId,
          writeBytesPortId);
    } finally {
      calloc.free(appIdC);
      calloc.free(transitRelayUrlC);
      calloc.free(rendezvousUrlC);
      calloc.free(codeC);
    }
  }

  Finalize get _finalize {
    return _asyncCallbackLib
        .lookup<NativeFunction<FinalizeNative>>('finalize')
        .asFunction();
  }

  void finalize(Pointer<Void> transferContext) {
    _finalize(transferContext);
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

  SeekDone get _seekDone {
    return _asyncCallbackLib
        .lookup<NativeFunction<SeekDoneNative>>('seek_done')
        .asFunction();
  }

  void seekDone(Pointer<Void> ctxPtr, int currentOffset, String? errorMessage) {
    final errorC = errorMessage == null ? nullptr : errorMessage.toNativeUtf8();
    try {
      _seekDone(ctxPtr, currentOffset, errorC);
    } finally {
      if (errorC != nullptr) {
        calloc.free(errorC);
      }
    }
  }

  ReadDone get _readDone {
    return _asyncCallbackLib
        .lookup<NativeFunction<ReadDoneNative>>('read_done')
        .asFunction();
  }

  void readDone(Pointer<Void> ctxPtr, int bytesRead, String? errorMessage) {
    final errorC = errorMessage == null ? nullptr : errorMessage.toNativeUtf8();
    try {
      _readDone(ctxPtr, bytesRead, errorC);
    } finally {
      if (errorC != nullptr) {
        calloc.free(errorC);
      }
    }
  }

  WriteDone get _writeDone {
    return _asyncCallbackLib
        .lookup<NativeFunction<WriteDoneNative>>('write_done')
        .asFunction();
  }

  void writeDone(Pointer<Void> ctx, String? errorMessage) {
    final errorC = errorMessage == null ? nullptr : errorMessage.toNativeUtf8();
    try {
      _writeDone(ctx, errorC);
    } finally {
      if (errorC != nullptr) {
        calloc.free(errorC);
      }
    }
  }

  AcceptDownload get _acceptDownload {
    return _asyncCallbackLib
        .lookup<NativeFunction<AcceptDownloadNative>>('accept_download')
        .asFunction();
  }

  RejectDownload get _rejectDownload {
    return _asyncCallbackLib
        .lookup<NativeFunction<RejectDownloadNative>>('reject_download')
        .asFunction();
  }

  CancelTransfer get _cancelTransfer {
    return _asyncCallbackLib
        .lookup<NativeFunction<CancelTransferNative>>('cancel_transfer')
        .asFunction();
  }

  void acceptDownload(Pointer<Void> context) {
    _acceptDownload(context);
  }

  void rejectDownload(Pointer<Void> context) {
    _rejectDownload(context);
  }

  void cancelTransfer(Pointer<Void> context) {
    _cancelTransfer(context);
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
      baseName = "$libraryName.dll";
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
