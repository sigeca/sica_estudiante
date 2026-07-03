import 'package:flutter/material.dart';
import 'evento.dart';
import 'api_service.dart';
import 'main.dart'; // To reuse AsignaturaCard
import 'SicaAppBar.dart';

class CursosMoocPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const CursosMoocPage({
    Key? key,
    required this.idpersona,
    required this.cedula,
  }) : super(key: key);

  @override
  State<CursosMoocPage> createState() => _CursosMoocPageState();
}

class _CursosMoocPageState extends State<CursosMoocPage> {
  late Future<List<Asignatura>> _asignaturasFuture;

  @override
  void initState() {
    super.initState();
    _asignaturasFuture = ApiService.fetchAsignaturasMalla();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SicaAppBar(
        title: 'Cursos Malla MOOC',
        idpersona: widget.idpersona,
        cedula: widget.cedula,
        showDrawer: false,
      ),
      body: FutureBuilder<List<Asignatura>>(
        future: _asignaturasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final asignaturas = snapshot.data!;

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: asignaturas.length,
              itemBuilder: (context, index) {
                return AsignaturaCard(
                  asignatura: asignaturas[index],
                );
              },
            );
          }
          return const Center(child: Text('No hay asignaturas disponibles.'));
        },
      ),
    );
  }
}
