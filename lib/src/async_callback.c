#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dart_api.h>
#include <dart_api_dl.h>

#include "libwormhole_william.h"

typedef struct {
    int32_t callback_port_id;
    const char* entrypoint;
} context;

const char* SEND_TEXT = "context/send_text";
const char* RECV_TEXT = "context/recv_text";
const char* SEND_FILE = "context/send_file";
const char* RECV_FILE = "context/recv_file";

intptr_t init_dart_api_dl(void *data) { return Dart_InitializeApiDL(data); }

void async_callback(void *ctx, void *value, int32_t err_code) {
  bool dart_message_sent = false;
  intptr_t callback_port_id = ((context *)(ctx))->callback_port_id;

  Dart_CObject response;

  context* _ctx = (context*)(ctx);

  if (err_code != 0) {
    response.type = Dart_CObject_kInt32;
    response.value.as_int32 = err_code;
  } else {
    if (strcmp(_ctx->entrypoint, RECV_TEXT) || strcmp(_ctx->entrypoint, SEND_TEXT)) {
        response = (Dart_CObject){
          .type = Dart_CObject_kNull,
        };
    } else {
        file_t *file = (file_t*)(value);

        response = (Dart_CObject){
          .type = Dart_CObject_kTypedData,
          .value = {
            .as_typed_data = {
              .type = Dart_TypedData_kUint8,
              .length = file->length,
              .values = file->data,
            }
          }
        };
    }
  }

  dart_message_sent = Dart_PostCObject_DL(callback_port_id, &response);

  if (!dart_message_sent) {
    printf("Sending callback result to dart isolate failed");
  }

  free(ctx);
}

int async_ClientSendText(uintptr_t client_id, char *msg, char **code_out, int32_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
    .callback_port_id = callback_port_id,
    .entrypoint = SEND_TEXT,
  };
  return ClientSendText(ctx, client_id, msg, code_out, async_callback);
}

// TODO: factor `file_name`, `lenght`, and `file_bytes` out to a struct.
int async_ClientSendFile(uintptr_t client_id, char *file_name, int32_t length, void *file_bytes, char **code_out, int32_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
    .callback_port_id = callback_port_id,
    .entrypoint = SEND_FILE,
  };
  return ClientSendFile(ctx, client_id, file_name, length, file_bytes, code_out, async_callback);
}

int async_ClientRecvText(uintptr_t client_id, char *code, int32_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
    .callback_port_id = callback_port_id,
    .entrypoint = RECV_TEXT,
  };
  return ClientRecvText(ctx, client_id, code, async_callback);
}
