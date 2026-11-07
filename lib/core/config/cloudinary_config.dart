abstract final class CloudinaryConfig {
  static const cloudName = 'ybzufhwg';
  static const uploadPreset = 'pulse_unsigned';

  static Uri get uploadUri => Uri.https('api.cloudinary.com', '/v1_1/$cloudName/image/upload');
}
