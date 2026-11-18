import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:todos_data_source/todos_data_source.dart';

FutureOr<Response> onRequest(RequestContext context, String id) async {
  final dataSource = context.read<TodosDataSource>();
  final todo = await dataSource.read(id);

  if (todo == null) {
    return Response(statusCode: HttpStatus.notFound, body: 'Not found');
  }

  switch (context.request.method) {
    case HttpMethod.get:
      return _get(context, todo);
    case HttpMethod.put:
      return _put(context, id, todo);
    case HttpMethod.delete:
      return _delete(context, id);
    case _:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}

Future<Response> _get(RequestContext context, Todo todo) async {
  return Response.json(body: todo);
}

Future<Response> _put(RequestContext context, String id, Todo todo) async {
  final dataSource = context.read<TodosDataSource>();
  final updatedTodo = Todo.fromJson(
    await context.request.json() as Map<String, dynamic>,
  );
  final newTodo = await dataSource.update(
    id,
    todo.copyWith(
      title: updatedTodo.title,
      description: updatedTodo.description,
      isCompleted: updatedTodo.isCompleted,
    ),
  );

  return Response.json(body: newTodo);
}

Future<Response> _delete(RequestContext context, String id) async {
  final dataSource = context.read<TodosDataSource>();
  await dataSource.delete(id);
  return Response(statusCode: HttpStatus.noContent);
}
