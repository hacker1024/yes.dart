import 'dart:async';
import 'dart:io';

import 'package:yes/yes.dart';

/// A clone of the unix `yes` utility.
void main(List<String> arguments) {
  // Parse the message to output, or use the default `y`.
  final String message;
  if (arguments.isEmpty) {
    message = 'y';
  } else {
    message = arguments[0];
  }

  // Start the yes operation.
  final controller = yes(stdout, message);

  // Stop on SIGINT.
  late final StreamSubscription sigintSubscription;
  sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
    sigintSubscription.cancel();
    controller.cancel();
  });
}
