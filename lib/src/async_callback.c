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
  int64_t read_args_port;

  struct {
    void *context;
    uint8_t *buffer;
    int32_t length;
  } args;

  volatile struct {
    bool done;
    int bytes_read;
  } call_state;
} read_state;

typedef struct {
  int64_t write_args_port;

  int32_t download_id;

  struct {
    void *context;
    uint8_t *buffer;
    int32_t length;
  } args;

  volatile struct {
    bool done;
    bool successful;
  } call_state;
} write_state;

typedef struct {
  const char *entrypoint;

  int64_t progress_port_id;
  int64_t result_port_id;
  int64_t file_metadata_port_id;

  int32_t transfer_id;

  write_state write;
  read_state read;
  seekf_dart seek;
  Dart_Handle file;
} context;

typedef int32_t client_id_t;

const char *SEND_TEXT = "context/send_text";
const char *RECV_TEXT = "context/recv_text";
const char *SEND_FILE = "context/send_file";
const char *RECV_FILE = "context/recv_file";

int64_t init_dart_api_dl(void *data) { return Dart_InitializeApiDL(data); }

#define DartSend(port, message)                                                \
  {                                                                            \
    Dart_CObject response = (Dart_CObject){                                    \
        .type = Dart_CObject_kInt64, .value.as_int64 = (int64_t)(message)};    \
    if (!Dart_PostCObject_DL(port, &response)) {                               \
      debugf("Sending message %p to port %ld failed", message, port);          \
      abort();                                                                 \
    }                                                                          \
  }

int read_callback(void *ctx, uint8_t *bytes, int length) {
  context *_ctx = (context *)(ctx);

  _ctx->read.call_state.done = false;
  _ctx->read.args.buffer = bytes;
  _ctx->read.args.length = length;

  DartSend(_ctx->read.read_args_port, &(_ctx->read.args));

  while (!_ctx->read.call_state.done)
    ;
  return _ctx->read.call_state.bytes_read;
}

int write_callback(void *ctx, uint8_t *bytes, int32_t length) {
  context *_ctx = (context *)(ctx);

  _ctx->write.call_state.done = false;
  _ctx->write.args.buffer = bytes;
  _ctx->write.args.length = length;

  DartSend(_ctx->write.write_args_port, &(_ctx->write.args));

  while (!_ctx->write.call_state.done)
    ;

  return _ctx->write.call_state.successful;
}

int64_t seek_callback(void *ctx, int64_t offset, int whence) {
  context *_ctx = (context *)(ctx);

  return _ctx->seek(_ctx->file, offset, whence);
}

void read_done(void *ctx, int64_t length) {
  context *_ctx = (context *)ctx;
  _ctx->read.call_state.bytes_read = length;
  _ctx->read.call_state.done = true;
}

void write_done(void *ctx, bool successful) {
  context *_ctx = (context *)ctx;
  _ctx->write.call_state.successful = successful;
  _ctx->write.call_state.done = true;
}

bool entrypoint_is(context *ctx, const char *other) {
  return strcmp(ctx->entrypoint, other) == 0;
}

void async_callback(void *ptr, result_t *result) {
  DartSend(((context *)ptr)->result_port_id, result);
}

void update_progress_callback(void *ptr, progress_t *progress) {
  DartSend(((context *)ptr)->progress_port_id, progress);
}

void log_callback(void *context, char *msg) {
  debugf("wormhole-william:ctx:%p: %s", context, msg);
}

void set_file_metadata(void *ctx, file_metadata_t *fmd) {
  debugf("Setting file metadata: length:%ld, file_name:%s, download_id:%d, "
         "context:%p",
         fmd->length, fmd->file_name, fmd->download_id, fmd->context);
  ((context *)ctx)->transfer_id = fmd->download_id;
  fmd->context = ctx;
  DartSend(((context *)ctx)->file_metadata_port_id, fmd);
}

void free_context(context *ctx) {
  if (ctx != NULL) {
    free(ctx);
  }
}

wrapped_context_t *new_wrapped_context(client_context_t clientCtx,
                                       int32_t go_client_id) {
  wrapped_context_t *wctx =
      (wrapped_context_t *)(calloc(1, sizeof(wrapped_context_t)));
  *wctx =
      (wrapped_context_t){.clientCtx = clientCtx,
                          .go_client_id = go_client_id,
                          .impl = {.notify = async_callback,
                                   .update_progress = update_progress_callback,
                                   .update_metadata = set_file_metadata,
                                   .log = log_callback,
                                   .write = write_callback,
                                   .seek = seek_callback,
                                   .read = read_callback,
                                   .free_client_ctx = free_context}};
  return wctx;
}

codegen_result_t *async_ClientSendText(client_id_t client_id, char *msg,
                                       int64_t result_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .result_port_id = result_port_id,
      .entrypoint = SEND_TEXT,
  };

  wrapped_context_t *wctx = new_wrapped_context(ctx, client_id);

  return ClientSendText(wctx, msg);
}

codegen_result_t *async_ClientSendFile(client_id_t client_id, char *file_name,
                                       int64_t result_port_id,
                                       int64_t progress_port_id,
                                       Dart_Handle file, int64_t read_args_port,
                                       seekf_dart seek) {
  context *ctx = (context *)(calloc(1, sizeof(context)));
  *ctx = (context){
      .result_port_id = result_port_id,
      .entrypoint = SEND_FILE,
      .progress_port_id = progress_port_id,
      .file = file,
      .read.read_args_port = read_args_port,
      .read.call_state.done = false,
      .seek = seek,
  };

  ctx->read.args.context = ctx;
  wrapped_context_t *wctx = new_wrapped_context(ctx, client_id);
  codegen_result_t *result = ClientSendFile(wctx, file_name);
  ctx->transfer_id = result->generated.transfer_id;
  return result;
}

int async_ClientRecvText(client_id_t client_id, char *code,
                         int64_t result_port_id) {
  context *ctx = (context *)(calloc(1, sizeof(context)));
  *ctx = (context){
      .result_port_id = result_port_id,
      .entrypoint = RECV_TEXT,
  };

  wrapped_context_t *wctx = new_wrapped_context(ctx, client_id);

  return ClientRecvText(wctx, code);
}

int async_ClientRecvFile(client_id_t client_id, char *code,
                         int64_t result_port_id, int64_t progress_port_id,
                         int64_t fmd_port_id, int64_t write_args_port_id) {
  context *ctx = (context *)(calloc(1, sizeof(context)));
  *ctx = (context){
      .result_port_id = result_port_id,
      .entrypoint = RECV_FILE,
      .progress_port_id = progress_port_id,
      .file_metadata_port_id = fmd_port_id,
      .write.call_state.done = false,
      .write.write_args_port = write_args_port_id,
  };

  ctx->write.args.context = ctx;

  wrapped_context_t *wctx = new_wrapped_context(ctx, client_id);

  return ClientRecvFile(wctx, code);
}

void accept_download(void *ctx) {
  return AcceptDownload(((context *)ctx)->write.download_id);
}

void reject_download(void *ctx) {
  return RejectDownload(((context *)ctx)->write.download_id);
}

void cancel_transfer(void *ctx) {
  return CancelTransfer(((context *)ctx)->transfer_id);
}

int32_t finalize(int32_t clientId) { return Finalize(clientId); }
