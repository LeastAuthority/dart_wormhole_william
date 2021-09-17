#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

#include <dart_api.h>
#include <dart_api_dl.h>

// extern GoInt ClientSendText(void* ctxC, GoUintptr clientPtr, char* msgC,
// char** codeOutC, callback cb);

// int main() {}
//
intptr_t init_dart_api_dl(void* data) {
  return Dart_InitializeApiDL(data);
}

typedef struct {
  intptr_t callback_port;
} context;

void async(void *ctx, void *value, int32_t err_code) {
  // Construct Dart object from C API.
  //  (see:
  //  https://github.com/dart-lang/sdk/blob/master/runtime/include/dart_native_api.h#L19)
  // dart_object.type = Dart_CObject_kInt32;
  // dart_object.value.as_int32 = value;

  if (err_code != 0) {
    // TODO: throw error / exception whatever using Dart native api ...
    // TODO: maybe construct dart error object
  }

  intptr_t callback_port = ((context *)(ctx))->callback_port;

  Dart_CObject* obj = malloc(sizeof(Dart_CObject));
  obj->type = Dart_CObject_kString;
  obj->value.as_string = "done from C";
  // *obj = {.type = Dart_CObject_kString, .value.as_string = "I'm done yo"};

  // Send dart object response.
  bool result = Dart_PostCObject_DL(callback_port, obj);
}

int client_send_text(uintptr_t clientPtr, char *msg, char **_codeOut,
                     intptr_t callback_port) {
  context ctx = {.callback_port = callback_port};

  *_codeOut = "hello";

  // async(&ctx, NULL, 0);

  return 0;

  // ClientSendText(ctx, clientPtr, msg, _codeOut, &async);
}
