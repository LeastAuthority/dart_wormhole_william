#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <dart_api.h>
#include <dart_api_dl.h>

#include "libwormhole_william.h"

#ifdef DESTINY_DEBUG_LOGS
#define debugmsg(msg) printf("C | %s:%d: " msg "\n", __FILE_NAME__, __LINE__)
#define debugf(format, ...)                                                    \
  printf("C | %s:%d: " format "\n", __FILE_NAME__, __LINE__, __VA_ARGS__)
#else
#define debugmsg(msg)
#define debugf(format, ...)
#endif

typedef int64_t (*seekf_dart)(Dart_Handle, int64_t, int32_t whence);

typedef struct {
  intptr_t read_args_port;

  struct {
    void *context;
    uint8_t *buffer;
    int length;
  } args;

  struct {
    bool done;
    int bytes_read;
  } call_state;
} read_state;

typedef struct {
  const char *entrypoint;
  const void *logging_context;

  intptr_t progress_port_id;

  intptr_t callback_port_id;

  read_state read;
  seekf_dart seek;
  Dart_Handle file;
} context;

const char *SEND_TEXT = "context/send_text";
const char *RECV_TEXT = "context/recv_text";
const char *SEND_FILE = "context/send_file";
const char *RECV_FILE = "context/recv_file";

intptr_t init_dart_api_dl(void *data) { return Dart_InitializeApiDL(data); }

#define DartSend(port, message)                                                \
  {                                                                            \
    Dart_CObject response = (Dart_CObject){                                    \
        .type = Dart_CObject_kInt64, .value.as_int64 = (int64_t)(message)};    \
    if (!Dart_PostCObject_DL(port, &response)) {                               \
      debugf("Sending message %p to port %d failed", message, port);           \
    }                                                                          \
  }

int read_callback(void *ctx, uint8_t *bytes, int length) {
  debugf("Calling read_callback with ctx:%p, bytes:%p, length:%d", ctx, bytes,
         length);
  context *_ctx = (context *)(ctx);

  _ctx->read.call_state.done = false;
  _ctx->read.args.context = _ctx;
  _ctx->read.args.buffer = bytes;
  _ctx->read.args.length = length;

  if (!Dart_PostInteger_DL(_ctx->read.read_args_port,
                           (int64_t)(&(_ctx->read.args)))) {
    debugmsg("Failed to send read call args to dart");
  }

  while (!_ctx->read.call_state.done)
    ;
  return _ctx->read.call_state.bytes_read;
}

int64_t seek_callback(void *ctx, int64_t offset, int whence) {
  debugf("Calling seek_callback with ctx:%p, offset:%d, whence:%d", ctx, offset,
         whence);
  context *_ctx = (context *)(ctx);

  return _ctx->seek(_ctx->file, offset, whence);
}

void read_done(void *ctx, int64_t length) {
  context *_ctx = (context *)ctx;
  _ctx->read.call_state.bytes_read = length;
  _ctx->read.call_state.done = true;
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
                                       intptr_t callback_port_id,
                                       intptr_t progress_port_id,
                                       Dart_Handle file,
                                       intptr_t read_args_port,
                                       seekf_dart seek) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .callback_port_id = callback_port_id,
      .entrypoint = SEND_FILE,
      .progress_port_id = progress_port_id,
      .file = file,
      .read.read_args_port = read_args_port,
      .read.call_state.done = false,
      .seek = seek,
  };
  return ClientSendFile(ctx, client_id, file_name, async_callback,
                        update_progress_callback, read_callback, seek_callback);
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
                         intptr_t callback_port_id, intptr_t progress_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .callback_port_id = callback_port_id,
      .entrypoint = RECV_FILE,
      .progress_port_id = progress_port_id,
  };
  return ClientRecvFile((void *)(ctx), client_id, code, async_callback,
                        update_progress_callback);
}
