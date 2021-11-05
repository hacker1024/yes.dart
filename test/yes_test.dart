// ignore_for_file: avoid_redundant_argument_values

import 'dart:io';

import 'package:test/test.dart';
import 'package:yes/yes.dart';

import 'sinks.dart';

void main() {
  const standardWriteCount = 20000;

  /// Starts a [yes] operation, stopping it when the given sink is written to
  /// [maxWriteCount] times.
  ///
  /// Returns the amount of times the [sink] was written to.
  Future<int> _writeLimitedAmount(
    IOSink sink, {
    String message = 'y',
    bool flushMayBeSync = true,
    int maxWriteCount = standardWriteCount,
  }) async {
    var writeCount = 0;
    late final YesController controller;
    final output = NotifyingIOSink(
      sink,
      onAdd: (_) {
        if (++writeCount >= maxWriteCount) controller.cancel();
      },
    );
    controller = yes(output, message, flushMayBeSync);
    await controller.done;
    return writeCount;
  }

  test(
    'Cancelling directly after a write stops immediately',
    () async {
      final sink = StringBufferIOSink();
      final writeCount = await _writeLimitedAmount(
        sink,
        flushMayBeSync: false,
        maxWriteCount: standardWriteCount,
      );
      expect(writeCount, standardWriteCount);
    },
  );

  test(
    'Output only contains repetitions of the given string and a newline',
    () async {
      // TODO: This test should fail if the yes function doesn't flush the
      // TODO: IOSink properly in between writes.
      // TODO: It currently passes, due to the usage of a memory-backed IOSink
      // TODO: implementation. Perhaps a small randomized write delay can be
      // TODO: introduced?
      final sink = StringBufferIOSink();
      await _writeLimitedAmount(
        sink,
        message: 'yes',
        flushMayBeSync: false,
        maxWriteCount: standardWriteCount,
      );
      final output = sink.toString();
      expect(output, matches(RegExp('(?:yes\\n){$standardWriteCount}')));
    },
  );

  test(
    'Synchronous flushes are handled correctly',
    () async {
      final sink = SyncFlushingStringBufferIOSink();
      final controller = yes(sink, 'y', true);
      // Let the event loop continue, so the following code will run in another
      // task (after it is reached in the event loop).
      // If a synchronous flush is not handled correctly, the next task will
      // never be reached, causing an infinite hang.
      await Future.delayed(Duration.zero);
      controller.cancel();
    },
  );

  test(
    'Asynchronous flushes are handled correctly when synchronous flushes are possible',
    () async {
      // Exactly like the test above, but check that asynchronous flushes still
      // work.
      final sink = StringBufferIOSink();
      final controller = yes(sink, 'y', true);
      await Future.delayed(Duration.zero);
      controller.cancel();
    },
  );
}
