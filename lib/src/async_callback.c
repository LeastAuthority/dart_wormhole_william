#include <stdbool.h>
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
#define debugf(format, ...)                                                    \
  printf("C | %s:%d: " format "\n", __FILE_NAME__, __LINE__, __VA_ARGS__)
#else
#define debugmsg(msg)
#define debugf(format, ...)
#endif

typedef struct {
  intptr_t callback_port_id;
  const char *entrypoint;
} context;

const char *SEND_TEXT = "context/send_text";
const char *RECV_TEXT = "context/recv_text";
const char *SEND_FILE = "context/send_file";
const char *RECV_FILE = "context/recv_file";

intptr_t init_dart_api_dl(void *data) { return Dart_InitializeApiDL(data); }

bool entrypoint_is(context *ctx, const char *other) {
  return strcmp(ctx->entrypoint, other) == 0;
}

// TODO we need to decide if Go should be freeing the result on its end or not
// It seems like the Dart_PostCObject_DL function does not block until the
// message is handled and Go currently frees the result as soon as
// async_callback exits
//
// There seems to be two ways to free the memory when it is safe to do so:
// - Explicitly calling free_result after the client is done with the result
// - Adding a finalizer and returning a dart object with the free_result
// function as its finalizer
//
// The first approach adds a bit more boilerplate in the client implementation
// but is explicit.
//
// The second one does not seem straightforward to implement but if implemented
// will have the least friction for the client implementation.

result_t *copy_result(result_t result) {
  result_t *copy = malloc(sizeof(result_t));
  *copy = result;

  if (result.err_string != NULL) {
    copy->err_string = malloc(strlen(result.err_string) * sizeof(char));
    strcpy(copy->err_string, result.err_string);
  }

  if (result.file != NULL) {
    copy->file = malloc(sizeof(file_t));
    *copy->file = *result.file;

    copy->file->data = malloc(result.file->length);
    memcpy(copy->file->data, result.file->data, result.file->length);

    copy->file->file_name =
        malloc(strlen(result.file->file_name) * sizeof(char));
    strcpy(copy->file->file_name, result.file->file_name);
  }

  return copy;
}

void free_result(result_t *result) {
  debugf("Freeing result located at %p", result);
  if (result->err_string != NULL) {
    free(result->err_string);
  }

  if (result->file != NULL) {
    if (result->file->data != NULL) {
      free(result->file->data);
    }

    if (result->file->file_name != NULL) {
      free(result->file->file_name);
    }

    free(result->file);
  }

  if (result->received_text != NULL) {
    free(result->received_text);
  }

  free(result);
}

void async_callback(void *ptr, result_t *result) {
  debugf("result: %p", result);
  bool dart_message_sent = false;
  context *ctx = (context *)(ptr);
  intptr_t callback_port_id = ctx->callback_port_id;
  int32_t err_code = result->err_code;

  result_t *copy = copy_result(*result);

  Dart_CObject response = (Dart_CObject){.type = Dart_CObject_kInt64,
                                         .value.as_int64 = (int64_t)(copy)};

  debugf("Result pointer: %u\nEntrypoint: %s\nResult was: file:%p, "
         "err_code:%d, err_string:%s, "
         "received_text:%s",
         copy, ctx->entrypoint, result->file, result->err_code,
         result->err_string, result->received_text);

  dart_message_sent = Dart_PostCObject_DL(callback_port_id, &response);

  if (!dart_message_sent) {
    debugmsg("Sending callback result to dart isolate failed");
  }

  free(ctx);
}

int async_ClientSendText(uintptr_t client_id, char *msg, char **code_out,
                         intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .callback_port_id = callback_port_id,
      .entrypoint = SEND_TEXT,
  };
  return ClientSendText(ctx, client_id, msg, code_out, async_callback);
}

// TODO: factor `file_name`, `lenght`, and `file_bytes` out to a struct.
int async_ClientSendFile(uintptr_t client_id, char *file_name, int32_t length,
                         void *file_bytes, char **code_out,
                         intptr_t callback_port_id) {
  context *ctx = (context *)(malloc(sizeof(context)));
  *ctx = (context){
      .callback_port_id = callback_port_id,
      .entrypoint = SEND_FILE,
  };
  return ClientSendFile(ctx, client_id, file_name, length, file_bytes, code_out,
                        async_callback);
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
