import 'dart:io';

/// Writes the given [message], followed by a newline, to the given [sink]
/// repeatedly.
///
/// If no [message] is provided, `y` will be used.
///
/// [flushMayBeSync] must be true if the [sink]'s [IOSink.flush] implementation
/// can return a synchronous future. If it is set incorrectly, the event loop
/// will be blocked until the sink closes.
/// When it's safe to do so, setting [flushMayBeSync] to false can offer a
/// significant performance boost.
///
/// Returns a [YesController] that can be used to monitor and terminate the
/// operation.
YesController yes(
  IOSink sink, [
  String message = 'y',
  bool flushMayBeSync = // ignore: avoid_positional_boolean_parameters
      true,
]) {
  final messageData = sink.encoding.encode('$message\n');
  var stopWriting = false;

  Future<void> start() async {
    sink.done.then((_) => stopWriting = true);
    // ignore: literal_only_boolean_expressions
    while (!stopWriting) {
      try {
        sink.add(messageData);
        await sink.flush();
        // If the flush operation could be synchronous, let the event loop
        // continue, and resume in the next task.
        if (flushMayBeSync) await Future<void>.delayed(Duration.zero);
      } on IOException {
        // Stop writing data when the sink stops accepting it.
        break;
      }
    }
  }

  void stop() => stopWriting = true;

  return YesController(start(), stop);
}

/// An object used to monitor and terminate a `yes` operation.
class YesController {
  /// A [Future] that completes when the operation terminates.
  final Future<void> done;

  /// A function that can be called to terminate the operation.
  final void Function() cancel;

  const YesController(this.done, this.cancel);
}
