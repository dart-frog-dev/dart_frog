import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:todos_data_source/todos_data_source.dart';

import '../../../routes/todos/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockTodosDataSource extends Mock implements TodosDataSource {}

class _MockUri extends Mock implements Uri {}

void main() {
  late RequestContext context;
  late Request request;
  late TodosDataSource dataSource;
  late Uri uri;

  const id = 'id';
  final todo = Todo(
    id: id,
    title: 'Test title',
    description: 'Test description',
  );

  setUpAll(() => registerFallbackValue(todo));

  setUp(() {
    context = _MockRequestContext();
    request = _MockRequest();
    dataSource = _MockTodosDataSource();
    uri = _MockUri();
    when(() => context.read<TodosDataSource>()).thenReturn(dataSource);
    when(() => context.request).thenReturn(request);
    when(() => request.uri).thenReturn(uri);
    when(() => uri.resolve(any())).thenAnswer(
      (answer) => Uri.parse(
        'http://localhost/todos${answer.positionalArguments.first}',
      ),
    );
    when(() => uri.queryParameters).thenReturn({});
  });

  group('responds with a 405', () {
    test('when method is DELETE', () async {
      when(() => request.method).thenReturn(HttpMethod.delete);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is HEAD', () async {
      when(() => request.method).thenReturn(HttpMethod.head);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is OPTIONS', () async {
      when(() => request.method).thenReturn(HttpMethod.options);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is PATCH', () async {
      when(() => request.method).thenReturn(HttpMethod.patch);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is PUT', () async {
      when(() => request.method).thenReturn(HttpMethod.put);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is QUERY', () async {
      when(() => request.method).thenReturn(HttpMethod.query);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });

  group('GET /todos', () {
    test('responds with a 200 and an empty list', () async {
      when(() => dataSource.readAll()).thenAnswer((_) async => []);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.json(), completion(isEmpty));

      verify(() => dataSource.readAll()).called(1);
    });

    test('responds with a 200 and a populated list', () async {
      when(() => dataSource.readAll()).thenAnswer((_) async => [todo]);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.json(), completion(equals([todo.toJson()])));

      verify(() => dataSource.readAll()).called(1);
    });
  });

  group('POST /todos', () {
    test('responds with a 201 and the newly created Todo', () async {
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => request.json()).thenAnswer((_) async {
        return <String, dynamic>{
          'title': 'Test title',
          'description': 'Test description',
          'isCompleted': false,
        };
      });
      when(() => dataSource.create(any())).thenAnswer((_) async => todo);

      final response = await route.onRequest(context);

      expect(response.statusCode, equals(HttpStatus.created));
      expect(response.json(), completion(equals(todo.toJson())));

      verify(() => dataSource.create(any())).called(1);
    });
  });
}
