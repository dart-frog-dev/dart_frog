// Not needed for test file
// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/photos/upload.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  group('POST /upload', () {
    test('responds with a 400 when file extension is not .png', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();
      when(() => context.request).thenReturn(request);

      final formData = FormData(
        fields: {},
        files: {
          'photo': [
            UploadedFile(
              'file.txt',
              ContentType.text,
              Stream.fromIterable([[]]),
            ),
          ],
        },
      );
      when(request.formData).thenAnswer((_) async => formData);

      final response = await route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.badRequest));
    });

    test('responds with a 200', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();
      when(() => context.request).thenReturn(request);

      final formData = FormData(
        fields: {},
        files: {
          'photo': [
            UploadedFile(
              'picture.png',
              ContentType('image', 'png'),
              Stream.fromIterable([[]]),
            ),
          ],
        },
      );
      when(request.formData).thenAnswer((_) async => formData);

      final response = await route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.json(),
        completion(
          equals({'message': 'Successfully uploaded picture.png'}),
        ),
      );
    });
  });
}
