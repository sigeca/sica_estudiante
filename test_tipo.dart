import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/tipooferta/tipooferta_flutter'));
  if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = json.decode(response.body)['data'];
    final tipos = jsonResponse.map((e) => e['nombre'].toString()).toList();
    print('Tipos from API: $tipos');
  }
}
