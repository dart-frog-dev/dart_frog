import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

final contentTypePng = ContentType('image', 'png');

Future<Response> onRequest(RequestContext context) async {
  final formData = await context.request.formData();
  final photo = formData.files['photo']?.first;

  if (photo == null || photo.contentType.mimeType != contentTypePng.mimeType) {
    return Response(statusCode: HttpStatus.badRequest);
  }

  return Response.json(
    body: {'message': 'Successfully uploaded ${photo.name}'},
  );
}
