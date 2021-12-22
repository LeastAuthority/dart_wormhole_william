#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dart_api.h>
#include <dart_api_dl.h>

#include "libwormhole_william.h"

#ifdef DDESTINY_DEBUG_LOGS
#define debugmsg(msg) printf("C | %s:%d: " msg "\n", __FILE_NAME__, __LINE__)
#define debugf(format, ...)                                                    \
  printf("C | %s:%d: " format "\n", __FILE_NAME__, __LINE__, __VA_ARGS__)
#else
#define debugmsg(msg)
#define debugf(format, ...)
#endif

typedef struct {
  intptr_t callback_port_id;
  intptr_t progress_port_id;
  const char *entrypoint;
} context;

const char *SEND_TEXT = "context/send_text";
const char *RECV_TEXT = "context/recv_text";
const char *SEND_FILE = "context/send_file";
const char *RECV_FILE = "context/recv_file";

intptr_t init_dart_api_dl(void *data) { return Dart_InitializeApiDL(data); }

#define DartSend(port, message)                                                \
  Dart_CObject response = (Dart_CObject){                                      \
      .type = Dart_CObject_kInt64, .value.as_int64 = (int64_t)(message)};      \
  if (!Dart_PostCObject_DL(port, &response)) {                                 \
    debugf("Sending message %p to port %d failed", message, port);             \
  }

bool entrypoint_is(context *ctx, const char *other) {
  return strcmp(ctx->entrypoint, other) == 0;
}

void async_callback(void *ptr, result_t *result) {
  DartSend(((context *)ptr)->callback_port_id, result);
}

void update_progress_callback(void *ptr, progress_t *progress) {
  DartSend(((context *)ptr)->progress_port_id, progress);
}

codegen_result_t *async_ClientSendText(uintptr_t client_id, char *msg,
                                       intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .callback_port_id = callback_port_id,
      .entrypoint = SEND_TEXT,
  };
  return ClientSendText(ctx, client_id, msg, async_callback);
}

// TODO: factor `file_name`, `lenght`, and `file_bytes` out to a struct.
codegen_result_t *async_ClientSendFile(uintptr_t client_id, char *file_name,
                                       int32_t length, void *file_bytes,
                                       intptr_t callback_port_id,
                                       intptr_t progress_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .callback_port_id = callback_port_id,
      .entrypoint = SEND_FILE,
      .progress_port_id = progress_port_id,
  };
  return ClientSendFile(ctx, client_id, file_name, length, file_bytes,
                        async_callback, update_progress_callback);
}

int async_ClientRecvText(uintptr_t client_id, char *code,
                         intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .callback_port_id = callback_port_id,
      .entrypoint = RECV_TEXT,
  };
  return ClientRecvText((void *)(ctx), client_id, code, async_callback);
}

int async_ClientRecvFile(uintptr_t client_id, char *code,
                         intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .callback_port_id = callback_port_id,
      .entrypoint = RECV_FILE,
  };
  return ClientRecvFile((void *)(ctx), client_id, code, async_callback);
}
