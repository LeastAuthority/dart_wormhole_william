import 'dart:ffi';

import 'package:dart_wormhole_william/client.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientNative', () {
    test('#newClient', () {
      int goClient = ClientNative().newClient();
      print("goClient: $goClient");

      expect(goClient, isNonNegative);
      expect(goClient, isNonZero);
    });

    int goClient = -1;
    Pointer<Utf8> codeC = ''.toNativeUtf8();

    String testMsg = "testing 123";
    Pointer<Utf8> testMsgC = testMsg.toNativeUtf8();
    Pointer<Pointer<Utf8>> codeOutC = calloc();

    test('#clientSendText', () {
      // TODO: figure out.
      //  "Unsupported operation: Operation 'toDartString' not allowed on a 'nullptr'" unless initially set.
      codeOutC.value = ''.toNativeUtf8();

      goClient = ClientNative().newClient();
      expect(goClient, isNonNegative);
      expect(goClient, isNonZero);

      int statusCode = ClientNative().clientSendText(goClient, testMsgC, codeOutC);
      expect(statusCode, isZero);
      expect(codeOutC.value, isNotNull);
      expect(codeOutC.value.toDartString(), isNotEmpty);
      codeC = codeOutC.value;
    });

    test('#clientRecvText', () {
      Pointer<Pointer<Utf8>> msgOutC = calloc();

      int statusCode = ClientNative().clientRecvText(goClient, codeC, msgOutC);
      expect(statusCode, isZero);
      expect(msgOutC.value, isNotNull);
      expect(msgOutC.value.toDartString(), testMsg);
    });
  });

//  group('Client' () {
//
//  });
}
