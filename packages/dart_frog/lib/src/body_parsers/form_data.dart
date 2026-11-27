import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

/// Content-Type: application/x-www-form-urlencoded
final formUrlEncodedContentType = ContentType(
  'application',
  'x-www-form-urlencoded',
);

/// Content-Type: multipart/form-data
final multipartFormDataContentType = ContentType(
  'multipart',
  'form-data',
);

/// Parses the body as form data and returns a `Future<Map<String, dynamic>>`.
/// Throws a [StateError] if the MIME type is not "application/x-www-form-urlencoded" or "multipart/form-data".
/// https://fetch.spec.whatwg.org/#ref-for-dom-body-formdata%E2%91%A0
Future<FormData> parseFormData({
  required Map<String, String> headers,
  required Future<String> Function() body,
  required Stream<List<int>> Function() bytes,
}) async {
  final contentType = _extractContentType(headers);
  final isFormUrlEncoded = _isFormUrlEncoded(contentType);
  final isMultipartFormData = _isMultipartFormData(contentType);

  if (!isFormUrlEncoded && !isMultipartFormData) {
    throw StateError(
      '''
Body could not be parsed as form data due to an invalid MIME type.
Expected MIME type: "${formUrlEncodedContentType.mimeType}" OR "${multipartFormDataContentType.mimeType}"
Actual MIME type: "${contentType?.mimeType ?? ''}"
''',
    );
  }

  return isFormUrlEncoded
      ? _extractFormUrlEncodedFormData(body: await body())
      : await _extractMultipartFormData(headers: headers, bytes: bytes());
}

ContentType? _extractContentType(Map<String, String> headers) {
  final contentTypeValue = headers[HttpHeaders.contentTypeHeader];
  if (contentTypeValue == null) return null;
  return ContentType.parse(contentTypeValue);
}

bool _isFormUrlEncoded(ContentType? contentType) {
  if (contentType == null) return false;
  return contentType.mimeType == formUrlEncodedContentType.mimeType;
}

bool _isMultipartFormData(ContentType? contentType) {
  if (contentType == null) return false;
  return contentType.mimeType == multipartFormDataContentType.mimeType;
}

FormData _extractFormUrlEncodedFormData({required String body}) {
  final query = Uri.splitQueryString(body);
  final fields = <String, List<String>>{};

  query.forEach((k, v) => fields.putIfAbsent(k, () => []).add(v));
  return FormData(fields: fields, files: {});
}

final _keyValueRegexp = RegExp('(?:(?<key>[a-zA-Z0-9-_]+)="(?<value>.*?)";*)+');

Future<FormData> _extractMultipartFormData({
  required Map<String, String> headers,
  required Stream<List<int>> bytes,
}) async {
  final contentType = headers[HttpHeaders.contentTypeHeader]!;
  final mediaType = MediaType.parse(contentType);
  final boundary = mediaType.parameters['boundary'];
  final transformer = MimeMultipartTransformer(boundary!);

  final fields = <String, List<String>>{};
  final files = <String, List<UploadedFile>>{};

  await for (final part in transformer.bind(bytes)) {
    final contentDisposition = part.headers['content-disposition'];
    if (contentDisposition == null) continue;
    if (!contentDisposition.startsWith('form-data;')) continue;

    final values = _keyValueRegexp
        .allMatches(contentDisposition)
        .fold(<String, String>{}, (map, match) {
      return map..[match.namedGroup('key')!] = match.namedGroup('value')!;
    });

    final name = values['name']!;
    final fileName = values['filename'];

    if (fileName != null) {
      files.putIfAbsent(name, () => []).add(
            UploadedFile(
              fileName,
              ContentType.parse(part.headers['content-type'] ?? 'text/plain'),
              part,
            ),
          );
    } else {
      final bytes = (await part.toList()).fold(<int>[], (p, e) => p..addAll(e));
      fields.putIfAbsent(name, () => []).add(utf8.decode(bytes));
    }
  }

  return FormData(fields: fields, files: files);
}

/// {@template form_data}
/// The fields and files of received form data request.
/// {@endtemplate}
class FormData with MapMixin<String, List<String>> {
  /// {@macro form_data}
  const FormData({
    required Map<String, List<String>> fields,
    required Map<String, List<UploadedFile>> files,
  })  : _fields = fields,
        _files = files;

  final Map<String, List<String>> _fields;

  final Map<String, List<UploadedFile>> _files;

  /// The fields that were submitted in the form.
  Map<String, List<String>> get fields => Map.unmodifiable(_fields);

  /// The files that were uploaded in the form.
  Map<String, List<UploadedFile>> get files => Map.unmodifiable(_files);

  @override
  @Deprecated('Use `fields[key]` to retrieve values')
  List<String>? operator [](Object? key) => _fields[key];

  @override
  @Deprecated('Use `fields.keys` to retrieve field keys')
  Iterable<String> get keys => _fields.keys;

  @override
  @Deprecated('Use `fields.values` to retrieve field values')
  Iterable<List<String>> get values => _fields.values;

  @override
  @Deprecated(
    'FormData should be immutable, in the future this will thrown an error',
  )
  void operator []=(String key, List<String> value) => _fields[key] = value;

  @override
  @Deprecated(
    'FormData should be immutable, in the future this will thrown an error',
  )
  void clear() => _fields.clear();

  @override
  @Deprecated(
    'FormData should be immutable, in the future this will thrown an error',
  )
  List<String>? remove(Object? key) => _fields.remove(key);
}

/// {@template uploaded_file}
/// The uploaded file of a form data request.
/// {@endtemplate}
class UploadedFile {
  /// {@macro uploaded_file}
  const UploadedFile(
    this.name,
    this.contentType,
    this._byteStream,
  );

  /// The name of the uploaded file.
  final String name;

  /// The type of the uploaded file.
  final ContentType contentType;

  final Stream<List<int>> _byteStream;

  /// Read the content of the file as a list of bytes.
  ///
  /// Can only be called once.
  Future<List<int>> readAsBytes() async {
    return (await _byteStream.toList())
        .fold<List<int>>([], (p, e) => p..addAll(e));
  }

  /// Open the content of the file as a stream of bytes.
  ///
  /// Can only be called once.
  Stream<List<int>> openRead() => _byteStream;

  @override
  String toString() {
    return '{ name: $name, contentType: $contentType }';
  }
}
