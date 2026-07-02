import 'package:flutter/material.dart';
import 'evento.dart';
import 'api_service.dart';
import 'main.dart'; // To reuse EventoCard if possible, or we can create a custom one.
import 'SicaAppBar.dart';

class EventosActivosPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const EventosActivosPage({
    Key? key,
    required this.idpersona,
    required this.cedula,
  }) : super(key: key);

  @override
  State<EventosActivosPage> createState() => _EventosActivosPageState();
}

class _EventosActivosPageState extends State<EventosActivosPage> {
  late Future<List<Evento>> _eventosFuture;

  @override
  void initState() {
    super.initState();
    _eventosFuture = ApiService.fetchEventos(widget.idpersona);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SicaAppBar(
        title: 'Eventos Activos',
        idpersona: widget.idpersona,
        cedula: widget.cedula,
        showDrawer: false,
      ),
      body: FutureBuilder<List<Evento>>(
        future: _eventosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final todosEventos = snapshot.data!;
            // Filtrar eventos con estado 'INSCRIPCIÓN' o 'EN EJECUCIÓN'
            final eventosActivos = todosEventos.where((e) {
              final st = e.estado.toUpperCase();
              return st.contains('INSCRIPCI') || st.contains('EJECUCI');
            }).toList();

            if (eventosActivos.isEmpty) {
              return const Center(child: Text('No hay eventos en inscripción o ejecución.'));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: eventosActivos.length,
              itemBuilder: (context, index) {
                // EventoCard está diseñado para scroll horizontal (tiene margin y width fijo),
                // pero dentro de un GridView el crossAxis constraint forzará su ancho.
                return EventoCard(
                  evento: eventosActivos[index],
                  idpersona: widget.idpersona,
                  cedula: widget.cedula,
                );
              },
            );
          }
          return const Center(child: Text('No hay eventos activos.'));
        },
      ),
    );
  }
}
