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
    char *error_msg;
  } call_state;
} read_state;

typedef struct {
  int64_t write_args_port;

  struct {
    void *context;
    uint8_t *buffer;
    int32_t length;
  } args;

  volatile struct {
    bool done;
    char *error_msg;
  } call_state;
} write_state;

typedef struct {
  int64_t seek_args_port;

  struct {
    void *context;
    int64_t new_offset;
    int32_t whence;
  } args;

  volatile struct {
    bool done;
    int64_t current_offset;
    const char *error_msg;
  } call_state;
} seek_state;

typedef struct {
  const char *entrypoint;

  int64_t progress_port_id;
  int64_t result_port_id;
  int64_t codegen_result_port_id;
  int64_t file_metadata_port_id;

  write_state write;
  read_state read;
  seek_state seek;
} context;

const char *SEND_TEXT = "context/send_text";
const char *RECV_TEXT = "context/recv_text";
const char *SEND_FILE = "context/send_file";
const char *RECV_FILE = "context/recv_file";

int64_t init_dart_api_dl(void *data) { return Dart_InitializeApiDL(data); }

char *copy_str(const char *str) {
  if (str == NULL)
    return NULL;
  char *copy = malloc(strlen(str) + 1);
  strcpy(copy, str);
  return copy;
}

#define DartSend(port, message)                                                \
  {                                                                            \
    Dart_CObject response = (Dart_CObject){                                    \
        .type = Dart_CObject_kInt64, .value.as_int64 = (int64_t)(message)};    \
    if (!Dart_PostCObject_DL(port, &response)) {                               \
      debugf("Sending message %p to port %ld failed", message, port);          \
      abort();                                                                 \
    }                                                                          \
  }

read_result_t read_callback(void *ctx, uint8_t *bytes, int length) {
  context *_ctx = (context *)(ctx);

  _ctx->read.call_state.done = false;
  _ctx->read.call_state.bytes_read = -1;
  _ctx->read.call_state.error_msg = NULL;
  _ctx->read.args.buffer = bytes;
  _ctx->read.args.length = length;

  DartSend(_ctx->read.read_args_port, &(_ctx->read.args));

  while (!_ctx->read.call_state.done)
    ;
  return (read_result_t){.bytes_read = _ctx->read.call_state.bytes_read,
                         .error_msg = _ctx->read.call_state.error_msg};
}

char *write_callback(void *ctx, uint8_t *bytes, int32_t length) {
  context *_ctx = (context *)(ctx);

  _ctx->write.call_state.done = false;
  _ctx->write.call_state.error_msg = NULL;
  _ctx->write.args.buffer = bytes;
  _ctx->write.args.length = length;

  DartSend(_ctx->write.write_args_port, &(_ctx->write.args));

  while (!_ctx->write.call_state.done)
    ;

  return _ctx->write.call_state.error_msg;
}

seek_result_t seek_callback(void *ctx, int64_t offset, int32_t whence) {
  context *_ctx = (context *)(ctx);

  _ctx->seek.call_state.done = false;
  _ctx->seek.call_state.error_msg = NULL;
  _ctx->seek.call_state.current_offset = -1;
  _ctx->seek.args.new_offset = offset;
  _ctx->seek.args.whence = whence;
  _ctx->seek.args.context = _ctx;

  DartSend(_ctx->seek.seek_args_port, &(_ctx->seek.args));

  while (!_ctx->seek.call_state.done)
    ;

  return (seek_result_t){.current_offset = _ctx->seek.call_state.current_offset,
                         .error_msg = _ctx->seek.call_state.error_msg};
}

void seek_done(void *ctx, int64_t current_offset, char *error_msg) {
  context *_ctx = (context *)ctx;
  _ctx->seek.call_state.current_offset = current_offset;
  _ctx->seek.call_state.error_msg = copy_str(error_msg);
  _ctx->seek.call_state.done = true;
}

void read_done(void *ctx, int64_t length, char *error_msg) {
  context *_ctx = (context *)ctx;
  _ctx->read.call_state.bytes_read = length;
  _ctx->read.call_state.error_msg = copy_str(error_msg);
  _ctx->read.call_state.done = true;
}

void write_done(void *ctx, char *error_msg) {
  context *_ctx = (context *)ctx;
  _ctx->write.call_state.error_msg = copy_str(error_msg);
  _ctx->write.call_state.done = true;
}

void notify(void *ptr, result_t *result) {
  DartSend(((context *)ptr)->result_port_id, result);
}

void notify_codegen(void *ptr, codegen_result_t *result) {
  DartSend(((context *)ptr)->codegen_result_port_id, result);
}

void update_progress(void *ptr, progress_t *progress) {
  DartSend(((context *)ptr)->progress_port_id, progress);
}

void log_callback(void *context, char *msg) {
  debugf("wormhole-william:ctx:%p: %s", context, msg);
}

void set_file_metadata(void *ctx, file_metadata_t *fmd) {
  DartSend(((context *)ctx)->file_metadata_port_id, fmd);
}

void free_context(context *ctx) {
  if (ctx != NULL) {
    free(ctx);
  } else {
    debugf("Trying to free a null context. ctx:%p", ctx);
    abort();
  }
}

client_config_t new_config(const char *app_id, const char *transit_relay_url,
                           const char *rendezvous_url,
                           int32_t passphrase_length) {
  return (client_config_t){
      .app_id = copy_str(app_id),
      .transit_relay_url = copy_str(transit_relay_url),
      .rendezvous_url = copy_str(rendezvous_url),
      .passphrase_length = passphrase_length,
  };
}

wrapped_context_t *new_wrapped_context(client_context_t clientCtx,
                                       client_config_t config) {
  wrapped_context_t *wctx =
      (wrapped_context_t *)(calloc(1, sizeof(wrapped_context_t)));
  *wctx = (wrapped_context_t){.clientCtx = clientCtx,
                              .config = config,
                              .impl = {.notify = notify,
                                       .notify_codegen = notify_codegen,
                                       .update_progress = update_progress,
                                       .update_metadata = set_file_metadata,
                                       .log = log_callback,
                                       .write = write_callback,
                                       .seek = seek_callback,
                                       .read = read_callback,
                                       .free_client_ctx = free_context}};
  return wctx;
}

wrapped_context_t *async_ClientSendText(char *app_id, char *transit_relay_url,
                                        char *rendezvous_url,
                                        int32_t passphrase_component_length,
                                        char *msg, int64_t result_port_id,
                                        int64_t codegen_result_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .codegen_result_port_id = codegen_result_port_id,
      .result_port_id = result_port_id,
      .entrypoint = SEND_TEXT,
  };

  wrapped_context_t *wctx = new_wrapped_context(
      ctx, new_config(app_id, transit_relay_url, rendezvous_url,
                      passphrase_component_length));
  ClientSendText(wctx, msg);
  return wctx;
}

wrapped_context_t *
async_ClientSendFile(char *app_id, char *transit_relay_url,
                     char *rendezvous_url, int passphrase_component_length,
                     char *file_name, int64_t codegen_result_port_id,
                     int64_t result_port_id, int64_t progress_port_id,
                     int64_t read_args_port, int64_t seek_args_port) {
  context *ctx = (context *)(calloc(1, sizeof(context)));
  *ctx = (context){
      .entrypoint = SEND_FILE,
      .read.call_state.done = false,
      .seek.call_state.done = false,
      .result_port_id = result_port_id,
      .codegen_result_port_id = codegen_result_port_id,
      .progress_port_id = progress_port_id,
      .read.read_args_port = read_args_port,
      .seek.seek_args_port = seek_args_port,
  };

  ctx->read.args.context = ctx;
  wrapped_context_t *wctx = new_wrapped_context(
      ctx, new_config(app_id, transit_relay_url, rendezvous_url,
                      passphrase_component_length));
  ClientSendFile(wctx, file_name);
  return wctx;
}

wrapped_context_t *async_ClientRecvText(char *app_id, char *transit_relay_url,
                                        char *rendezvous_url,
                                        int passphrase_component_length,
                                        char *code, int64_t result_port_id) {
  context *ctx = (context *)(calloc(1, sizeof(context)));
  *ctx = (context){
      .result_port_id = result_port_id,
      .entrypoint = RECV_TEXT,
  };

  wrapped_context_t *wctx = new_wrapped_context(
      ctx, new_config(app_id, transit_relay_url, rendezvous_url,
                      passphrase_component_length));
  ClientRecvText(wctx, code);

  return wctx;
}

wrapped_context_t *async_ClientRecvFile(
    char *app_id, char *transit_relay_url, char *rendezvous_url,
    int passphrase_component_length, char *code, int64_t result_port_id,
    int64_t progress_port_id, int64_t fmd_port_id, int64_t write_args_port_id) {
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

  wrapped_context_t *wctx = new_wrapped_context(
      ctx, new_config(app_id, transit_relay_url, rendezvous_url,
                      passphrase_component_length));
  ClientRecvFile(wctx, code);
  return wctx;
}

void accept_download(void *wctx) { return AcceptDownload(wctx); }

void reject_download(void *wctx) { return RejectDownload(wctx); }

void cancel_transfer(void *wctx) { return CancelTransfer(wctx); }

void finalize(void *wctx) { return Finalize(wctx); }
