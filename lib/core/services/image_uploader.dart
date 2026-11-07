import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/cloudinary_config.dart';
import '../utils/failure.dart';

final imageUploaderProvider = Provider<ImageUploader>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ImageUploader(client);
});

class UploadedImage {
  const UploadedImage({required this.url, required this.id});

  final String url;
  final String id;
}

class ImageUploadFailed extends AppException {
  const ImageUploadFailed(this.reason);

  final String reason;

  @override
  String get message => 'The photo could not be uploaded. Check your connection and try again.';
}

class ImageUploader {
  ImageUploader(this._client);

  final http.Client _client;

  Future<UploadedImage> upload(File photo) async =>
      uploadBytes(await photo.readAsBytes(), filename: photo.uri.pathSegments.last);

  Future<UploadedImage> uploadBytes(List<int> bytes, {required String filename}) async {
    final request = http.MultipartRequest('POST', CloudinaryConfig.uploadUri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on Exception catch (error) {
      throw ImageUploadFailed(error.toString());
    }

    final body = _decode(response.body);
    final url = body['secure_url'];
    final id = body['public_id'];
    if (response.statusCode != 200 || url is! String || id is! String) {
      final error = body['error'];
      throw ImageUploadFailed(error is Map ? '${error['message']}' : 'HTTP ${response.statusCode}');
    }
    return UploadedImage(url: url, id: id);
  }

  Map<String, dynamic> _decode(String text) {
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } on FormatException {
      return const {};
    }
  }
}
