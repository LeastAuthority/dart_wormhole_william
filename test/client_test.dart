import 'dart:io' show Directory;
import 'dart:ffi';

import 'package:dart_wormhole_william/client.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart' show Frame;

void main() {
  group('ClientNative', () {
//    String _dylibDir = path.join(
//        Directory.current.path, '..', 'wormhole-william', 'build');
    // TODO: figure this out!

    test('#newClient', () {
      ClientNative _native = ClientNative();
      int goClient = _native.newClient();
      print("goClient: $goClient");

      expect(goClient, isNonNegative);
      expect(goClient, isNonZero);
    });

    late ClientNative _native;
    int goClient = -1;
    Pointer<Utf8> codeC = ''.toNativeUtf8();

    String testMsg = "testing 123";
    Pointer<Utf8> testMsgC = testMsg.toNativeUtf8();
    Pointer<Pointer<Utf8>> codeOutC = calloc();

    test('#clientSendText', () {
      // TODO: figure out.
      //  "Unsupported operation: Operation 'toDartString' not allowed on a 'nullptr'" unless initially set.
      codeOutC.value = ''.toNativeUtf8();

      _native = ClientNative();
      goClient = _native.newClient();

      expect(goClient, isNonNegative);
      expect(goClient, isNonZero);

      // TODO FIXME
      // int statusCode = _native.clientSendText(goClient, testMsgC, codeOutC);
      // expect(statusCode, isZero);
      expect(codeOutC.value, isNotNull);
      expect(codeOutC.value.toDartString(), isNotEmpty);
      codeC = codeOutC.value;
    });

    test('#clientRecvText', () {
      Pointer<Pointer<Utf8>> msgOutC = calloc();

      int statusCode = _native.clientRecvText(goClient, codeC, msgOutC);
      expect(statusCode, isZero);
      expect(msgOutC.value, isNotNull);
      expect(msgOutC.value.toDartString(), testMsg);
    });
  });

  group('Client', () {
    Client client = Client();
    String testMsg = 'testing 456';
    late String code;

    test('#sendText', () {
      // TODO confirm this
      client
          .sendText(testMsg)
          .then((code) => expect(code, isNotEmpty))
          .onError((error, stackTrace) => fail(error.toString()));
      // expect(code, isNotEmpty);
    });

    test('#recvText', () {
      // TODO fix this
      //String msg = client.recvText(code);
      //expect(code, isNotEmpty);
      //expect(msg, testMsg);
    });
  });
}
