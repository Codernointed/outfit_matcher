import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiApiService {
  static const String _apiKey = 'AIzaSyC_iVAGdmwlszToZOawkyInMc497Wd3hQE';
  static const String _endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static Future<Map<String, String>?> analyzeClothingItem(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final requestBody = {
        "contents": [
          {
            "parts": [
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image
                }
              },
              {
                "text": "You are a fashion assistant. Analyze this clothing item and return a JSON object with the following keys: itemType (e.g. Top, Bottom, Dress, Outerwear, Shoes, Accessory), primaryColor (e.g. Blue, Black, Red, etc.), and patternType (e.g. Solid, Striped, Floral, Checkered, etc.). Only return the JSON object, no explanation."
              }
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        final content = jsonDecode(response.body);
        final text = content['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        // Try to extract JSON from response text
        final jsonStart = text.indexOf('{');
        final jsonEnd = text.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonString = text.substring(jsonStart, jsonEnd + 1);
          final Map<String, dynamic> result = jsonDecode(jsonString);
          return {
            'itemType': result['itemType'] ?? '',
            'primaryColor': result['primaryColor'] ?? '',
            'patternType': result['patternType'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      print('Gemini API error: $e');
      return null;
    }
  }
}
