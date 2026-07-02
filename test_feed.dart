import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/producto/feed1'));
  if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = json.decode(response.body);
    if (jsonResponse.isNotEmpty) {
      print(jsonResponse.first);
    }
  }
}
