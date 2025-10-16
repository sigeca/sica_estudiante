import 'dart:convert';
import 'package:http/http.dart' as http;
import 'evento.dart';
import 'portafolio.dart';

class ApiService {

  static Future<List<Estudiante>> obtenerEstudiantes(String idevento, String fecha) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/asistencia/asistencia_dataflutter?idevento=$idevento&fecha=$fecha');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => Estudiante.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener los estudiantes');
    }
  }


static Future<void> actualizarAsistencia(int idasistencia, int idtipoasistencia) async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/asistencia/update_flutter');

  final response = await http.post(url, body: {
    'idasistencia': idasistencia.toString(),
    'idtipoasistencia': idtipoasistencia.toString(),
  });

  if (response.statusCode != 200) {
    throw Exception('Error al actualizar asistencia');
  }
}


static Future<void> registrarAsistenciaAll({
  required String idevento,
  required String fecha,
}) async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/asistencia/save_allasistencia/');
  final response = await http.post(url, body: {
    'idevento': idevento,
    'fecha': fecha,
    'idtipoasistencia': '1',
    'comentario': 'inicial',
    'idpersona': '0',
  });

  if (response.statusCode != 200) {
    throw Exception('❌ Error al registrar asistencia masiva');
  }
}






    static Future<List<Evento>> fetchEventos(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/evento/evento_flutter');
    final response = await http.post(
      url,
      body: {
        'idpersona': idpersona,
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => Evento.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar eventos');
    }
  }



 static Future<Persona> fetchPersonaInfo(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/persona/persona_flutter');
    final response = await http.post(
      url,
      body: {
        'idpersona': idpersona,
      },
    );
if (response.statusCode == 200) {
    final json = jsonDecode(response.body);

    final data = json['data'];

    if (data != null && data.isNotEmpty) {
      return Persona.fromJson(data[0]);
    } else {
      throw Exception('No se encontró la persona con id: $idpersona');
    }
  } else {
    throw Exception('Error al cargar persona: ${response.statusCode}');
  }



 }







  static Future<List<Portafolio>> fetchPortafolio(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/portafolio/portafolio_flutter?idpersona=$idpersona');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => Portafolio.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar portafolio');
    }
  }

static Future<List<SesionEvento>> fetchSesiones(String idevento) async {
  final response = await http.post(
    Uri.parse('https://educaysoft.org/sica/index.php/sesionevento/sesionevento_dataflutter'),
    body: {'idevento': idevento},
  );

  if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
     return data.map((e) => SesionEvento.fromJson(e)).toList();


  } else {
    throw Exception('Error al cargar sesiones');
  }
}

static Future<List<Asistencia>> fetchAsistencias(String idevento, String idpersona) async {
  final response = await http.post(
    Uri.parse('https://educaysoft.org/sica/index.php/asistencia/asistencia_personaflutter'),
    body: {'idevento': idevento,'idpersona': idpersona},
  );

  if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
     return data.map((e) => Asistencia.fromJson(e)).toList();


  } else {
    throw Exception('Error al cargar sesiones');
  }
}



static Future<List<Participacion>> fetchParticipaciones(String idevento, String idpersona) async {
  final response = await http.post(
    Uri.parse('https://educaysoft.org/sica/index.php/participacion/participacion_personaflutter'),
    body: {'idevento': idevento,'idpersona': idpersona},
  );

  if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
     return data.map((e) => Participacion.fromJson(e)).toList();


  } else {
    throw Exception('Error al cargar sesiones');
  }
}


static Future<List<Nota>> fetchNotasAll(String idevento, String idpersona) async {
  final response = await http.post(
    Uri.parse('https://educaysoft.org/sica/index.php/participacion/participacion_personaAllflutter'),
    body: {'idevento': idevento,'idpersona': idpersona},
  );

  if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
     return data.map((e) => Nota.fromJson(e)).toList();


  } else {
    throw Exception('Error al cargar sesiones');
  }
}






static Future<List<Nota>> fetchNotas(String idevento, String idpersona) async {
  final response = await http.post(
    Uri.parse('https://educaysoft.org/sica/index.php/participacion/participacion_persona2flutter'),
    body: {'idevento': idevento,'idpersona': idpersona},
  );

  if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
     return data.map((e) => Nota.fromJson(e)).toList();


  } else {
    throw Exception('Error al cargar sesiones');
  }
}



static Future<List<Pago>> fetchPagos(String idevento, String idpersona) async {
  final response = await http.post(
    Uri.parse('https://educaysoft.org/sica/index.php/pagoevento/pagoevento_personaflutter'),
    body: {'idevento': idevento,'idpersona': idpersona},
  );

  if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
     return data.map((e) => Pago.fromJson(e)).toList();


  } else {
    throw Exception('Error al cargar sesiones');
  }
}









 static Future<List<DocumentoPortafolio>> fetchDocumentosPortafolio(String idportafolio) async {
    final response = await http.post(
      Uri.parse('https://educaysoft.org/sica/index.php/documentoportafolio/documentoportafolio_dataflutter'),
      body: {'idportafolio': idportafolio},
    );

    if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
      return data.map((json) => DocumentoPortafolio.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener documentos');
    }
  }

static Future<List<Participante>> fetchParticipantes(String idevento) async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/participante/participante_dataflutter?idevento=$idevento');

    final response = await http.get(url);
  if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
     return data.map((e) => Participante.fromJson(e)).toList();


  } else {
    throw Exception('Error al cargar sesiones');
  }
}



 static Future<List<Login>> login(String email, String password) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/login/login_flutter');

      final response = await http.post(url, body: {
        'email': email.trim(),
        'password': password,
      });

      if (response.statusCode == 200) {
     final json = jsonDecode(response.body);
     final List data = json['data'];
    if (data is List && data.isNotEmpty) {
      return data.map((json) => Login.fromJson(json)).toList();
 } else {
      return [];
    }
    } else {
      throw Exception('Error de red o inesperado:');
    }
  }



static Future<List<Vendedor>> fetchVendedores() async {
  final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/vendedor/vendedor1')); // Asegúrate de que esta URL exista y devuelva los datos de la vista.

  if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((vendedor) => Vendedor.fromJson(vendedor)).toList();
  } else {
    throw Exception('Error al cargar la lista de vendedores');
  }
}

static Future<List<Producto>> fetchProductosPorVendedor(String idpersona) async {
   final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/producto/producto1?idpersona=$idpersona'));
   if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = json.decode(response.body);
     return jsonResponse.map((data) => Producto.fromJson(data)).toList();
   } else {
     throw Exception('Failed to load articles');
   }
 }

static Future<List<Producto>> fetchProductosCarrito(String idpersona) async {
   final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/carrito/carrito1?idpersona=$idpersona'));
   if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = json.decode(response.body);
     return jsonResponse.map((data) => Producto.fromJson(data)).toList();
   } else {
     throw Exception('Failed to load articles');
   }
 }





}
