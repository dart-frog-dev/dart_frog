import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:todos_data_source/todos_data_source.dart';

import '../../../routes/todos/[id].dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockTodosDataSource extends Mock implements TodosDataSource {}

void main() {
  late RequestContext context;
  late Request request;
  late TodosDataSource dataSource;

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
    when(() => context.read<TodosDataSource>()).thenReturn(dataSource);
    when(() => context.request).thenReturn(request);
    when(() => request.headers).thenReturn({});
  });

  group('responds with a 405', () {
    setUp(() {
      when(() => dataSource.read(any())).thenAnswer((_) async => todo);
    });

    test('when method is HEAD', () async {
      when(() => request.method).thenReturn(HttpMethod.head);

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is OPTIONS', () async {
      when(() => request.method).thenReturn(HttpMethod.options);

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is PATCH', () async {
      when(() => request.method).thenReturn(HttpMethod.patch);

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is POST', () async {
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });

    test('when method is QUERY', () async {
      when(() => request.method).thenReturn(HttpMethod.query);

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.methodNotAllowed));
    });
  });

  group('responds with a 404', () {
    test('if no todo is found', () async {
      when(() => dataSource.read(any())).thenAnswer((_) async => null);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.notFound));

      verify(() => dataSource.read(any(that: equals(id)))).called(1);
    });
  });

  group('GET /todos/[id]', () {
    test('responds with a 200 and the found todo', () async {
      when(() => dataSource.read(any())).thenAnswer((_) async => todo);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.ok));
      await expectLater(response.json(), completion(equals(todo.toJson())));

      verify(() => dataSource.read(any(that: equals(id)))).called(1);
    });
  });

  group('PUT /todos/[id]', () {
    test('responds with a 200 and updates the todo', () async {
      final updatedTodo = todo.copyWith(title: 'New title');

      when(() => dataSource.read(any())).thenAnswer((_) async => todo);
      when(
        () => dataSource.update(any(), any()),
      ).thenAnswer((_) async => updatedTodo);
      when(() => request.method).thenReturn(HttpMethod.put);
      when(() => request.json()).thenAnswer((_) async => updatedTodo.toJson());

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.ok));
      expect(response.json(), completion(equals(updatedTodo.toJson())));

      verify(() => dataSource.read(any(that: equals(id)))).called(1);
      verify(
        () => dataSource.update(
          any(that: equals(id)),
          any(that: equals(updatedTodo)),
        ),
      ).called(1);
    });
  });

  group('DELETE /todos/[id]', () {
    test('responds with a 204 and deletes the todo', () async {
      when(() => dataSource.read(any())).thenAnswer((_) async => todo);
      when(() => dataSource.delete(any())).thenAnswer((_) async => {});
      when(() => request.method).thenReturn(HttpMethod.delete);

      final response = await route.onRequest(context, id);

      expect(response.statusCode, equals(HttpStatus.noContent));
      expect(response.body(), completion(isEmpty));

      verify(() => dataSource.read(any(that: equals(id)))).called(1);
      verify(() => dataSource.delete(any(that: equals(id)))).called(1);
    });
  });
}
