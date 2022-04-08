import 'dart:ffi';
import 'dart:io' show Platform, RandomAccessFile;

import 'package:ffi/ffi.dart';

import 'c_structs.dart';

const ErrCodeSuccess = 0;
const ErrCodeSendFileError = 1;
const ErrCodeReceiveFileError = 2;
const ErrCodeSendTextError = 3;
const ErrCodeReceiveTextError = 4;
const ErrCodeTransferRejected = 5;
const ErrCodeTransferCancelled = 6;

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
    IntPtr goClientId, Pointer<Utf8> msg, Int64 callbackPortId);

typedef ClientSendText = Pointer<CodeGenerationResult> Function(
    int goClientId, Pointer<Utf8> msg, int callbackPortId);

typedef ClientSendFileNative = Pointer<CodeGenerationResult> Function(
    IntPtr goClientId,
    Pointer<Utf8> fileName,
    Int64 callbackPortId,
    Int64 progressPortId,
    Handle file,
    Int64 readArgsPort,
    Pointer<NativeFunction<SeekNative>> seekHandle);

typedef ClientSendFile = Pointer<CodeGenerationResult> Function(
    int goClientId,
    Pointer<Utf8> fileName,
    int callbackPortId,
    int progressPortId,
    RandomAccessFile file,
    int readArgsPort,
    Pointer<NativeFunction<SeekNative>> seek);

typedef ClientRecvTextNative = Int32 Function(
    IntPtr goClientId, Pointer<Utf8> code, Int64 callbackPortId);

typedef ClientRecvText = int Function(
    int goClientId, Pointer<Utf8> code, int callbackPortId);

typedef ClientRecvFileNative = Int32 Function(
    Int32 goClientId,
    Pointer<Utf8> code,
    Int64 callbackPortId,
    Int64 progressPortId,
    Int64 fmdPortId,
    Int64 writeBytesPortId);

typedef ClientRecvFile = int Function(
    int goClientId,
    Pointer<Utf8> code,
    int callbackPortId,
    int progressPortId,
    int fmdPortId,
    int writeBytesPortId);

typedef FreeResultNative = Void Function(Pointer<CallbackResult> result);
typedef FreeResult = void Function(Pointer<CallbackResult> result);

typedef FreeCodegenResultNative = Void Function(
    Pointer<CodeGenerationResult> result);
typedef FreeCodegenResult = void Function(Pointer<CodeGenerationResult> result);

typedef ReadDoneNative = Void Function(Pointer<Void>, Int64);
typedef ReadDone = void Function(Pointer<Void>, int);

typedef WriteDoneNative = Void Function(Pointer<Void>, Bool);
typedef WriteDone = void Function(Pointer<Void>, bool);

typedef SeekNative = Int64 Function(Handle, Int64 offset, Int64 whence);
typedef Seek = int Function(RandomAccessFile, int offset, int whence);

typedef AcceptDownloadNative = Void Function(Pointer<Void>);
typedef AcceptDownload = void Function(Pointer<Void>);

typedef RejectDownloadNative = Void Function(Pointer<Void>);
typedef RejectDownload = void Function(Pointer<Void>);

typedef CancelTransferNative = Void Function(Pointer<Void>);
typedef CancelTransfer = void Function(Pointer<Void>);

typedef FinalizeNative = Int32 Function(Int32);
typedef Finalize = int Function(int);

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
    _wormholeWilliamLib = DynamicLibrary.open(libName("wormhole_william"));
    _asyncCallbackLib = DynamicLibrary.open(libName("bindings"));
    _initDartApi(NativeApi.initializeApiDLData);

    Config effectiveConfig = config ?? Config();

    _goClientId = _newClient(
        effectiveConfig.appId.toNativeUtf8(),
        effectiveConfig.rendezvousUrl.toNativeUtf8(),
        effectiveConfig.transitRelayUrl.toNativeUtf8(),
        effectiveConfig.passPhraseComponentLength);
  }

  int get clientId => _goClientId;

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
      int callbackPortId,
      int progressPortId,
      RandomAccessFile file,
      int readArgsPort,
      Pointer<NativeFunction<SeekNative>> seek) {
    return _clientSendFile(_goClientId, fileName, callbackPortId,
        progressPortId, file, readArgsPort, seek);
  }

  int clientRecvText(Pointer<Utf8> code, int callbackPortId) {
    return _clientRecvText(_goClientId, code, callbackPortId);
  }

  int clientRecvFile(Pointer<Utf8> code, int callbackPortId, int progressPortId,
      int fmdPortId, int writeBytesPortId) {
    return _clientRecvFile(_goClientId, code, callbackPortId, progressPortId,
        fmdPortId, writeBytesPortId);
  }

  void freeResult(int result) {
    _freeResult(Pointer.fromAddress(result));
  }

  void freeCodegenResult(int codegenResult) {
    _freeCodegenResult(Pointer.fromAddress(codegenResult));
  }

  Finalize get _finalize {
    return _asyncCallbackLib
        .lookup<NativeFunction<FinalizeNative>>('finalize')
        .asFunction();
  }

  void finalize(int clientId) {
    _finalize(clientId);
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

  ReadDone get _readDone {
    return _asyncCallbackLib
        .lookup<NativeFunction<ReadDoneNative>>('read_done')
        .asFunction();
  }

  void readDone(Pointer<Void> ctxPtr, int bytesRead) {
    _readDone(ctxPtr, bytesRead);
  }

  WriteDone get _writeDone {
    return _asyncCallbackLib
        .lookup<NativeFunction<WriteDoneNative>>('write_done')
        .asFunction();
  }

  // TODO send error details as well so they can be shown in
  // the Future's result when the Go client has gracefully
  // terminated the session
  void writeDone(Pointer<Void> ctx, bool successful) {
    _writeDone(ctx, successful);
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

  FreeResult get _freeResult {
    return _wormholeWilliamLib
        .lookup<NativeFunction<FreeResultNative>>('free_result')
        .asFunction();
  }

  FreeCodegenResult get _freeCodegenResult {
    return _wormholeWilliamLib
        .lookup<NativeFunction<FreeCodegenResultNative>>('free_codegen_result')
        .asFunction();
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
