import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/evento/evento_flutter');
  for (var id in ['1', '51', '608', '614']) {
    final response = await http.post(url, body: {'idpersona': id});
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('data')) {
        final data = decoded['data'];
        if (data is List && data.isNotEmpty) {
          print('Found for idpersona: $id');
          print(data.first.keys);
          print(data.first);
          return;
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        print('Found for idpersona: $id');
        print(decoded.first.keys);
        print(decoded.first);
        return;
      }
    }
  }
}
