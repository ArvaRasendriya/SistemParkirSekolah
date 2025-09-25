import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> uploadSim(String filePath) async {
  var uri = Uri.parse("https://simocr.vercel.app/api/scan");

  var request = http.MultipartRequest('POST', uri);
  request.files.add(await http.MultipartFile.fromPath('file', filePath));

  var response = await request.send();
  var body = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final data = jsonDecode(body);
    print("OCR Result: ${data['text']}");
    if (data['detected']) {
      print("✅ SIM terdeteksi");
    } else {
      print("❌ Bukan SIM");
    }
  } else {
    print("Error: $body");
  }
}
