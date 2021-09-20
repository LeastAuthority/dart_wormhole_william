import 'dart:ffi';

class NativeContext extends Struct {
  @IntPtr()
  external int callbackPortId;
}