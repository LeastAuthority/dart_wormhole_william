import 'dart:ffi';

import 'package:ffi/ffi.dart';

class CallbackResult extends Struct {
  @Int32()
  external int errorCode;

  external Pointer<Utf8> errorString;
  external Pointer<Utf8> receivedText;
}

class CodeGenerationResult extends Struct {
  @Int32()
  external int errorCode;
  external Pointer<Utf8> errorString;
  external Pointer<Utf8> code;
}

class Progress extends Struct {
  @Int64()
  external int transferredBytes;

  @Int64()
  external int totalBytes;
}

class ReadArgs extends Struct {
  external Pointer<Void> context;
  external Pointer<Uint8> buffer;
  @Int32()
  external int length;
}

class WriteArgs extends Struct {
  external Pointer<Void> context;
  external Pointer<Uint8> buffer;
  @Int32()
  external int length;
}

class FileMetadataStruct extends Struct {
  @Int64()
  external int size;
  external Pointer<Utf8> fileName;
  @Int32()
  external int downloadId;
  external Pointer<Void> context;
}
