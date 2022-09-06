# Magic Wormhole for Dart

⚠ This plugin is a work in progress, use at your own risk ⚠

A flutter plugin that wraps [wormhole-william](https://github.com/LeastAuthority/wormhole-william) into a Dart API.

Supported functionality

- [x] Send/Receive files
- [x] Send/Receive text

## Examples

Sending files:

```dart
final client = Client();
client.sendFile(File("/home/user/hello.txt")).then((codegenResult) {
  print("Enter ${codegenResult.code} to receive the file");
});
```

Receiving files:

```dart
final client = Client();
final download = client.recvFile("1-revenue-gazelle");
download.pendingDownload.accept(File("/home/user/${download.pendingDownload.fileName}"));
download.done.then((result) {
  print("Received file ${download.pendingDownload.fileName}");
});
```

## Building

Currently this plugin is only buildable as part of the build for this
[app](https://github.com/LeastAuthority/destiny).

## Known Issues

Dart does not support callbacks from `wormhole-william` from multiple threads. The
plugin implements function calls by sending the arguments to a
[Dart send port](https://api.dart.dev/stable/2.16.1/dart-isolate/SendPort-class.html) and handling
the messages to resolve on Dart. The C stack is kept in a busy loop until the
dart function is completed. Once [this issue](https://github.com/dart-lang/sdk/issues/37022)
is resolved, we can cleanup that code to be much simpler and less error prone.
