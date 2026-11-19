import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../routes/projects/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

void main() {
  group('GET /', () {
    test('responds with a 405', () async {
      final request = Request.get(Uri.parse('http://localhost/'));
      final context = _MockRequestContext();
      when(() => context.request).thenReturn(request);
      final response = await route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
      expect(response.body(), completion(isEmpty));
    });
  });

  group('POST /', () {
    final contentTypeFormUrlEncodedHeader = {
      HttpHeaders.contentTypeHeader: ContentType(
        'application',
        'x-www-form-urlencoded',
      ).mimeType,
    };
    test('responds with a 200 and an empty project configuration', () async {
      final request = Request.post(
        Uri.parse('http://localhost/'),
        headers: contentTypeFormUrlEncodedHeader,
      );
      final context = _MockRequestContext();
      when(() => context.request).thenReturn(request);
      final response = await route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.json(),
        completion(equals({'project_configuration': const <String, String>{}})),
      );
    });

    test('responds with a 200 and a populated project configuration', () async {
      final request = Request.post(
        Uri.parse('http://localhost/'),
        headers: contentTypeFormUrlEncodedHeader,
        body: 'name=my_app&version=3.3.8',
      );
      final context = _MockRequestContext();
      when(() => context.request).thenReturn(request);
      final response = await route.onRequest(context);
      expect(response.statusCode, equals(HttpStatus.ok));
      expect(
        response.json(),
        completion(
          equals({
            'project_configuration': const <String, List<String>>{
              'name': ['my_app'],
              'version': ['3.3.8'],
            },
          }),
        ),
      );
    });
  });
}
