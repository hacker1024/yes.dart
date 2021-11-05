import 'dart:async';
import 'dart:convert';
import 'dart:io';

mixin IOSinkMixin implements IOSink {
  final _completer = Completer<void>();

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _completer.completeError(error);
  }

  @override
  Future addStream(Stream<List<int>> stream) => stream.listen((data) {
        add(data);
      }).asFuture();

  @override
  Future close() => (_completer..complete()).future;

  @override
  Future get done => _completer.future;

  @override
  Future flush() async {}

  @override
  void write(Object? object) {
    final string = '$object';
    if (string.isEmpty) return;
    add(encoding.encode(string));
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    final iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object? object = ""]) {
    write(object);
    write('\n');
  }
}

/// A [StringBuffer] that implements [IOSink].
///
/// [add]ed data is encoded with [encoding] (permitting malformed characters)
/// and appended to the buffer.
class StringBufferIOSink extends StringBuffer implements IOSink {
  final _completer = Completer<void>();

  @override
  Utf8Codec get encoding => utf8;

  @override
  set encoding(Encoding encoding) =>
      throw StateError('Encoding is not mutable!');

  @override
  void add(List<int> data) =>
      write(encoding.decode(data, allowMalformed: false));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _completer.completeError(error);
  }

  @override
  Future addStream(Stream<List<int>> stream) => stream.listen((data) {
        add(data);
      }).asFuture();

  @override
  Future close() => (_completer..complete()).future;

  @override
  Future get done => _completer.future;

  @override
  Future flush() async {}
}

/// A variant of [StringBufferIOSink] that returns a synchronous [Future] when
/// [flush] is called.
class SyncFlushingStringBufferIOSink extends StringBufferIOSink {
  @override
  Future flush() => Future.sync(() => null);
}

class NotifyingIOSink implements IOSink {
  final IOSink _inner;
  final void Function(List<int> data)? _onAdd;
  final void Function(Object? object)? _onWrite;

  const NotifyingIOSink(
    this._inner, {
    void Function(List<int> data)? onAdd,
    void Function(Object? object)? onWrite,
  })  : _onAdd = onAdd,
        _onWrite = onWrite;

  @override
  Encoding get encoding => _inner.encoding;

  @override
  set encoding(Encoding encoding) => _inner.encoding = encoding;

  @override
  void add(List<int> data) {
    _onAdd?.call(data);
    _inner.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inner.addError(error, stackTrace);

  @override
  Future addStream(Stream<List<int>> stream) => _inner.addStream(stream);

  @override
  Future close() => _inner.close();

  @override
  Future get done => _inner.done;

  @override
  Future flush() => _inner.flush();

  @override
  void write(Object? object) {
    _onWrite?.call(object);
    _inner.write(object);
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) =>
      _inner.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _inner.writeCharCode(charCode);

  @override
  void writeln([Object? object = ""]) => _inner.writeln(object);
}
