import 'dart:convert';

import 'package:campus_incident_reporting_app/core/config/cloudinary_config.dart';
import 'package:campus_incident_reporting_app/core/services/image_uploader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends the photo with the unsigned preset and returns its link', () async {
    late http.BaseRequest sent;
    late String sentBody;
    final client = MockClient.streaming((request, bodyStream) async {
      sent = request;
      sentBody = utf8.decode(await bodyStream.toBytes(), allowMalformed: true);
      final reply = jsonEncode({'secure_url': 'https://res.cloudinary.com/x/a.jpg', 'public_id': 'pulse/a'});
      return http.StreamedResponse(Stream.value(utf8.encode(reply)), 200);
    });

    final image = await ImageUploader(client).uploadBytes([1, 2, 3], filename: 'leak.jpg');

    expect(sent.url, CloudinaryConfig.uploadUri);
    expect(sentBody, contains(CloudinaryConfig.uploadPreset));
    expect(sentBody, contains('leak.jpg'));
    expect(sentBody, isNot(contains('api_secret')));
    expect(image.url, 'https://res.cloudinary.com/x/a.jpg');
    expect(image.id, 'pulse/a');
  });

  test('reports Cloudinary errors instead of saving a broken link', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'error': {'message': 'Upload preset not found'},
        }),
        400,
      ),
    );

    expect(
      () => ImageUploader(client).uploadBytes([1], filename: 'a.jpg'),
      throwsA(isA<ImageUploadFailed>().having((e) => e.reason, 'reason', 'Upload preset not found')),
    );
  });

  test('treats network failures as upload failures', () async {
    final client = MockClient((_) async => throw const SocketExceptionStub());

    expect(() => ImageUploader(client).uploadBytes([1], filename: 'a.jpg'), throwsA(isA<ImageUploadFailed>()));
  });
}

class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
