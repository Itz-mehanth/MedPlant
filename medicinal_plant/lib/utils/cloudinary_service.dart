import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medicinal_plant/keys.dart';

class CloudinaryService {
  // Use a free unsigned upload credential for initial setup
  // User should replace these with their own or use a signed backend
  static const String cloudName = 'duypl5tt4'; // Demo cloud name for quickstart, usually better to ask user
  
  static const String _cloudName = Keys.cloudinaryCloudName;
  static const String _uploadPreset = Keys.cloudinaryUploadPreset;

  static Future<String?> uploadImage(String filePath) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        print('Cloudinary Upload Failed: ${response.statusCode}');
        print('Response Body: $responseString');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }
}
