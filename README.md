# yes
A Dart package that constantly writes a string to an `IOSink`, simillarly to the UNIX `yes` utility.

## Usage
```dart
// Write to stdout for 5 seconds.
final controller = yes(stdout, message);
await Future<void>.delayed(const Duration(seconds: 5));
controller.cancel();
```

```dart
// Write to a process's stdin for 5 seconds, and kill it.
// Wait for the yes operation to complete (which occurs when stdin closes)
// before continuing.
final process = await Process.start('cat', const []);
process.stdout.pipe(stdout);
final controller = yes(process.stdin);
Future.delayed(const Duration(seconds: 5))
    .then((_) => process.kill(ProcessSignal.sigint));
await controller.done;
print('Done!');
```

A complete UNIX `yes` utility clone can be found in the example project.

### Performance notes
In order not to block the event loop, one write at most is performed each loop.
While this should be fine in most cases, output speed is severely bottlenecked.
This can be mitigated by repeating the given message several times:

```dart
yes(stdout, 'y\ny\ny\ny');
```

Additionally, by default, the given `IOSink`'s `flush` future is considered as possibly
synchronous, so an additional event loop loop is added to prevent the event loop from
blocking. If the `flush` future is guaranteed to be asynchronous, then the additional
loop can be avoided.

```dart
yes(stdout, 'y', false);
```

## License

```dart
MIT License

Copyright (c) 2021 hacker1024

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
