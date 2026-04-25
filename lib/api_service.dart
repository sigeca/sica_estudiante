import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // 🎯 SOLUCIÓN: IMPORTAR ESTO
import 'evento.dart';
import 'portafolio.dart';
import 'tipo_oferta.dart';
import 'package:flutter/foundation.dart';

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
  }  static Future<List<Asignatura>> fetchAsignaturasMalla() async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/asignatura/asignaturas_malla_flutter');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json.containsKey('data')) {
           final List data = json['data'];
           return data.map((e) => Asignatura.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en fetchAsignaturasMalla: $e');
      throw Exception('Error al cargar asignaturas: Verifique su conexión y los datos del servidor.');
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

  static Future<List<ProductoFeed>> fetchTodosLosProductos() async {
    // Nota: El backend en PHP debe responder con un listado completo (feed) de productos,
    // que incluya no solo datos del producto sino también 'tipo', 'subtipo', y datos del vendedor.
    final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/producto/feed1'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => ProductoFeed.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load products feed');
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
  static Future<void> registrarCumplimiento(
      String iddetallemedicacion, 
      DateTime fechaHora, 
      int cumplimiento
      ) async {
        final String fechaHoraString = DateFormat('yyyy-MM-dd HH:mm:ss').format(fechaHora);

    final url = Uri.parse('https://educaysoft.org/sica/index.php/cumplimientomedicacion/save_flutter');
    
    final response= await http.post(url, body: {
      'iddetallemedicacion': iddetallemedicacion,
      'fechahora': fechaHoraString,
      'cumplimiento': cumplimiento.toString(), // 1 o 0
    });
    if(response.statusCode != 200){
        throw Exception('Error al registrar cumplimiento: ${response.body}');
    }

  }



  // 4. Eliminar un Signo Vital
  static Future<void> eliminarCumplimiento(String iddetallemedicacion,DateTime fecha) async {

        final String fechaString = DateFormat('yyyy-MM-dd').format(fecha);
    final url = Uri.parse('https://educaysoft.org/sica/index.php/cumplimientomedicacion/delete_flutter');
    
    final response = await http.post(url, body: {
      'iddetallemedicacion': iddetallemedicacion,
      'fecha' : fechaString,
    });

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar signo vital');
    }
  }
 





// MODIFICADO: Ahora recibe idtipomedicacion en lugar de un string libre "tipo"
static Future<String> registrarMedicacion(
      String nombre, 
      String fechadesde, 
      String fechahasta, 
      String idpersona, 
      int idtipomedicacion, 
      int idestadomedicacion) async {
    
    final url = Uri.parse('https://educaysoft.org/sica/index.php/medicacion/save_flutter');
    final response = await http.post(url, body: {
      'nombre': nombre,
      'fechadesde': fechadesde,
      'fechahasta': fechahasta,
      'idpersona': idpersona,
      'idtipomedicacion': idtipomedicacion.toString(),
      'idestadomedicacion': idestadomedicacion.toString(),
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['status'] == true ? 'OK' : 'Error';
    } else {
      throw Exception('Error al guardar medicación');
    }
  }



// MODIFICADO: Ahora recibe idtipoalimentacion en lugar de un string libre "tipo"
static Future<String> registrarAlimentacion(
      String nombre, 
      String fechadesde, 
      String fechahasta, 
      String idpersona, 
      int idtipoalimentacion, 
      int idestadoalimentacion) async {
    
    final url = Uri.parse('https://educaysoft.org/sica/index.php/alimentacion/save_flutter');
    final response = await http.post(url, body: {
      'nombre': nombre,
      'fechadesde': fechadesde,
      'fechahasta': fechahasta,
      'idpersona': idpersona,
      'idtipoalimentacion': idtipoalimentacion.toString(),
      'idestadoalimentacion': idestadoalimentacion.toString(),
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['status'] == true ? 'OK' : 'Error';
    } else {
      throw Exception('Error al guardar medicación');
    }
  }





// MODIFICADO: Ahora recibe idtipomedicacion en lugar de un string libre "tipo"
static Future<String> registrarEjercitacion(
      String nombre, 
      String fechadesde, 
      String fechahasta, 
      String idpersona, 
      int idtipoejercitacion, 
      int idestadoejercitacion) async {
    
    final url = Uri.parse('https://educaysoft.org/sica/index.php/ejercitacion/save_flutter');
    final response = await http.post(url, body: {
      'nombre': nombre,
      'fechadesde': fechadesde,
      'fechahasta': fechahasta,
      'idpersona': idpersona,
      'idtipoejercitacion': idtipoejercitacion.toString(),
      'idestadoejercitacion': idestadoejercitacion.toString(),
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['status'] == true ? 'OK' : 'Error';
    } else {
      throw Exception('Error al guardar medicación');
    }
  }













// NUEVO: Método para actualizar
  static Future<String> actualizarMedicacion(
      String idmedicacion,
      String nombre,
      int idtipomedicacion,
      int idestadomedicacion) async {

    final url = Uri.parse('https://educaysoft.org/sica/index.php/medicacion/update_flutter');
    final response = await http.post(url, body: {
      'idmedicacion': idmedicacion,
      'nombre': nombre,
      'idtipomedicacion': idtipomedicacion.toString(),
      'idestadomedicacion': idestadomedicacion.toString(),
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['status'] == true ? 'OK' : 'Error';
    } else {
      throw Exception('Error al actualizar medicación');
    }
  }


// NUEVO: Método para actualizar
  static Future<String> actualizarAlimentacion(
      String idalimentacion,
      String nombre,
      int idtipoalimentacion,
      int idestadoalimentacion) async {

    final url = Uri.parse('https://educaysoft.org/sica/index.php/alimentacion/update_flutter');
    final response = await http.post(url, body: {
      'idalimentacion': idalimentacion,
      'nombre': nombre,
      'idtipoalimentacion': idtipoalimentacion.toString(),
      'idestadoalimentacion': idestadoalimentacion.toString(),
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['status'] == true ? 'OK' : 'Error';
    } else {
      throw Exception('Error al actualizar medicación');
    }
  }




// NUEVO: Método para actualizar
  static Future<String> actualizarEjercitacion(
      String idejercitacion,
      String nombre,
      int idtipoejercitacion,
      int idestadoejercitacion) async {

    final url = Uri.parse('https://educaysoft.org/sica/index.php/ejercitacion/update_flutter');
    final response = await http.post(url, body: {
      'idejercitacion': idejercitacion,
      'nombre': nombre,
      'idtipoejercitacion': idtipoejercitacion.toString(),
      'idestadoejercitacion': idestadoejercitacion.toString(),
    });

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['status'] == true ? 'OK' : 'Error';
    } else {
      throw Exception('Error al actualizar medicación');
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


static Future<List<MedicamentoVista>> fetchMedicacion2(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/medicacion/medicamentos_personaflutter');
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

        return data.map((e) => MedicamentoVista.fromJson(e)).toList();

      } catch (e) {
        print("Error parseando JSON: $e");
        // Devolvemos lista vacía en vez de explotar la app, para que el usuario pueda seguir
        return []; 
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }

}





static Future<List<AlimentoVista>> fetchAlimentacion2(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/alimentacion/alimentos_personaflutter');
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

        return data.map((e) => AlimentoVista.fromJson(e)).toList();

      } catch (e) {
        print("Error parseando JSON: $e");
        // Devolvemos lista vacía en vez de explotar la app, para que el usuario pueda seguir
        return []; 
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }

}






static Future<List<EjercicioVista>> fetchEjercitacion2(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/ejercitacion/ejercicios_personaflutter');
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

        return data.map((e) => EjercicioVista.fromJson(e)).toList();

      } catch (e) {
        print("Error parseando JSON: $e");
        // Devolvemos lista vacía en vez de explotar la app, para que el usuario pueda seguir
        return []; 
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }

}








// Dentro de la clase ApiService en lib/api_service.dart

static Future<List<Alimentacion>> fetchAlimentaciones(String idpersona) async {
  // Usamos el nombre exacto de la variable de URL que tengas en tu ApiService (ej. baseUrl o BASE_URL)

    final url = Uri.parse('https://educaysoft.org/sica/index.php/alimentacion/alimentacion_personaflutter');
    final response = await http.post(url, body: {'idpersona': idpersona});

    if (response.statusCode == 200) {
      print("DEBUG SICA: fetchAlimentaciones BODY: ${response.body}"); // 1. Ver qué llega
      try {
        String bodyString = response.body.trim();
        // Buscar el inicio real del JSON para ignorar cualquier Notice o Warning extra de PHP
        int startIndex = bodyString.indexOf(RegExp(r'[\{\[]'));
        int endIndex = bodyString.lastIndexOf(RegExp(r'[\}\]]'));
        
        if (startIndex != -1 && endIndex != -1 && endIndex >= startIndex) {
             bodyString = bodyString.substring(startIndex, endIndex + 1);
        }
        
        final dynamic decoded = json.decode(bodyString);
        print("DEBUG SICA: decoded type: ${decoded.runtimeType}"); // 2. Ver tipo de dato

        List<dynamic> data = [];

        // 1. Verificamos si es un Mapa con clave 'data'
        if (decoded is Map<String, dynamic>) {
           print("DEBUG SICA: Es MAP. Contiene data? ${decoded.containsKey('data')}");
           // AQUÍ EL CAMBIO: Verificamos explícitamente que no sea null
           if (decoded['data'] != null && decoded['data'] is List) {
             data = decoded['data']; 
             print("DEBUG SICA: Data extraída del mapa. Count: ${data.length}");
           } else {
             print("DEBUG SICA: Data es null o no es lista: ${decoded['data']}");
           }
        } 
        // 2. O si es una Lista directa
        else if (decoded is List) {
           print("DEBUG SICA: Es LIST directamente");
           data = decoded;
        } else {
           print("DEBUG SICA: No es ni Map ni List. Es ${decoded.runtimeType}");
        }

        final result = data.map((e) {
          try {
             return Alimentacion.fromJson(e);
          } catch(innerE) {
             print("DEBUG SICA: Error parseando item individual: $innerE\nItem: $e");
             return null; 
          }
        }).whereType<Alimentacion>().toList();
        
        print("DEBUG SICA: Resultado final parseado count: ${result.length}");
        return result;

      } catch (e, stack) {
        print("Error parseando JSON Alimentacion: $e");
        print(stack);
        // Devolvemos lista vacía en vez de explotar la app, para que el usuario pueda seguir
        return []; 
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }
 
 
}


static Future<List<AlimentoVista>> fetchCatalogoAlimentos(String idpersona) async {
  // Cambiar la URL para que apunte al método del controlador PHP
  final response = await http.post(
    Uri.parse('https://educaysoft.org/sica/index.php/alimentacion/alimento_personaflutter'),
    body: {'idpersona': idpersona},
  );

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    final List data = decoded['data']; // El PHP envuelve todo en "data"
    return data.map((e) => AlimentoVista.fromJson(e)).toList();
  } else {
    throw Exception('Error al cargar catálogo');
  }
}




static Future<List<EjercicioVista>> fetchCatalogoEjercicios(String idpersona) async {

final url = Uri.parse('https://educaysoft.org/sica/index.php/ejercitacion/get_ejercicios_flutter?idpersona=$idpersona');
  final response = await http.get(url);

//  final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/ejercitacion/get_catalogo_ejercicios.php'));
  if (response.statusCode == 200) {
    List jsonResponse = json.decode(response.body);
    return jsonResponse.map((data) => EjercicioVista.fromJson(data)).toList();
  } else {
    throw Exception('Error al cargar catálogo');
  }
}


// 2. Corregir Catálogo de Medicamentos (Si no lo tenías)
static Future<List<MedicamentoVista>> fetchCatalogoMedicamentos(String idpersona) async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/medicacion/get_medicamentos_flutter?idpersona=$idpersona');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> jsonResponse = jsonDecode(response.body);
    return jsonResponse.map((data) => MedicamentoVista.fromJson(data)).toList();
  } else {
    throw Exception('Error al cargar medicamentos');
  }
}










//static Future<Map<String, bool>> fetchCumplimientosAlimentacion(String iddetalle) async {
static Future<List<Cumplimiento>> fetchCumplimientosAlimentacion(String iddetalle) async {
//  final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/cumplimientoalimentacion/get_cumplimientos_alim.php?iddetalle=$iddetalle'));

    final url = Uri.parse('https://educaysoft.org/sica/index.php/cumplimientoalimentacion/get_cumplimientos_flutter');
    final response = await http.post(url, body: {'iddetallealimentacion': iddetalle});

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
  static Future<void> registrarCumplimientoAlimentacion(
      String iddetallealimentacion, 
      DateTime fechaHora, 
      int cumplimiento
      ) async {
        final String fechaHoraString = DateFormat('yyyy-MM-dd HH:mm:ss').format(fechaHora);

    final url = Uri.parse('https://educaysoft.org/sica/index.php/cumplimientoalimentacion/save_flutter');
    
    final response= await http.post(url, body: {
      'iddetallealimentacion': iddetallealimentacion,
      'fechahora': fechaHoraString,
      'cumplimiento': cumplimiento.toString(), // 1 o 0
    });
    if(response.statusCode != 200){
        throw Exception('Error al registrar cumplimiento: ${response.body}');
    }

  }









static Future<List<Ejercitacion>> fetchEjercitaciones(String idpersona) async {
  // Usamos el nombre exacto de la variable de URL que tengas en tu ApiService (ej. baseUrl o BASE_URL)

    final url = Uri.parse('https://educaysoft.org/sica/index.php/ejercitacion/ejercitacion_personaflutter');
    final response = await http.post(url, body: {'idpersona': idpersona});

    if (response.statusCode == 200) {
      print("DEBUG SICA: fetchEjercitaciones BODY: ${response.body}"); // 1. Ver qué llega
      try {
        final dynamic decoded = json.decode(response.body);
        print("DEBUG SICA: decoded type: ${decoded.runtimeType}"); // 2. Ver tipo de dato

        List<dynamic> data = [];

        // 1. Verificamos si es un Mapa con clave 'data'
        if (decoded is Map<String, dynamic>) {
           print("DEBUG SICA: Es MAP. Contiene data? ${decoded.containsKey('data')}");
           // AQUÍ EL CAMBIO: Verificamos explícitamente que no sea null
           if (decoded['data'] != null && decoded['data'] is List) {
             data = decoded['data']; 
             print("DEBUG SICA: Data extraída del mapa. Count: ${data.length}");
           } else {
             print("DEBUG SICA: Data es null o no es lista: ${decoded['data']}");
           }
        } 
        // 2. O si es una Lista directa
        else if (decoded is List) {
           print("DEBUG SICA: Es LIST directamente");
           data = decoded;
        } else {
           print("DEBUG SICA: No es ni Map ni List. Es ${decoded.runtimeType}");
        }

        final result = data.map((e) {
          try {
             return Ejercitacion.fromJson(e);
          } catch(innerE) {
             print("DEBUG SICA: Error parseando item individual: $innerE\nItem: $e");
             rethrow; 
          }
        }).toList();
        
        print("DEBUG SICA: Resultado final parseado count: ${result.length}");
        return result;

      } catch (e, stack) {
        print("Error parseando JSON Ejercitacion: $e");
        print(stack);
        // Devolvemos lista vacía en vez de explotar la app, para que el usuario pueda seguir
        return []; 
      }
    } else {
      throw Exception('Error de conexión: ${response.statusCode}');
    }
 
 
}


  // 4. Guardar el detalle (Dosis)
  static Future<void> registrarDetalleEjercitacion(
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



  // Marcar o desmarcar un día
  static Future<void> registrarCumplimientoEjercitacion(
      String iddetalleejercitacion, 
      DateTime fechaHora, 
      int cumplimiento
      ) async {
        final String fechaHoraString = DateFormat('yyyy-MM-dd HH:mm:ss').format(fechaHora);

    final url = Uri.parse('https://educaysoft.org/sica/index.php/cumplimientoejercitacion/save_flutter');
    
    final response= await http.post(url, body: {
      'iddetalleejercitacion': iddetalleejercitacion,
      'fechahora': fechaHoraString,
      'cumplimiento': cumplimiento.toString(), // 1 o 0
    });
    if(response.statusCode != 200){
        throw Exception('Error al registrar cumplimiento: ${response.body}');
    }

  }







//static Future<Map<String, bool>> fetchCumplimientosEjercitacion(String iddetalle) async {
static Future<List<Cumplimiento>> fetchCumplimientosEjercitacion(String iddetalle) async {
  //final response = await http.get(Uri.parse('https://educaysoft.org/sica/index.php/cumplimientoejercitacion/get_cumplimientos_flutter?iddetalle=$iddetalle'));
    final url = Uri.parse('https://educaysoft.org/sica/index.php/cumplimientoejercitacion/get_cumplimientos_flutter');
    final response = await http.post(url, body: {'iddetalleejercitacion': iddetalle});

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



static Future<bool> eliminarProductoCarrito(String idcarrito, int idproducto) async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/carritoproducto/eliminar_carrito'); // Cambia por tu URL real
  try {
    final response = await http.post(url, body: {
      'idcarrito': idcarrito,
      'idproducto': idproducto.toString(),
    });
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}

static Future<bool> devolverProductoCarritoFlutter(String idcarritoproducto) async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/carritoproducto/descargar_flutter');
  try {
    final response = await http.post(url, body: {
      'idcarritoproducto': idcarritoproducto,
    });
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}


static Future<bool> procesarPagoCarrito(String idpersona, List<Map<String, dynamic>> items) async {
  final url = Uri.parse('https://educaysoft.org/tu_endpoint_pago.php'); 
  try {
    final response = await http.post(url, body: {
      'idpersona': idpersona,
      'productos': jsonEncode(items),
    });
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}



static Future<bool> addProductoCarrito({
  required String idpersona,
  required int idproducto,
  required int cantidad,
  required double precio,
}) async {
  final url = Uri.parse('https://educaysoft.org/sica/index.php/carritoproducto/save_flutter');
  
  try {
    final response = await http.post(url, body: {
      'idpersona': idpersona,
      'idproducto': idproducto.toString(),
      'cantidad': cantidad.toString(),
      'precio': precio.toString(),
    });

print("RESPUESTA BRUTA DEL SERVIDOR: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return decoded['status'] == true;
    }
    return false;
  } catch (e) {
    print("Error en añadirProductoCarrito: $e");
    return false;
  }
}








  static Future<bool> esCliente(String cedula) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/cliente/cliente_cedula_flutter');
    try {
      final response = await http.post(url, body: {
        'cedula': cedula,
      });

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // Verificación robusta: status=true o existencia de datos
        if (decoded is Map) {
          if (decoded['status'] == true) return true;
          
          if (decoded.containsKey('data')) {
            final data = decoded['data'];
            if (data == null) return false;
            if (data is Map) return true; // Si es un mapa, se encontró un registro
            if (data is List) return data.isNotEmpty;
          }
        }
        
        if (decoded is List) {
          return decoded.isNotEmpty;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error verificando cliente: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> fetchFacturaInitialData(String idpersona) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/factura/get_initial_data_flutter/$idpersona');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': false, 'message': 'Servidor retornó error ${response.statusCode}'};
    } catch (e) {
      return {'status': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> saveFactura(String idpersona, Factura header, List<DetalleFactura> detalles) async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/factura/save_flutter');
    try {
      final body = json.encode({
        'idpersona': idpersona,
        'header': header.toJson(),
        'detalles': detalles.map((d) => d.toJson()).toList(),
      });
      final response = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'status': false, 'message': 'Error ${response.statusCode}'};
    } catch (e) {
      return {'status': false, 'message': e.toString()};
    }
  }

  static String getFacturaPdfUrl(String idfactura) {
    return 'https://educaysoft.org/sica/index.php/factura/reportepdf_flutter/$idfactura';
  }

  static Future<List<TipoOferta>> fetchTipoOferta() async {
    final url = Uri.parse('https://educaysoft.org/sica/index.php/tipooferta/tipooferta_flutter');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json.containsKey('data')) {
           final List data = json['data'];
           return data.map((e) => TipoOferta.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en fetchTipoOferta: $e');
      throw Exception('Error al cargar tipos de oferta.');
    }
  }

}
