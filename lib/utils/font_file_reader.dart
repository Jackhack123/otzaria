import 'font_file_reader_stub.dart'
    if (dart.library.io) 'font_file_reader_io.dart' as impl;

/// קורא file פונט מהדיסק.
///
/// בדסקטופ (dart:io) זה נתמך.
/// ב-web זה יזרוק UnsupportedError.
class FontFileReader {
  FontFileReader._();

  static List<int> readBytesSync(String path) => impl.readBytesSync(path);
}
