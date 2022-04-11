import 'dart:ffi';

import 'package:ffi/ffi.dart';

class CallbackResult extends Struct {
  @Int32()
  external int errorCode;

  external Pointer<Utf8> errorString;
  external Pointer<Utf8> receivedText;
}

class Error extends Struct {
  external Pointer<Utf8> errorString;
}

class CodeGenerated extends Struct {
  external Pointer<Utf8> code;
  @Int32()
  external int transferId;
}

class CodeGenerationResult extends Struct {
  @Int32()
  external int resultType;
  external Pointer<Void> context;
  external Error error;
  external CodeGenerated generated;
}

class Progress extends Struct {
  @Int64()
  external int transferredBytes;

  @Int64()
  external int totalBytes;
}

class SeekArgs extends Struct {
  external Pointer<Void> context;
  @Int64()
  external int newOffset;
  @Int32()
  external int whence;
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
