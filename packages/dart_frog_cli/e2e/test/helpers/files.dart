import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

File fileAt(String filePath, {required Directory on}) {
  return File(path.join(on.path, filePath));
}

final exists = FileExistsMatcher(isTrue);
final doesNotExist = FileExistsMatcher(isFalse);

class FileExistsMatcher extends CustomMatcher {
  FileExistsMatcher(Matcher matcher)
    : super(
        'File exists',
        'file exists',
        isA<File>().having((p) => p.existsSync(), 'exists', matcher),
      );
}
