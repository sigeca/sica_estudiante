import 'package:flutter/material.dart';
import 'api_service.dart'; // Asegúrate de tener este import si usas la API
import 'evento.dart'; // O donde tengas la clase SesionEvento
import 'package:flutter_math_fork/flutter_math.dart'; // Asegúrate de tener este paquete
import 'ParticipacionScreen.dart';
import 'PagoeventoScreen.dart';
import 'PagoeventoPeople.dart';
import 'AsistenciaScreen.dart';
import 'SesionItem.dart'; // <--- Agrega esta línea


class EventoDetalleScreen extends StatefulWidget {
  final String idevento;
  final String titulo;
  final String idpersona;
  final String idtipogrupoparticipante;
  const EventoDetalleScreen({super.key, required this.idevento,required this.titulo,required this.idtipogrupoparticipante, required this.idpersona});

  @override
  State<EventoDetalleScreen> createState() => _EventoDetalleScreenState();
}

class _EventoDetalleScreenState extends State<EventoDetalleScreen> {
  // Ajuste de índices:
  // 0: Contenido (Syllabus)
  // 1: Participante (Docente) / Asistencia (Estudiante)
  // 2: Tomar Asistencia (Docente) / Participación (Estudiante)
  // 3: Nota
  // 4: Pago
  int _selectedIndex = 0;
  // int numerosesion=0; // No necesario como campo de estado, se calcula en _buildContenido

  late Future<List<SesionEvento>> _contenidoFuture;
  late Future<List<Asistencia>> _asistenciaFuture;
  late Future<List<Participante>> _participanteFuture;
  late Future<List<Participacion>> _participacionFuture;
  late Future<List<Nota>> _notaFuture;
  late Future<List<Pago>> _pagoFuture;
// NUEVO: Future para obtener foto y nombre en esta pantalla
  late Future<Persona> _personaInfoFuture;


  final TextEditingController _searchController = TextEditingController();
  List<Participante> _allParticipantes = [];
  List<Participante> _filteredParticipantes = [];
  String _searchQuery = '';

  // Variable para determinar si el usuario es docente ('6')
  bool get isDocente => widget.idtipogrupoparticipante == '6';

  @override
  void initState() {
    super.initState();
    _contenidoFuture = ApiService.fetchSesiones(widget.idevento);
    _participanteFuture = ApiService.fetchParticipantes(widget.idevento);
    _asistenciaFuture = ApiService.fetchAsistencias(widget.idevento,widget.idpersona);
    _participacionFuture = ApiService.fetchParticipaciones(widget.idevento,widget.idpersona);
// NUEVO: Inicializar información de persona
    _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona);

    _notaFuture = ApiService.fetchNotas(widget.idevento,widget.idpersona);
    _pagoFuture = ApiService.fetchPagos(widget.idevento,widget.idpersona);
   _searchController.addListener(_onSearchChanged);

// Cargar los datos iniciales y configurar las listas
    _participanteFuture.then((participantes) {
      if (mounted) { // Asegurarse de que el widget todavía está en el árbol
        setState(() {
          _allParticipantes = participantes;
          _filteredParticipantes = participantes;
        });
      }
    });


  }


@override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text == _searchQuery) return; // Evitar reconstrucciones innecesarias

    setState(() {
      _searchQuery = _searchController.text;
      if (_searchQuery.isEmpty) {
        _filteredParticipantes = _allParticipantes;
      } else {
        _filteredParticipantes = _allParticipantes.where((participante) {
          final nombreLower = participante.nombres.toLowerCase();
          final queryLower = _searchQuery.toLowerCase();
          final grupoletraLower = participante.grupoletra.toLowerCase(); // Opcional: buscar por cédula también
          return nombreLower.contains(queryLower) || grupoletraLower.contains(queryLower);
        }).toList();
      }
    });
  }








  List<Widget> _buildPages() {
    return [
      _buildContenido(),
       isDocente ? _buildParticipante() : _buildAsistencia(),
       isDocente ? _buildTomarAsistencia() : _buildParticipacion(),
      _buildNota(),
      _buildPago(),
    ];
  }



Widget _buildParticipante() {
  return FutureBuilder<List<Participante>>(
    future: _participanteFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting && _allParticipantes.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError && _allParticipantes.isEmpty) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (_allParticipantes.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
        return const Center(child: Text('No hay participantes para mostrar.'));
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Participantes del evento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o cédula...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: _filteredParticipantes.isEmpty && _searchQuery.isNotEmpty
                  ? Center(child: Text('No se encontraron participantes para "$_searchQuery"'))
                  : ListView.builder(
                      itemCount: _filteredParticipantes.length,
                      itemBuilder: (context, index) {
                        final participante = _filteredParticipantes[index];
                        final imageUrl =
                            'https://educaysoft.org/descargar2.php?archivo=${participante.cedula}.jpg';

                        Color tarjetaColor = Colors.grey.shade300;
                        final textColor = Colors.black;

                        return Card(
                          color: tarjetaColor,
                          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey.shade400,
                              backgroundImage: NetworkImage(imageUrl),
                              onBackgroundImageError: (exception, stackTrace) {
                                print('Error al cargar imagen: $exception para cédula ${participante.cedula}');
                              },
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ID: ${participante.idpersona}',
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.note_alt_outlined),
                                      tooltip: 'Notas y participaciones',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NotasPage(idpersona: participante.idpersona, idevento: participante.idevento),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.check_circle_outline),
                                      tooltip: 'Asistencias',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            //builder: (context) => AsistenciaPage(title: 'Asistencias'),
                                            builder: (context) => AsistenciaPage(idpersona: participante.idpersona, idevento: participante.idevento ),
                                          ),
                                        );
                                      },
                                    ),
                                     IconButton(
                                      icon: Icon(Icons.monetization_on, color: Colors.blueAccent),
                                      tooltip: 'Asistencias',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PagoeventoPeople(idpersona: participante.idpersona, idevento: participante.idevento ),
                                          ),
                                        );
                                      },
                                    ),
                                    



                                  ],
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  participante.nombres,
                                  style: TextStyle(color: textColor),
                                ),
                                Text(
                                  'Grupo: ${participante.grupoletra}',
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }
    },
  );
}




@override                                                                   
  Widget _buildTomarAsistencia() {
    return MaterialApp(
      title: 'tomar de Asistencia',
      home: const TomaasistenciaPage(),
    );  
  }


// New Function to calculate attendance stats
  Map<String, dynamic> _calculateAttendanceStats(List<Asistencia> asistencias) {
    int puntual = 0;
    int atrasado = 0;
    int justificada = 0;
    int injustificada = 0;
    double weightedScore = 0.0;
    double totalWeight = 0.0;

    for (var asistencia in asistencias) {
      final tipo = int.tryParse(asistencia.idtipoasistencia ?? '0') ?? 0;
      switch (tipo) {
        case 1:
          puntual++;
          weightedScore += 1.0;
          break;
        case 2:
          atrasado++;
          weightedScore += 0.75;
          break;
        case 3:
          justificada++;
          weightedScore += 0.5;
          break;
        case 4:
          injustificada++;
          weightedScore += 0.0; // Injustificada tiene un valor de 0
          break;
      }
    }
    totalWeight = asistencias.length > 0 ? weightedScore / asistencias.length : 0.0;
    final porcentaje = totalWeight * 100;

    return {
      'puntual': puntual,
      'atrasado': atrasado,
      'justificada': justificada,
      'injustificada': injustificada,
      'porcentaje': porcentaje.toStringAsFixed(2),
      'total': asistencias.length,
    };
  }

Widget _buildAsistencia() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Registro de asistencia',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Asistencia>>(
          future: _asistenciaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final asistencias = snapshot.data!;
              return ListView.builder(
                itemCount: asistencias.length,
                itemBuilder: (context, index) {
                  final asistencia = asistencias[index];
                  final tipo = int.tryParse(asistencia.idtipoasistencia ?? '0') ?? 0;

                  Color tarjetaColor;
                  IconData leadingIcon; // Variable para el icono
                  switch (tipo) {
                    case 1: // Puntual
                      tarjetaColor = Colors.green;
                      leadingIcon = Icons.check_circle_outline; // Icono de asistencia puntual
                      break;
                    case 2: // Atrasado
                      tarjetaColor = Colors.yellow;
                      leadingIcon = Icons.timer_off_outlined; // Icono de llegada tarde
                      break;
                    case 3: // Falta Justificada
                      tarjetaColor = Colors.orange;
                      leadingIcon = Icons.report_problem_outlined; // Icono de falta justificada
                      break;
                    case 4: // Falta Injustificada
                      tarjetaColor = Colors.red;
                      leadingIcon = Icons.cancel_outlined; // Icono de falta injustificada
                      break;
                    default:
                      tarjetaColor = Colors.grey.shade300;
                      leadingIcon = Icons.question_mark_outlined; // Icono por defecto
                  }

                  // Color del texto si fondo es muy claro (amarillo)
                  final textColor = (tarjetaColor == Colors.yellow) ? Colors.black : Colors.white;

                  return Card(
                    color: tarjetaColor,
                    child: ListTile(
                      leading: Icon(leadingIcon, color: textColor), // Usando el icono dinámico
                      title: Text(
                        'Fecha: ${asistencia.fecha}',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        'Tipo de Asistencia: ${asistencia.tipoasistencia}',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      // Nuevo widget para el footer de estadísticas
      _buildAttendanceSummary(),
    ],
  );
}


  Widget _buildAttendanceSummary() {
    return FutureBuilder<List<Asistencia>>(
      future: _asistenciaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // No mostrar nada si no hay datos
        } else {
          final asistencias = snapshot.data!;
          final stats = _calculateAttendanceStats(asistencias);
          final int total = stats['total'];
          final String porcentaje = stats['porcentaje'];

          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 2.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de Asistencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatChip(context, 'Puntual', stats['puntual'], Colors.green),
                    _buildStatChip(context, 'Atrasado', stats['atrasado'], Colors.yellow),
                    _buildStatChip(context, 'Justif.', stats['justificada'], Colors.orange),
                    _buildStatChip(context, 'Injust.', stats['injustificada'], Colors.red),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Puntuación total de asistencia:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      Text(
                        '$porcentaje%',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildStatChip(BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        Chip(
          label: Text(
            '$count',
            style: TextStyle(color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
          ),
          backgroundColor: color,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }


// WIDGET MEJORADO PARA CONTENIDO
Widget _buildContenido() {
  return FutureBuilder<List<SesionEvento>>(
    future: _contenidoFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else {
        final sesiones = snapshot.data!;
        if (sesiones.isEmpty) {
          return const Center(child: Text('No hay sesiones para mostrar.'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.blue,
              width: double.infinity,
              child: Text(
                widget.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sesiones.length,
                itemBuilder: (context, index) {
                  // Aquí usamos el nuevo widget SesionItem
                  return SesionItem(
                    sesion: sesiones[index],
                    isDocente: isDocente,
                  );
                },
              ),
            ),
          ],
        );
      }
    },
  );
}



Widget _buildParticipacion() {
// Simulación de datos para la demostración
   return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8.0),
        color: Colors.blue, // Puedes cambiar este color
        child: const Text(
          'Participación en el aula',
          style: TextStyle(
            color: Colors.white, // Puedes cambiar este color
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Participacion>>(
          future: _participacionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final participaciones = snapshot.data!;
              return ListView.builder(
                itemCount: participaciones.length,
                itemBuilder: (context, index) {
                  final participacion = participaciones[index];
                  final porcentaje = double.tryParse(participacion.porcentaje ?? '0') ?? 0.0;
                  final isNegativo = porcentaje < 0;
                  final backgroundColor = isNegativo ? Colors.red.shade200 : Colors.green.shade200;
                  final textColor = Colors.black87;

                  return Card(
                    color: backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(
                            isNegativo ? Icons.sentiment_very_dissatisfied : Icons.sentiment_very_satisfied,
                            color: textColor,
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Fecha: ${participacion.fecha}', style: TextStyle(color: textColor)),
                                Text('Comentario: ${participacion.comentario}', style: TextStyle(color: textColor)),
                                Text('Porcentaje de participación: ${participacion.porcentaje}%', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                              ],
                            ),



                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    ],
  );

}

// Method to calculate the sum of percentages
  List<double> _calculateTotalPercentage(List<Nota> notas) {
    double p11 = 0.0;
    double p12 = 0.0;
    double p21 = 0.0;
    double p22 = 0.0;
    double t1 = 0.0;
    double t2 = 0.0;
    double p1 = 0.0;
    double a1 = 0.0;
    double b1 = 0.0;
    double c1 = 0.0;
    double e1 = 0.0;
    double a2 = 0.0;
    double b2 = 0.0;
    double c2 = 0.0;
    double e2 = 0.0;
    double pa=0.03;
    double pb=0.015;
    double pc=0.015;
    double pe=0.04;
    for (var nota in notas) {

              switch (nota.idmodoevaluacion) {
                case  '2': // Puntual
                 a1 += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                  break;
                case '3': // Atrasado
                 b1 += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                  break;
                case '4': // Falta Justificada
                 c1 += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                  break;
                case '5': // Evaluado
                 e1 += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                  break;

                case '6': // Puntual
                 a2 += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                  break;
                case '7': // Atrasado
                 b2 += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                  break;
                case '8': // Falta Justificada
                 c2 += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                  break;
                case '9': // Evaluado
                 e2 += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                  break;
                default:
            }
    }
      p11 = ((a1/2)+(b1/2)+(c1/2)+e1)/4;
      p12 = (a1/2)*pa+(b1/2)*pb+(c1/2)*pc+e1*pe;
      p21 = ((a2/2)+(b2/2)+(c2/2)+e2)/4;
      p22 = (a2/2)*pa+(b2/2)*pb+(c2/2)*pc+e2*pe;
      t1 =(p11+p21)/2;
      t2 =(p12+p22)/2;
    return [t1,t2,p11,p12,p21,p22];
  }


// Method to show the bottom sheet with the total percentage
  void _showTotalPercentagePanel(BuildContext context, List<double> percentages ) {
      // Access p1, p2, and total from the list
  final double total = percentages[0];
  final double p1 = percentages[1];
  final double p2 = percentages[2];
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          height: 200, // You can adjust the height as needed
          padding: const EdgeInsets.all(20.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Sumatoria Total de Porcentajes:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
               Text(
              'Primer parcial: ${p1.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              'Segundo parcial: ${p2.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Sumatoria Final: ${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: total < 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

   Widget getIcon(nota,isNegativo) {


  switch (nota.idmodoevaluacion) {
    case '1':
      return Icon(
        isNegativo ? Icons.sentiment_very_dissatisfied : Icons.sentiment_very_satisfied,
      );
    case '2':
      return Icon(
        Icons.hearing,
      );
    case '3':
      return Icon(
        Icons.biotech,
      );
    case '4':
      return Icon(
        Icons.psychology,

      );
    case '5':
      return Icon(
        Icons.assignment_turned_in,
      );
    case '6':
      return Icon(
        Icons.hearing,
      );
    case '7':
      return Icon(
        Icons.biotech,
      );
    case '8':
      return Icon(
        Icons.psychology,
      );
    case '9':
      return Icon(
        Icons.assignment_turned_in,
      );
    default:
      return SizedBox.shrink(); // widget vacío en caso de no coincidir
  }
}







@override
@override
  Widget _buildNota() {
    final String latexFormula = r'P_x = \sum_{y=1}^{2}(A_x)_y \cdot p_a + \sum_{y=1}^{2}(B_x)_y \cdot p_b + \sum_{y=1}^{2}(C_x)_y \cdot p_c + \sum_{y=1}^{2}(E_x)_y \cdot p_e ';

    return Scaffold(
      // 1. ELIMINAR TÍTULO (Solo queda el botón de atrás y color)
        body: Column(
        children: [
          // SECCIÓN DE FOTO DE PERFIL (Mantenemos tu diseño anterior)
          FutureBuilder<Persona>(
            future: _personaInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final persona = snapshot.data!;
                final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${persona.cedula}.jpg";
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: NetworkImage(fotoUrl),
                        onBackgroundImageError: (_, __) => const Icon(Icons.person),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              persona.lapersona,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                            const Text("Estudiante", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // SECCIÓN DE NOTAS Y RESÚMENES
          Expanded(
            child: FutureBuilder<List<Nota>>(
              future: _notaFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay calificaciones.'));
                }

                final notas = snapshot.data!;
                
                // --- LÓGICA DE GENERACIÓN DE TARJETAS ---
                List<Widget> gridWidgets = [];
                
                // Calcular la Nota Final acumulada para la barra inferior
                double notaFinalAcumulada1 = 0;
                double notaFinalAcumulada2 = 0;


                 final List<double> calculatedPercentages = _calculateTotalPercentage(notas);
                 notaFinalAcumulada1=calculatedPercentages[0];
                 notaFinalAcumulada2=calculatedPercentages[1];


                for (var nota in notas) {
                  // 1. Crear Tarjeta Normal
                  gridWidgets.add(_buildStandardCard(nota));

                  // Calcular valor para la suma final
               //   double val = (double.tryParse(nota.porcentaje ?? '0') ?? 0.0) * (double.tryParse(nota.ponderacion ?? '0') ?? 0.0);
               //   notaFinalAcumulada += val;

                  // 2. Verificar si toca insertar Tarjeta de Resumen
                  // Insertar después de E1
                  if (nota.modoevaluacion == "E1") {
                    gridWidgets.add(_buildResumenCard("Primer Parcial", notas, "1"));
                  }
                  // Insertar después de E2
                  if (nota.modoevaluacion == "E2") {
                    gridWidgets.add(_buildResumenCard("Segundo Parcial", notas, "2"));
                  }
                }

                return Column(
                  children: [
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        padding: const EdgeInsets.all(8.0),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                        children: gridWidgets,
                      ),
                    ),
                    
                    // 3. BARRA DE SUMATORIA FINAL (Nueva franja inferior)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, -2))]
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "NOTA FINAL ACUMULADA:",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),

            // Centro: Promedio % | Raya | Total Ponderación
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Columna Promedio
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        notaFinalAcumulada1.toStringAsFixed(0) + "%", // Sin decimales el %
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ],
                  ),

                  // Raya Vertical Central
                  Container(width: 1, height: 40, color: Colors.indigo.withOpacity(0.3)),

                  // Columna Sumatoria
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        notaFinalAcumulada2.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ],
                  ),
                ],
              ),
            ),









                       ],
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
      
      // BARRA DE FÓRMULA (Mantenida al final)
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade50,
        height: 60,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
               const Text('Fórmula: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
               Expanded(
                 child: SingleChildScrollView(
                   scrollDirection: Axis.horizontal,
                   child: Math.tex(latexFormula, textStyle: const TextStyle(fontSize: 10)),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR 1: Tarjeta de Nota Normal (Con tu diseño previo) ---
  Widget _buildStandardCard(Nota nota) {
    final porcentaje = double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
    final isNegativo = porcentaje < 0;
    
    // Color según ID (Simplificado para el ejemplo)
    Color cardColor = isNegativo ? Colors.orange : Colors.white;
    int idModo = int.tryParse(nota.idmodoevaluacion ?? '0') ?? 0;
    if (!isNegativo) {
       switch (idModo) {
          case 1: cardColor = Colors.blue[100]!; break;
          case 2: cardColor = Colors.green[100]!; break;
          case 3: cardColor = Colors.yellow[100]!; break;
          case 4: cardColor = Colors.red[100]!; break;
          case 5: cardColor = Colors.blue[100]!; break;
          case 6: cardColor = Colors.green[100]!; break;
          case 7: cardColor = Colors.yellow[100]!; break;
          case 8: cardColor = Colors.red[100]!; break;
          case 9: cardColor = Colors.blue[100]!; break;
          default: cardColor = Colors.grey[200]!;
       }
    }
    final textColor = isNegativo ? Colors.white : Colors.black87;

    return Card(
      color: cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cabecera: Icono | Raya | Modo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.4), shape: BoxShape.circle),
                  child: getIcon(nota, isNegativo),
                ),
                Container(
                  height: 25, width: 1.5,
                  color: Colors.black26, margin: const EdgeInsets.symmetric(horizontal: 6),
                ),
                Expanded(
                  child: Text(
                    nota.modoevaluacion,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            Text(nota.fecha, style: TextStyle(fontSize: 9, color: textColor.withOpacity(0.7))),
            const Divider(height: 6),
           
            // Centro: Promedio % | Raya | Total Ponderación
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Columna Promedio
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Rendi. %", style: TextStyle(fontSize: 9, color: Colors.grey)),
                      Text(
                        nota.porcentaje + "%", // Sin decimales el %
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ],
                  ),

                  // Raya Vertical Central
                  Container(width: 1, height: 40, color: Colors.indigo.withOpacity(0.3)),

                  // Columna Sumatoria
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Ptos", style: TextStyle(fontSize: 9, color: Colors.grey)),
                      Text(
                        ((double.tryParse(nota.porcentaje ?? '0') ?? 0.0) * (double.tryParse(nota.ponderacion ?? '0') ?? 0.0)).toStringAsFixed(2),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ],
                  ),
                ],
              ),
            ),




            // Comentario
             Text(
                nota.comentario.isNotEmpty ? nota.comentario : "-",
                style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: textColor),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR 2: Tarjeta de Resumen (NUEVO REQUERIMIENTO) ---
  Widget _buildResumenCard(String titulo, List<Nota> todasLasNotas, String filtroParcial) {
    // 1. Filtrar las notas que pertenecen a este parcial (contienen "1" o "2" en su modo)
    // Ejemplo: "A1", "B1" contienen "1".
//    final notasParcial = todasLasNotas.where((n) => n.modoevaluacion.contains(filtroParcial)).toList();



    double sumaPonderacion = 0;
    double sumaPorcentajes = 0;
    double promedioPorcentaje=0;
    final List<double> calculatedPercentages = _calculateTotalPercentage(todasLasNotas);



// 2. Asignar dentro (sin escribir 'double' de nuevo)
if (filtroParcial == "1") {
   // Asumimos que calculatedPercentages es una lista válida
   // Nota: Verifica si el índice es 0 o 1 dependiendo de cómo llenaste la lista
   promedioPorcentaje = calculatedPercentages[2]; // Usualmente el primero es índice 0
   sumaPonderacion = calculatedPercentages[3]; // Usualmente el primero es índice 0
} else if (filtroParcial == "2") {
   promedioPorcentaje = calculatedPercentages[4];
   sumaPonderacion = calculatedPercentages[5]; // Usualmente el primero es índice 0
}



//    for (var n in notasParcial) {
//      double p = double.tryParse(n.porcentaje ?? '0') ?? 0.0;
//      double w = double.tryParse(n.ponderacion ?? '0') ?? 0.0;
//      sumaPorcentajes += p;
 //     sumaPonderacion += (p * w);
 //   }

//    double promedioPorcentaje = notasParcial.isNotEmpty ? sumaPorcentajes / notasParcial.length : 0.0;

    return Card(
      color: Colors.indigo.shade50, // Color distintivo
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.indigo.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título Superior
            Text(
              titulo.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
              textAlign: TextAlign.center,
            ),
            const Divider(color: Colors.indigoAccent),
            
            // Centro: Promedio % | Raya | Total Ponderación
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Columna Promedio
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Prom. %", style: TextStyle(fontSize: 9, color: Colors.grey)),
                      Text(
                        promedioPorcentaje.toStringAsFixed(0) + "%", // Sin decimales el %
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ],
                  ),

                  // Raya Vertical Central
                  Container(width: 1, height: 40, color: Colors.indigo.withOpacity(0.3)),

                  // Columna Sumatoria
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Total Ptos", style: TextStyle(fontSize: 9, color: Colors.grey)),
                      Text(
                        sumaPonderacion.toStringAsFixed(2),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                    ],
                  ),
                ],
              ),
            )


          ],
        ),
      ),
    );
  }







    Widget _buildPago() {
    return Column( // 1. Widget principal como Columna para agregar el título
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Financiamiento de actividades", // Título agregado
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded( // Para que el ListView ocupe el espacio restante
          child: FutureBuilder<List<Pago>>(
            future: _pagoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay financiamientos para mostrar.'));
              } else {
                final pagoes = snapshot.data!;
                return ListView.builder(
                  itemCount: pagoes.length,
                  itemBuilder: (context, index) {
                    final pago = pagoes[index];
                    final valor = double.tryParse(pago.valor ?? '0') ?? 0.0;
                    final isNegativo = valor < 0;
                    final textColor = isNegativo ? Colors.white : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      color: isNegativo ? Colors.orangeAccent : Theme.of(context).cardColor,
                      elevation: 3,
                      child: ListTile(
                        leading: Icon( // 4. Icono de manos estrechándose
                          Icons.favorite,
                          color: Colors.red,
                          size: 40,
                        ),
                        title: Text(
                          'Fecha: ${pago.fecha}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column( // Para mostrar la información en múltiples líneas
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Motivo: ${pago.comentario}',
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4), // Pequeño espacio
                            Text( // 2. Campo pago.valor en otra línea con etiqueta
                              'Contribución: ${pago.valor}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500, // Un poco más de énfasis
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }






  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Definir los ítems del BottomNavigationBar una vez
    // Indices: 0: Syllabus, 1: P/A, 2: A/P, 3: Notas, 4: Pagos
    final navItems = [
         const BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Syllabus'),
          BottomNavigationBarItem(
            icon: isDocente ? const Icon(Icons.people) : const Icon(Icons.check_circle_outline),
            label: isDocente ? 'Participante' : 'Asiste',
          ),
        BottomNavigationBarItem(
          icon: isDocente ? const Icon(Icons.check_circle_outline) : const Icon(Icons.note_alt_outlined),
          label: isDocente ? 'Asiste' : 'Participa',
        ),
          const BottomNavigationBarItem(icon: Icon(Icons.rate_review), label: 'Notas'),
          const BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Pagos')
    ];


    return Scaffold(
      appBar: AppBar(title: const Text('Sesiones del Evento')),
      body: _buildPages()[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // o cualquier color visible
        unselectedItemColor: Colors.grey, // para los ítems no seleccionados
        backgroundColor: Colors.white, // o el que estés usando de fondo
        type: BottomNavigationBarType.fixed, // Usar tipo fijo para 5 ítems

        items: navItems,
      ),
    );
  }
}



class NotasPage extends StatefulWidget {
  final String idpersona;
  final String idevento;

  NotasPage({Key? key, required this.idpersona, required this.idevento}) : super(key: key);

  @override
  _NotasPageState createState() => _NotasPageState();
}




// Debes crear esta página o una similar para la navegación
class _NotasPageState extends State<NotasPage> {
  late Future<List<Nota>> _notapFuture;
  late Future<Persona> _personaInfoFuture; // Added for person info

  @override
  void initState() {
       super.initState();
    _notapFuture = ApiService.fetchNotasAll(widget.idevento,widget.idpersona);
    _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona); // Initialize person info fetch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CAlificaciones"),
      ),
      body: Center(
        child: _buildNota(), 
      ),
    );
  }

// Reusing the _buildPersonaInfo method from EventoPage
  Widget _buildPersonaInfo(Persona persona) {
    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${persona.cedula}.jpg";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        children: [
          ClipOval(
            child: Image.network(
              fotoUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            persona.lapersona,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19, // Tamaño adecuado para un nombre
              fontWeight: FontWeight.bold, // Letras resaltadas
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, // Color del texto
              shadows: [ // Efecto repujado/sombra sutil
                Shadow(
                  offset: Offset(1.5, 1.5),
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




   Widget getIcon(nota,isNegativo) {


  switch (nota.idmodoevaluacion) {
    case '1':
      return Icon(
        isNegativo ? Icons.sentiment_very_dissatisfied : Icons.sentiment_very_satisfied,
      );
    case '2':
      return Icon(
        Icons.hearing,
      );
    case '3':
      return Icon(
        Icons.biotech,
      );
    case '4':
      return Icon(
        Icons.psychology,

      );
    case '5':
      return Icon(
        Icons.assignment_turned_in,
      );
    case '6':
      return Icon(
        Icons.hearing,
      );
    case '7':
      return Icon(
        Icons.biotech,
      );
    case '8':
      return Icon(
        Icons.psychology,
      );
    case '9':
      return Icon(
        Icons.assignment_turned_in,
      );
    default:
      return SizedBox.shrink(); // widget vacío en caso de no coincidir
  }
}






Widget _buildNota() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Text(
            'Calificación de Actividades de aprendizaje',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),

      // Información de la persona
      FutureBuilder<Persona>(
        future: _personaInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            print("Error FutureBuilder Persona (PortafolioPage): ${snapshot.error}");
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No se pudo cargar la información del usuario.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return _buildPersonaInfo(snapshot.data!);
          } else {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay información del usuario disponible.')),
            );
          }
        },
      ),

      // Lista de notas
  Expanded(
  child: FutureBuilder<List<Nota>>(
    future: _notapFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else {
        final notaes = snapshot.data!;
        return ListView.builder(
          itemCount: notaes.length,
          itemBuilder: (context, index) {
            final nota = notaes[index];
            final porcentaje = double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
            final isNegativo = porcentaje < 0;

            // Función para obtener el color basado en el idmodoevaluacion
            Color? getColorForId(int id) {
              switch (id) {
                case 1:
                  return Colors.blue[100];
                case 2:
                  return Colors.green[100];
                case 3:
                  return Colors.yellow[100];
                case 4:
                  return Colors.red[100];
                case 5:
                  return Colors.purple[100];
                case 6:
                  return Colors.orange[100];
                case 7:
                  return Colors.pink[100];
                case 8:
                  return Colors.teal[100];
                case 9:
                  return Colors.cyan[100];
                default:
                  return null; // Color por defecto si no coincide
              }
            }

            final cardColor = isNegativo
                ? Colors.orange
                : getColorForId(int.tryParse(nota.idmodoevaluacion ?? '0') ?? 0);

            return Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16.0),

                child: Row(
                children: [


getIcon(nota,isNegativo),

          const SizedBox(width: 12.0),

               Expanded(
               

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fecha: ${nota.fecha}',
                      style: TextStyle(color: isNegativo ? Colors.white : null),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modo de evaluación: ${nota.modoevaluacion}',
                      style: TextStyle(color: isNegativo ? Colors.white : null),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rendimiento: ${nota.porcentaje}%',
                      style: TextStyle(color: isNegativo ? Colors.white : null),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comentario: ${nota.comentario}',
                      style: TextStyle(color: isNegativo ? Colors.white : null),
                    ),
                  ],
                ),
                ),

                  ],

                ),



              ),
            );



          },
        );
      }
    },
  ),
),

    ],
  );
}



}

// Debes crear esta página o una similar para la navegación
class AsistenciaPage extends StatefulWidget {
  final String idpersona;
  final String idevento;
  const AsistenciaPage({Key? key, required this.idpersona, required this.idevento}) : super(key: key);

 @override
  _AsistenciaPageState createState() => _AsistenciaPageState();
}







class _AsistenciaPageState extends State<AsistenciaPage>{
  late Future<List<Asistencia>> _asistenciaFuture;
  late Future<Persona> _personaInfoFuture; // Added for person info

 @override
  void initState() {
       super.initState();
    _asistenciaFuture = ApiService.fetchAsistencias(widget.idevento,widget.idpersona);

    _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona); // Initialize person info fetch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Asistencia"),
      ),
      body: Center(
        child: _buildAsistencia(),
      ),
    );
  }

// Reusing the _buildPersonaInfo method from EventoPage
  Widget _buildPersonaInfo(Persona persona) {
    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${persona.cedula}.jpg";
    //final fotoUrl = "https://repositorioutlvte.org/Repositorio/fotos/${persona.cedula}.jpg";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        children: [
          ClipOval(
            child: Image.network(
              fotoUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            persona.lapersona,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19, // Tamaño adecuado para un nombre
              fontWeight: FontWeight.bold, // Letras resaltadas
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, // Color del texto
              shadows: [ // Efecto repujado/sombra sutil
                Shadow(
                  offset: Offset(1.5, 1.5),
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// New Function to calculate attendance stats
  Map<String, dynamic> _calculateAttendanceStats(List<Asistencia> asistencias) {
    int puntual = 0;
    int atrasado = 0;
    int justificada = 0;
    int injustificada = 0;
    double weightedScore = 0.0;
    double totalWeight = 0.0;

    for (var asistencia in asistencias) {
      final tipo = int.tryParse(asistencia.idtipoasistencia ?? '0') ?? 0;
      switch (tipo) {
        case 1:
          puntual++;
          weightedScore += 1.0;
          break;
        case 2:
          atrasado++;
          weightedScore += 0.75;
          break;
        case 3:
          justificada++;
          weightedScore += 0.5;
          break;
        case 4:
          injustificada++;
          weightedScore += 0.0; // Injustificada tiene un valor de 0
          break;
      }
    }
    totalWeight = asistencias.length > 0 ? weightedScore / asistencias.length : 0.0;
    final porcentaje = totalWeight * 100;

    return {
      'puntual': puntual,
      'atrasado': atrasado,
      'justificada': justificada,
      'injustificada': injustificada,
      'porcentaje': porcentaje.toStringAsFixed(2),
      'total': asistencias.length,
    };
  }

  Widget _buildAttendanceSummary() {
    return FutureBuilder<List<Asistencia>>(
      future: _asistenciaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // No mostrar nada si no hay datos
        } else {
          final asistencias = snapshot.data!;
          final stats = _calculateAttendanceStats(asistencias);
          final int total = stats['total'];
          final String porcentaje = stats['porcentaje'];

          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 2.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de Asistencia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatChip(context, 'Puntual', stats['puntual'], Colors.green),
                    _buildStatChip(context, 'Atrasado', stats['atrasado'], Colors.yellow),
                    _buildStatChip(context, 'Justif.', stats['justificada'], Colors.orange),
                    _buildStatChip(context, 'Injust.', stats['injustificada'], Colors.red),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Puntuación total de asistencia:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                      Text(
                        '$porcentaje%',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildStatChip(BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        Chip(
          label: Text(
            '$count',
            style: TextStyle(color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
          ),
          backgroundColor: color,
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }


Widget _buildAsistencia() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.blue[700],
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Text(
            'Asistencia del estudiante',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),





    // Información de la persona
      FutureBuilder<Persona>(
        future: _personaInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            print("Error FutureBuilder Persona (PortafolioPage): ${snapshot.error}");
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No se pudo cargar la información del usuario.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return _buildPersonaInfo(snapshot.data!);
          } else {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('No hay información del usuario disponible.')),
            );
          }
        },
      ),

 



      Expanded(
        child: FutureBuilder<List<Asistencia>>(
          future: _asistenciaFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final asistencias = snapshot.data!;
              return ListView.builder(
                itemCount: asistencias.length,
                itemBuilder: (context, index) {
                  final asistencia = asistencias[index];
                  final tipo = int.tryParse(asistencia.idtipoasistencia ?? '0') ?? 0;

                  Color tarjetaColor;
                  IconData leadingIcon; // Variable para el icono
                  switch (tipo) {
                    case 1: // Puntual
                      tarjetaColor = Colors.green;
                      leadingIcon = Icons.check_circle_outline; // Icono de asistencia puntual
                      break;
                    case 2: // Atrasado
                      tarjetaColor = Colors.yellow;
                      leadingIcon = Icons.timer_off_outlined; // Icono de llegada tarde
                      break;
                    case 3: // Falta Justificada
                      tarjetaColor = Colors.orange;
                      leadingIcon = Icons.report_problem_outlined; // Icono de falta justificada
                      break;
                    case 4: // Falta Injustificada
                      tarjetaColor = Colors.red;
                      leadingIcon = Icons.cancel_outlined; // Icono de falta injustificada
                      break;
                    default:
                      tarjetaColor = Colors.grey.shade300;
                      leadingIcon = Icons.question_mark_outlined; // Icono por defecto
                  }

                  // Color del texto si fondo es muy claro (amarillo)
                  final textColor = (tarjetaColor == Colors.yellow) ? Colors.black : Colors.white;

                  return Card(
                    color: tarjetaColor,
                    child: ListTile(
                      leading: Icon(leadingIcon, color: textColor), // Usando el icono dinámico
                      title: Text(
                        'Fecha: ${asistencia.fecha}',
                        style: TextStyle(color: textColor),
                      ),
                      subtitle: Text(
                        'Tipo de Asistencia: ${asistencia.tipoasistencia}',
                        style: TextStyle(color: textColor),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
       _buildAttendanceSummary(),
    ],
  );
}

}












class TomaasistenciaPage extends StatefulWidget {
  const TomaasistenciaPage({super.key});
  @override
  State<TomaasistenciaPage> createState() => _TomaasistenciaPageState();
}

class _TomaasistenciaPageState extends State<TomaasistenciaPage> {
  final TextEditingController _eventoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  List<Estudiante> estudiantes = [];
  bool cargando = false;

  final opcionesAsistencia = {
    1: 'Puntual',
    2: 'Atrasado',
    3: 'Falta Just.',
    4: 'Falta Injust.'
  };

  void cargarEstudiantes() async {
    setState(() => cargando = true);
    try {
      estudiantes = await ApiService.obtenerEstudiantes(
        _eventoController.text,
        _fechaController.text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar: $e')),
      );
    }
    setState(() => cargando = false);
  }

  void guardarAsistencias() async {
    int exitos = 0;
    int errores = 0;

    for (var est in estudiantes) {
      if (est.idasistencia != null && est.tipoAsistencia != null) {
        try {
          await ApiService.actualizarAsistencia(
            est.idasistencia!,
            est.tipoAsistencia!,
          );
          exitos++;
        } catch (e) {
          errores++;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actualizados: $exitos, Errores: $errores'),
      ),
    );
  }

  bool get camposCompletos =>
      _eventoController.text.isNotEmpty && _fechaController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _eventoController,
              decoration: const InputDecoration(
                labelText: 'ID del Evento',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fechaController,
              decoration: const InputDecoration(
                labelText: 'Fecha (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: cargarEstudiantes,
                  child: const Text('Cargar estudiantes'),
                ),
                ElevatedButton(
                  onPressed: camposCompletos
                      ? () async {
                          try {
                            await ApiService.registrarAsistenciaAll(
                              idevento: _eventoController.text,
                              fecha: _fechaController.text,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Asistencia inicial registrada'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error al registrar asistencia inicial: $e'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Asistencia All'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (cargando)
              const CircularProgressIndicator()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: estudiantes.length,
                  itemBuilder: (context, index) {
                    final e = estudiantes[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  'https://educaysoft.org/descargar2.php?archivo=${e.cedula}.jpg',
                                ),
                              ),
                              title: Text(e.lapersona),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('idasistencia: ${e.idasistencia?.toString() ?? 'sin valor'}'),
                                  DropdownButton<int>(
                                    value: e.tipoAsistencia,
                                    hint: const Text('Seleccione asistencia'),
                                    items: opcionesAsistencia.entries
                                        .map((entry) => DropdownMenuItem<int>(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ))
                                        .toList(),
                                    onChanged: (valor) {
                                      setState(() => e.tipoAsistencia = valor);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  if (e.idasistencia != null && e.tipoAsistencia != null) {
                                    try {
                                      await ApiService.actualizarAsistencia(
                                        e.idasistencia!,
                                        e.tipoAsistencia!,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✅ Asistencia de ${e.lapersona} guardada'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '❌ Error al guardar asistencia de ${e.lapersona}',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Completa el tipo de asistencia primero'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}



















// --- Añadir la siguiente clase al final de EventoDetalleScreen.dart para que la funcionalidad funcione ---

class TemaDetalleScreen extends StatelessWidget {
  final String idtema;
  const TemaDetalleScreen({super.key, required this.idtema});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Tema ID: $idtema'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<List<Tema>>(
        // Se asume que fetchTema existe en ApiService y devuelve un objeto Tema
        future: ApiService.fetchTema(idtema), 
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el tema: ${snapshot.error}'));
          } else {
            final Tema tema = snapshot.data!.first;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailTile(context, 'ID Tema', tema.idtema),
                  _buildDetailTile(context, 'Nombre Corto', tema.nombrecorto),
                  _buildDetailTile(context, 'Nombre Largo', tema.nombrelargo),
                  _buildDetailTile(context, 'N° Sesión', tema.numerosesion),
                  _buildDetailTile(context, 'Objetivo de Aprendizaje', tema.objetivoaprendizaje),
                  _buildDetailTile(context, 'Experiencia', tema.experiencia),
                  _buildDetailTile(context, 'Reflexión', tema.reflexion),
                  _buildDetailTile(context, 'Secuencia', tema.secuencia),
                  _buildDetailTile(context, 'Aprendizaje Autónomo', tema.aprendizajeautonomo),
                  _buildDetailTile(context, 'Duración (min)', tema.duracionminutos),
                  _buildDetailTile(context, 'Link Presentación', tema.linkpresentacion, isLink: true),
                  // Añade más campos según la estructura de la clase Tema
                ],
              ),
            );
          }
        },
      ),
    );
  }

Widget _buildDetailTile(BuildContext context, String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 4.0),
          isLink
              ? InkWell(
                  // Simula un enlace
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Abriendo enlace: $value')),
                    );
                    // Aquí iría el código real para abrir el URL
                  },
                  child: Text(
                    value.isNotEmpty ? value : 'N/A',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(fontSize: 14.0),
                ),
          const Divider(),
        ],
      ),
    );
  }
}
