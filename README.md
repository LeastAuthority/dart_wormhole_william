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
[app](https://github.com/LeastAuthority/flutter_wormhole_gui).
