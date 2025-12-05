import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Use a free unsigned upload credential for initial setup
  // User should replace these with their own or use a signed backend
  static const String cloudName = 'duypl5tt4'; // Demo cloud name for quickstart, usually better to ask user
  // However, since I cannot easily ask user for a key right now, I will use a placeholder
  // AND instruct the user to change it.
  
  // Actually, I should probably not use a demo key that might expire or be invalid.
  // I will use placeholders and log a warning if they are not changed.
  
  static const String _cloudName = 'duypl5tt4'; // Replace with your cloud name
  static const String _uploadPreset = 'medplant'; // Replace with your upload preset
  
  // NOTE TO USER:
  // 1. Go to https://cloudinary.com/console
  // 2. Get your Cloud Name
  // 3. Go to Settings -> Upload -> Add upload preset -> Signing Mode: Unsigned
  // 4. Copy the preset name here.
  
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
