import 'dart:ffi';

import 'dart:typed_data';

typedef Read<Buffer> = Future<int> Function(Buffer);
typedef Write<Buffer> = Future<void> Function(Buffer);
typedef GetPosition = Future<int> Function();
typedef SetPosition = Future<void> Function(int);
typedef Close = Future<void> Function();

class Unsupported {
  String operation;
  Unsupported(this.operation);
}

Future<int> noRead(Uint8List buffer) async {
  throw Unsupported("Read");
}

Future<Void> noWrite(Uint8List buffer) async {
  throw Unsupported("Write");
}

Future<int> noPositionGetter() async {
  throw Unsupported("GetPosition");
}

Future<void> noPositionSetter(int position) async {
  throw Unsupported("SetPosition");
}

Future<Void> noClose() async {
  throw Unsupported("Close");
}

class Metadata {
  String? fileName;
  int? fileSize;
  String? type;
  Metadata({this.fileName, this.fileSize, this.type});
}

typedef GetMetadata = Future<Metadata> Function();

Future<Metadata> noMetadata() async {
  throw Unsupported("GetMetadata");
}

class File {
  final Read<Uint8List> read;
  final Write<Uint8List> write;
  final Close close;
  final GetPosition getPosition;
  final SetPosition setPosition;
  final GetMetadata metadata;

  File(
      {this.read: noRead,
      this.write: noWrite,
      this.close: noClose,
      this.getPosition: noPositionGetter,
      this.setPosition: noPositionSetter,
      this.metadata: noMetadata});
}
