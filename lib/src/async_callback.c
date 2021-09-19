#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "libwormhole_william.h"
#include <dart_api.h>
#include <dart_api_dl.h>

intptr_t init_dart_api_dl(void *data) { return Dart_InitializeApiDL(data); }

typedef struct {
  intptr_t callback_port;
} context;

void async(void *ctx, void *value, int32_t err_code) {
  bool dart_message_sent = false;
  intptr_t callback_port = ((context *)(ctx))->callback_port;

  printf("I'm in async\n");
  printf("Error code is: %d\n", err_code);

  Dart_CObject response;

  if (err_code != 0) {
    // TODO currently we return NULL for value always, this should probably be
    // changed in case of error Also we need to check if we'll return an
    // error-containing message or throw a dart error Construct Dart object from
    // C API.
    //  (see:
    //  https://github.com/dart-lang/sdk/blob/master/runtime/include/dart_native_api.h#L19)
    // dart_object.type = Dart_CObject_kInt32;
    // dart_object.value.as_int32 = value;
    response =
        (Dart_CObject){.type = Dart_CObject_kString, .value.as_string = value};

    dart_message_sent = Dart_PostCObject_DL(callback_port, &response);
  } else {
    response =
        (Dart_CObject){.type = Dart_CObject_kInt32, .value.as_int32 = err_code};
    dart_message_sent = Dart_PostCObject_DL(callback_port, &response);
  }

  if (!dart_message_sent) {
    printf("Sending callback result to dart isolate failed");
  }
}

int client_send_text(uintptr_t clientPtr, char *msg, char **_codeOut,
                     intptr_t callback_port) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){.callback_port = callback_port};
  ClientSendText(ctx, clientPtr, msg, _codeOut, async);
  return 0;
}
