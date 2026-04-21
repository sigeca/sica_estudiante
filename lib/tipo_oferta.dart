
class TipoOferta {
  final int idtipooferta;
  final String nombre;

  TipoOferta({required this.idtipooferta, required this.nombre});

  factory TipoOferta.fromJson(Map<String, dynamic> json) {
    return TipoOferta(
      idtipooferta: int.parse(json['idtipooferta'].toString()),
      nombre: json['nombre'],
    );
  }
}
