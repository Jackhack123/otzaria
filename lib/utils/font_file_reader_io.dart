import 'dart:io';

List<int> readBytesSync(String path) {
  // הקריאה סינכרונית כדי לSave על API סינכרוני של lists גופנים.
  return File(path).readAsBytesSync();
}
