import 'dart:convert';
import 'package:http/http.dart' as http;
import 'evento.dart';
import 'portafolio.dart';

class ApiService {

  // ... (Funciones de Eventos/Asistencia/Participación/Pagos se mantienen sin cambios) ...

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
      try {
        final decoded = json.decode(response.body);

        List<Evento> eventos = [];

        if (decoded is List) {
          eventos = decoded.map((e) => Evento.fromJson(e)).toList();
        } else if (decoded is Map && decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is List) {
            eventos = data.map((e) => Evento.fromJson(e)).toList();
          }
        } else {
          throw Exception(
              'Error al procesar la información de los eventos. Formato inesperado: ${decoded.runtimeType}');
        }

        return eventos;
      } catch (e) {
        throw Exception('Error al procesar la información de los eventos. Detalle: $e');
      }
    } else {
      throw Exception('Error al conectar con el servidor (${response.statusCode})');
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
        // 🎯 LÍNEA AGREGADA: Muestra la respuesta completa del servidor
      print('Respuesta JSON de la API de Persona: ${response.body}');
      try {
        final decoded = json.decode(response.body);
        final List<dynamic>? dataList = decoded['data'];

if (dataList != null && dataList.isNotEmpty) {
        // PASO CLAVE 2: Obtener el primer (y único) mapa de persona
        final Map<String, dynamic> personaMap = Map<String, dynamic>.from(dataList.first);
        
        // Opcional: Imprimir la cédula extraída para confirmar
        print('Cédula extraída del JSON: ${personaMap['cedula']}');

        return Persona.fromJson(personaMap);
      } else {
        throw Exception('Respuesta de la API de Persona vacía o sin clave "data".');
      }


      } catch (e) {
        throw Exception(
            'Error al procesar la información de la persona. Detalle: $e');
      }
    } else {
      throw Exception(
          'Error al conectar con el servidor (${response.statusCode})');
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

static Future<List<Tema>> fetchTema(String idtema) async {
    final response = await http.post(
      Uri.parse('https://educaysoft.org/sica/index.php/tema/tema_dataflutter'),
      body: {'idtema': idtema},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => Tema.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar tema');
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
          // Si el servidor devuelve un 200 pero el array de datos está vacío (credenciales incorrectas)
          throw Exception('Credenciales incorrectas.');
        }
      } else {
        // Error de red o del servidor
        throw Exception('Error de red o servidor: ${response.statusCode}');
      }
    }



  static Future<List<Vendedor>> fetchVendedores() async {
    final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/vendedor/vendedor1')); 

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


// --- MEDICACIÓN ---

  // 1. Obtener la lista de medicamentos de una persona
static Future<List<Medicacion>> fetchMedicaciones(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/medicacion/medicacion_personaflutter');
    
    final response = await http.post(url, body: {'idpersona': idpersona});

    if (response.statusCode == 200) {
      try {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> data = [];

        // 1. Verificamos si es un Mapa con clave 'data'
        if (decoded is Map<String, dynamic>) {
           // AQUÍ EL CAMBIO: Verificamos explícitamente que no sea null
           if (decoded['data'] != null && decoded['data'] is List) {
             data = decoded['data']; 
           }
        } 
        // 2. O si es una Lista directa
        else if (decoded is List) {
           data = decoded;
        }

        return data.map((e) => Medicacion.fromJson(e)).toList();

      } catch (e) {
        print("Error parseando JSON: $e");
        // Devolvemos lista vacía en vez de explotar la app, para que el usuario pueda seguir
        return []; 
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }
  } 




// 2. Obtener los detalles (dosis/frecuencia) de un medicamento específico
  // Esto es útil para cuando expandes la tarjeta en la UI
  static Future<List<DetalleMedicacion>> fetchDetallesMedicacion(String idmedicacion) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/detallemedicacion/detalle_dataflutter');
    
    final response = await http.post(
      url,
      body: {'idmedicacion': idmedicacion},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List data = decoded['data'];
      return data.map((e) => DetalleMedicacion.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar detalles de medicación');
    }
  }

// En lib/api_service.dart

  // 4. Guardar el detalle (Dosis)
  static Future<void> registrarDetalleMedicacion(
        String idmedicacion, String detalle, String fechadesde, String fechahasta) async {

    final url = Uri.parse('https://educaysoft.org/sica/index.php/detallemedicacion/save_flutter');
    
    final response = await http.post(url, body: {
      'idmedicacion': idmedicacion,
      'detalle': detalle,
      'fechadesde': fechadesde,
      'fechahasta': fechahasta,
    });

    if (response.statusCode != 200) {
      throw Exception('Error al guardar detalle de medicación');
    }
  }


// Obtener lista de dias cumplidos
  static Future<List<Cumplimiento>> fetchCumplimientos(String idDetalle) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/cumplimientomedicacion/get_cumplimientos_flutter');
    final response = await http.post(url, body: {'iddetallemedicacion': idDetalle});

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      if (decoded['data'] != null) {
        return (decoded['data'] as List).map((e) => Cumplimiento.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception('Error al cargar cumplimientos');
    }
  }

  // Marcar o desmarcar un día
  static Future<void> registrarCumplimiento(String idDetalle, String fecha, int estado) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/cumplimientomedicacion/save_flutter');
    
    await http.post(url, body: {
      'iddetallemedicacion': idDetalle,
      'fecha': fecha,
      'cumplimiento': estado.toString(), // 1 o 0
    });
  }


// MODIFICADO: Ahora recibe idtipomedicacion en lugar de un string libre "tipo"
  static Future<String> registrarMedicacion(String nombre,String fechadesde,String fechahasta,String idpersona, int idtipomedicacion) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/medicacion/save_flutter');
    
    final response = await http.post(url, body: {
      'nombre': nombre,
      'fechadesde': fechadesde,
      'fechahasta': fechahasta,
      'idpersona': idpersona,
      'idtipomedicacion': idtipomedicacion.toString(), // Enviamos 1 o 2
   //   'tipo': idtipomedicacion == 1 ? 'Farmacéutica' : 'Dietética', // Texto compatible
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['status'] == true ? 'OK' : 'Error';
    } else {
      throw Exception('Error al guardar medicación');
    }
  }

  // NUEVO: Función para traer signos vitales
  // Asegúrate de crear el endpoint 'signovital_dataflutter' en tu PHP similar a los otros
  static Future<List<SignoVital>> fetchSignosVitales(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/signovital/signovital_dataflutter');
    
    // Si no tienes este endpoint creado, usa un endpoint genérico SQL si tu backend lo permite, 
    // pero lo ideal es crear el archivo PHP correspondiente.
    final response = await http.post(url, body: {'idpersona': idpersona});

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      
      // Manejo robusto de la respuesta (Lista o Mapa)
      List<dynamic> data = [];
      if (decoded is Map && decoded['data'] != null) {
        data = decoded['data'];
      } else if (decoded is List) {
        data = decoded;
      }

      return data.map((e) => SignoVital.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar signos vitales');
    }
  }


// --- INICIO DE CÓDIGO FALTANTE EN api_service.dart ---

  // 1. Obtener lista de tipos de signos vitales (para el Dropdown)
  static Future<List<Map<String, dynamic>>> fetchTiposSignoVital() async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/signovital/get_tipos_flutter');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      // Asumimos que la respuesta tiene una estructura {"status": true, "data": [...]}
      if (decoded['data'] != null) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
    }
    return [];
  }

  // 2. Guardar un nuevo Signo Vital
  static Future<void> registrarSignoVital(String idpersona, int idtipo, String valor, String fecha) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/signovital/save_flutter');
    
    final response = await http.post(url, body: {
      'idpersona': idpersona,
      'idtiposignovital': idtipo.toString(),
      'valor': valor,
      'fechahora': fecha,
    });

    if (response.statusCode != 200) {
      throw Exception('Error al guardar signo vital');
    }
  }

  // 3. Actualizar un Signo Vital existente
  static Future<void> actualizarSignoVital(String idsignovital, String idpersona, int idtipo, String valor, String fecha) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/signovital/update_flutter');
    
    final response = await http.post(url, body: {
      'idsignovital': idsignovital,
      'idpersona': idpersona,
      'idtiposignovital': idtipo.toString(),
      'valor': valor.toString(),
      'fechahora': fecha,
    });

    if (response.statusCode != 200) {
      throw Exception('Error al actualizar signo vital');
    }
  }

  // 4. Eliminar un Signo Vital
  static Future<void> eliminarSignoVital(String idsignovital) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/signovital/delete_flutter');
    
    final response = await http.post(url, body: {
      'idsignovital': idsignovital
    });

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar signo vital');
    }
  }
  
  // --- FIN DE CÓDIGO FALTANTE ---






















}
