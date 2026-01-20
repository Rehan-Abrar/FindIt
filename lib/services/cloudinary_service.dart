import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

import '../config/cloudinary_config.dart';

class CloudinaryService {
  /// Uploads an image file or bytes to Cloudinary using an unsigned preset.
  /// Provide either [file] or [bytes]. Returns the `secure_url` on success, else null.
  static Future<String?> uploadImage({File? file, Uint8List? bytes, required String folder, required String filename}) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$CLOUDINARY_CLOUD_NAME/image/upload');
      final request = http.MultipartRequest('POST', uri);

      // Prefer server-signed uploads if an endpoint is configured.
      if (CLOUDINARY_SIGNING_ENDPOINT.isNotEmpty) {
        try {
          final signUri = Uri.parse(CLOUDINARY_SIGNING_ENDPOINT + '?folder=' + Uri.encodeComponent(folder));
          final signResp = await http.get(signUri).timeout(const Duration(seconds: 8));
          if (signResp.statusCode >= 200 && signResp.statusCode < 300) {
            final body = json.decode(signResp.body) as Map<String, dynamic>;
            // Expecting { api_key, timestamp, signature }
            request.fields['api_key'] = body['api_key']?.toString() ?? '';
            request.fields['timestamp'] = body['timestamp']?.toString() ?? '';
            request.fields['signature'] = body['signature']?.toString() ?? '';
            request.fields['folder'] = folder;
          } else {
            // fallback to unsigned preset if signing endpoint fails
            request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;
            request.fields['folder'] = folder;
          }
        } catch (e) {
          // fallback to unsigned preset on any error
          request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;
          request.fields['folder'] = folder;
        }
      } else if (CLOUDINARY_API_KEY.isNotEmpty && CLOUDINARY_API_SECRET.isNotEmpty) {
        // If API key and secret are provided locally, perform client-side signed upload (insecure).
        final ts = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
        final params = <String, String>{
          'folder': folder,
          'timestamp': ts.toString(),
        };
        final sortedKeys = params.keys.toList()..sort();
        final toSign = sortedKeys.map((k) => '$k=${params[k]}').join('&') + CLOUDINARY_API_SECRET;
        final signature = sha1.convert(utf8.encode(toSign)).toString();

        request.fields['api_key'] = CLOUDINARY_API_KEY;
        request.fields['timestamp'] = ts.toString();
        request.fields['signature'] = signature;
        request.fields['folder'] = folder;
      } else {
        // unsigned upload using preset
        request.fields['upload_preset'] = CLOUDINARY_UPLOAD_PRESET;
        request.fields['folder'] = folder;
      }

      if (bytes != null) {
        final multipartFile = http.MultipartFile.fromBytes('file', bytes, filename: filename);
        request.files.add(multipartFile);
      } else if (file != null) {
        final multipartFile = await http.MultipartFile.fromPath('file', file.path, filename: filename);
        request.files.add(multipartFile);
      } else {
        return null;
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        return body['secure_url'] as String?;
      } else {
        // Log for debugging
        // ignore: avoid_print
        print('Cloudinary upload failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Cloudinary upload exception: $e');
      return null;
    }
  }
}
