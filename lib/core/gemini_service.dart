import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final String _apiKey =
      dotenv.env['GEMINI_API_KEY']!; // Ganti dengan API Key
  static final String _model =
      dotenv.env['GEMINI_MODEL']!; // Gratis (Flash 2.5)

  /// Kirim gambar nota ke Gemini API dan parsing hasilnya ke JSON
  static Future<Map<String, dynamic>> parseReceipt(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final prompt = '''
You are a receipt parser. Analyze the uploaded receipt and return a JSON with this format:
{
  "date": "YYYY-MM-DD",
  "total": 12345.67,
  "items": [
    { "name": "Item name", "qty": 1, "price": 123.45 }
  ]
}
If data is missing, use null or 0.
''';

    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey");

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image,
              }
            }
          ]
        }
      ]
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to call Gemini API: ${response.body}");
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

    if (text == null) throw Exception("No response text from Gemini API");

    // Bersihkan response agar menjadi JSON valid
    final cleanedText =
        text.replaceAll("```json", "").replaceAll("```", "").trim();

    return jsonDecode(cleanedText);
  }
}
