class Salud {
  final int idsalud;
  final String nombre;
  final String descripcion;

  Salud({
    required this.idsalud,
    required this.nombre,
    this.descripcion = '',
  });

  factory Salud.fromJson(Map<String, dynamic> json) {
    return Salud(
      idsalud: int.parse(json['idsalud'].toString()),
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
    );
  }
}
