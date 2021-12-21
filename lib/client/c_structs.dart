import 'dart:ffi';

import 'package:ffi/ffi.dart';

class FileStruct extends Struct {
  @Int32()
  external int length;

  external Pointer<Uint8> data;

  external Pointer<Utf8> fileName;
}

class CallbackResult extends Struct {
  external Pointer<FileStruct> file;

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
