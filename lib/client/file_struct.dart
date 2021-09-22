import 'dart:ffi';

class FileStruct extends Struct {
  @Int32()
  external int size;

  external Pointer<Uint8> data;
}