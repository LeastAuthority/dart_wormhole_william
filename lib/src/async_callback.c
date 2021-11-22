#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dart_api.h>
#include <dart_api_dl.h>

#include "libwormhole_william.h"
// TODO define this in the build
#define DEBUG

#ifdef DEBUG
#define debugmsg(msg) printf("C | %s:%d: " msg "\n", __FILE_NAME__, __LINE__)
#define debugf(format, ...) printf("C | %s:%d: " format "\n", __FILE_NAME__, __LINE__, __VA_ARGS__)
#else
#define debugmsg(msg)
#define debugf(format, ...)
#endif


typedef struct {
    intptr_t callback_port_id;
    const char* entrypoint;
} context;

const char* SEND_TEXT = "context/send_text";
const char* RECV_TEXT = "context/recv_text";
const char* SEND_FILE = "context/send_file";
const char* RECV_FILE = "context/recv_file";

intptr_t init_dart_api_dl(void *data) { return Dart_InitializeApiDL(data); }

bool entrypoint_is(context *ctx, const char *other) {
  return strcmp(ctx->entrypoint, other) == 0;
}

void async_callback(void *ptr, result_t *result) {
  debugf("result: %p", result);
  bool dart_message_sent = false;
  context* ctx = (context*)(ptr);
  intptr_t callback_port_id = ctx->callback_port_id;
  int32_t err_code = result->err_code;

  Dart_CObject response;

  // TODO: use codes enum (?)
  debugf("ctx->entrypoint: %s", ctx->entrypoint);
  if (err_code != 0) {
    debugf("err_code: %d", err_code);
    response.type = Dart_CObject_kInt32;
    response.value.as_int32 = err_code;
  } else if (entrypoint_is(ctx, SEND_FILE)) {
    debugmsg("SEND_FILE");
      response = (Dart_CObject){
        .type = Dart_CObject_kNull,
      };
  } else if (entrypoint_is(ctx, SEND_TEXT)) {
    debugmsg("SEND_TEXT");
      response = (Dart_CObject){
        .type = Dart_CObject_kNull,
      };
  } else if (entrypoint_is(ctx, RECV_FILE)) {
    debugmsg("RECV_FILE");
      file_t *file = (file_t*)(result->file);

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
  } else if (entrypoint_is(ctx, RECV_TEXT)) {
    debugmsg("RECV_TEXT");
      file_t *file = (file_t*)(result->file);

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

  dart_message_sent = Dart_PostCObject_DL(callback_port_id, &response);

  if (!dart_message_sent) {
    debugmsg("Sending callback result to dart isolate failed");
  }

  free(ctx);
}

int async_ClientSendText(uintptr_t client_id, char *msg, char **code_out, intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
    .callback_port_id = callback_port_id,
    .entrypoint = SEND_TEXT,
  };
  return ClientSendText(ctx, client_id, msg, code_out, async_callback);
}

// TODO: factor `file_name`, `lenght`, and `file_bytes` out to a struct.
int async_ClientSendFile(uintptr_t client_id, char *file_name, int32_t length, void *file_bytes, char **code_out, intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
    .callback_port_id = callback_port_id,
    .entrypoint = SEND_FILE,
  };
  return ClientSendFile(ctx, client_id, file_name, length, file_bytes, code_out, async_callback);
}

int async_ClientRecvText(uintptr_t client_id, char *code, intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
    .callback_port_id = callback_port_id,
    .entrypoint = RECV_TEXT,
  };
  return ClientRecvText((void*)(ctx), client_id, code, async_callback);
}

int async_ClientRecvFile(uintptr_t client_id, char *code, intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
    .callback_port_id = callback_port_id,
    .entrypoint = RECV_FILE,
  };
  return ClientRecvFile((void*)(ctx), client_id, code, async_callback);
}
