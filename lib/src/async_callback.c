#include <stdio.h>
#include <stdint.h>

#include "bindings.h"
#include "include/dart_api.h"
#include "include/dart_api_dl.h"

int64_t main_send_port;

void main() {
}

intptr_t init_dart_api_dl(void* data) {
  return Dart_InitializeApiDL(data);
}

typedef context struct {
    intptr callback_port;
} context;

void async(void *ctx, void *value, int32_t err_code) {
    // Construct Dart object from C API.
    //  (see: https://github.com/dart-lang/sdk/blob/master/runtime/include/dart_native_api.h#L19)
    Dart_CObject dart_object;
    //dart_object.type = Dart_CObject_kInt32;
    //dart_object.value.as_int32 = value;

    if (err_code != 0) {
    // TODO: throw error / exception whatever using Dart native api ...
    // TODO: maybe construct dart error object
    }

    intptr_t callback_port = (context*)(ctx)->callback_port;
    // Send dart object response.
    auto result = Dart_PostCObject_DL(callback_port, &dart_object);
}

void client_send_text(uintptr_t clientPtr, char *msg, char **_codeOut, intptr callback_port) {
    context ctx = {
        callback_port
    };

    ClientSendFile(ctx, clientPtr, msg, _codeOut, &async);
}