
import 'package:flutter/material.dart';

// 1. Importa el modelo de datos (donde está definida la clase SesionEvento)
import 'evento.dart'; 

// 2. Importa las pantallas a las que dirigen los botones
import 'ParticipacionScreen.dart';
import 'AsistenciaScreen.dart';
import 'PagoeventoScreen.dart';
import 'TemaDetalleScreen.dart';

// NOTA: Si tienes una pantalla para 'TemaDetalleScreen', impórtala aquí. 
// Si no tienes el archivo, comenta la línea o el botón correspondiente en el código.
// import 'TemaDetalleScreen.dart';


class SesionItem extends StatefulWidget {
  final SesionEvento sesion;
  final bool isDocente;

  const SesionItem({
    Key? key,
    required this.sesion,
    required this.isDocente,
  }) : super(key: key);

  @override
  State<SesionItem> createState() => _SesionItemState();
}

class _SesionItemState extends State<SesionItem> {
  bool _isExpanded = false; // Controla si la tarjeta está desplegada o no

  // Función para determinar el color según la metodología de evaluación
  Color _getColorByEvaluacion(String? evaluacion) {
    if (evaluacion == null) return Colors.grey.shade200;
    String eval = evaluacion.toLowerCase();
    
    // Define aquí tus reglas de colores
    if (eval.contains('e1') || eval.contains('e2')) return Colors.red.shade100;
    if (eval.contains('b1') || eval.contains('b2')) return Colors.blue.shade100;
    if (eval.contains('c1') || eval.contains('c2')) return Colors.orange.shade100;
    if (eval.contains('a1') || eval.contains('a2')) return Colors.purple.shade100;
    if (eval.contains('investigación')) return Colors.teal.shade100;
    
    // Color por defecto si no coincide con ninguno
    return Colors.grey.shade300; 
  }

  @override
  Widget build(BuildContext context) {
    // Determina el color de la cabecera
    final headerColor = _getColorByEvaluacion(widget.sesion.evaluacion);

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        children: [
          // --- 1. CABECERA (Siempre visible) ---
          Container(
            color: headerColor, // Color basado en metodología de evaluación
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                // Botón de despliegue a la izquierda
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                // Título: Sesión y Unidad
                Expanded(
                  child: Text(
                    'Sesión No: ${widget.sesion.numerosesion}   -   ${widget.sesion.unidadsilabo}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. CONTENIDO DETALLADO (Visible solo si _isExpanded es true) ---
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tema Planificado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.description, color: Colors.blue, size: 20.0),
                      const SizedBox(width: 8.0),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Tema planificado ID: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                            TextSpan(text: '${widget.sesion.idtema}', style: const TextStyle(fontSize: 13.0)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                    width: double.infinity,
                    child: Text(
                      '${widget.sesion.tema}',
                      style: const TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic, color: Colors.black87),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  // Tema Ejecutado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.description, color: Colors.green, size: 20.0),
                      const SizedBox(width: 8.0),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Tema ejecutado ID : ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                            TextSpan(text: '${widget.sesion.idsesionevento}', style: const TextStyle(fontSize: 13.0)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                    width: double.infinity,
                    child: Text(
                      '${widget.sesion.temasilabo}',
                      style: const TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic, color: Colors.black87),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  const SizedBox(height: 8.0),

                  // Metodología
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.lightbulb, color: Colors.green, size: 20.0),
                      const SizedBox(width: 8.0),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Metodología: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                            TextSpan(text: '${widget.sesion.metodologia}', style: const TextStyle(fontSize: 13.0)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Método de Evaluación
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.trending_up, color: Colors.green, size: 20.0),
                      const SizedBox(width: 8.0),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Evaluación: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                            TextSpan(text: '${widget.sesion.evaluacion}', style: const TextStyle(fontSize: 13.0)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Fecha
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(Icons.access_time, color: Colors.green, size: 20.0),
                      const SizedBox(width: 8.0),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Fecha: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.0)),
                            TextSpan(text: '${widget.sesion.fecha}', style: const TextStyle(fontSize: 13.0)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Botones de Acción (Solo Docente)
                  if (widget.isDocente)
                   
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.done, color: Colors.blueAccent),
                            tooltip: 'Participación',
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ParticipacionScreen(idevento: widget.sesion.idevento, fecha: widget.sesion.fecha, temacorto: widget.sesion.temacorto, tema: widget.sesion.tema)));
                            },
                          ),
                          const VerticalDivider(),
                          IconButton(
                            icon: const Icon(Icons.note_alt_outlined, color: Colors.blueAccent),
                            tooltip: 'Notas',
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (_) => ParticipacionScreen(idevento: widget.sesion.idevento, fecha: widget.sesion.fecha, temacorto: widget.sesion.temacorto, tema: widget.sesion.tema)));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.blueAccent),
                            tooltip: 'Asistencias',
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => AsistenciaScreen(idevento: widget.sesion.idevento, fecha: widget.sesion.fecha)));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.monetization_on, color: Colors.blueAccent),
                            tooltip: 'Pagos',
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => PagoeventoScreen(idevento: widget.sesion.idevento, fecha: widget.sesion.fecha)));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.purple),
                            tooltip: 'Detalle',
                            onPressed: () {
                              // Asegúrate de tener TemaDetalleScreen importado
                               Navigator.push(context, MaterialPageRoute(builder: (_) => TemaDetalleScreen(idtema: widget.sesion.idtema)));
                            },
                          ),
                        ],
                      ),
                    )
                  else

                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                             IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.purple),
                            tooltip: 'Detalle',
                            onPressed: () {
                              // Asegúrate de tener TemaDetalleScreen importado
                               Navigator.push(context, MaterialPageRoute(builder: (_) => TemaDetalleScreen(idtema: widget.sesion.idtema)));
                            },
                          ),
                        ],
                      ),
                    ),
                  

                


                ],
              ),
            ),
        ],
      ),
    );
  }
}
