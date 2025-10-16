class Estudiante {
  final String lapersona;
  final String cedula;
  final int? idasistencia;
  final int? idtipoasistencia;
  int? tipoAsistencia; // 1=puntual, 2=atrasado, 3=falta justificada, 4=falta injustificada

  Estudiante({
    required this.lapersona,
    required this.cedula,
    this.idasistencia,
    this.idtipoasistencia,
    this.tipoAsistencia,
  });

  factory Estudiante.fromJson(Map<String, dynamic> json) {
    return Estudiante(
      lapersona: json['lapersona'],
      cedula: json['cedula'],
      idasistencia: int.tryParse(json['idasistencia'].toString()),
      idtipoasistencia: int.tryParse(json['idtipoasistencia'].toString()),
      tipoAsistencia: json['idtipoasistencia'] != null
          ? int.tryParse(json['idtipoasistencia'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'cedula': cedula,
    'idtipoasistencia': tipoAsistencia,
  };
}





class Evento {                                                                                               
    final String idevento;
    final String idpersona;
    final String idtipogrupoparticipante;
    final String titulo;
  
    Evento({required this.titulo, required this.idpersona,required this.idtipogrupoparticipante, required this.idevento});
  
    factory Evento.fromJson(Map<String, dynamic> json) {
      return Evento(
        idevento: json['idevento'].toString(),
        idpersona: json['idpersona'].toString(),
        idtipogrupoparticipante: json['idtipogrupoparticipante'].toString(),
        titulo: json['titulo'],
      );
    }
  }





class Persona {                                                                                               
    final String idpersona;
    final String lapersona;
    final String cedula;
  
    Persona({required this.idpersona, required this.cedula, required this.lapersona});
  
    factory Persona.fromJson(Map<String, dynamic> json) {
      return Persona(
        idpersona: json['idpersona'].toString(),
        cedula: json['cedula'].toString(),
        lapersona: json['lapersona'],
      );
    }
  }









class SesionEvento {
  final String idsesionevento;
  final String tema;
  final String temacorto;
  final String fecha;
  final String idevento;
  final String idcumplimientosesion;
  final String metodologia;
  final String duracionminutos;

  SesionEvento({required this.idsesionevento, required this.fecha , required this.tema, required this.temacorto, required this.idevento, required this.idcumplimientosesion, required this.metodologia, required this.duracionminutos });

  factory SesionEvento.fromJson(Map<String, dynamic> json) {
    return SesionEvento(
      idsesionevento: json['idsesionevento'].toString(),
      tema: json['tema'],
      temacorto: json['temacorto'],
      fecha: json['fecha'],
      idevento: json['idevento'].toString(),
      idcumplimientosesion: json['idcumplimientosesion'],
      metodologia: json['metodologia'] ?? '',
      duracionminutos: (json['duracionminutos'] ?? '') .toString(),
    );
  }
}




class Asistencia {
  final String idasistencia;
  final String fecha;
  final String tipoasistencia;
  final String idtipoasistencia;

  Asistencia({required this.idasistencia, required this.fecha, required this.tipoasistencia , required this.idtipoasistencia});

  factory Asistencia.fromJson(Map<String, dynamic> json) {
    return Asistencia(
      idasistencia: json['idasistencia'].toString(),
      fecha: json['fecha'],
      tipoasistencia: json['tipoasistencia'],
      idtipoasistencia: json['idtipoasistencia'],
    );
  }
}

class Participacion {
  final String idparticipacion;
  final String idevento;
  final DateTime fecha;
  final String porcentaje;
  final double ayuda;
  final String idpersona;
  final String nombres;
  final String comentario;

  Participacion({
      required this.idparticipacion, 
      required this.idevento,
      required this.fecha, 
      required this.porcentaje, 
      required this.ayuda,
      required this.idpersona,
      required this.nombres,
      required this.comentario });

  factory Participacion.fromJson(Map<String, dynamic> json) {
    return Participacion(
      idparticipacion: json['idparticipacion'].toString(),
      idevento: json['idevento'],
      fecha: DateTime.parse(json['fecha']),
      porcentaje: json['porcentaje'].toString(),
      ayuda: double.tryParse(json['ayuda'].toString()) ?? 0.0,
      idpersona: json['idpersona'],
      nombres: json['nombres'],
      comentario: json['comentario'],

    );
  }

Map<String, dynamic> toJson() {
    return {
      'idparticipacion': idparticipacion,
      'idevento': idevento,
      'fecha': fecha.toIso8601String(),
      'porcentaje': porcentaje,
      'ayuda': ayuda,                                                                                                                                                  
      'idpersona': idpersona,
      'nombres': nombres,
      'comentario': comentario,
    };  

}

}


   class Participante {                                                                                               
       final String idevento;
       final String idparticipante;
       final String idpersona;
       final String cedula;
       final String nombres;
       final String grupoletra;
     
       Participante({required this.idevento, required this.idparticipante, required this.idpersona, required this.cedula, required this.nombres, required this.grupoletra});
     
       factory Participante.fromJson(Map<String, dynamic> json) {
        return Participante(
          idevento: json['idevento'].toString(),
          idparticipante: json['idparticipante'].toString(),
          idpersona: json['idpersona'].toString(),
          cedula: json['cedula'].toString(),
          nombres: json['nombres'].toString(),
          grupoletra: json['grupoletra'].toString(),
        );
      }
    }





class Nota {
  final String idparticipacion;
  final String fecha;
  final String porcentaje;
  final String comentario;
  final String idmodoevaluacion;
  final String modoevaluacion;

  Nota({required this.idparticipacion, required this.fecha, required this.porcentaje, required this.comentario, required this.idmodoevaluacion, required this.modoevaluacion});

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      idparticipacion: json['idparticipacion'].toString(),
      fecha: json['fecha'],
      porcentaje: json['porcentaje'],
      comentario: json['comentario'],
      idmodoevaluacion: json['idmodoevaluacion'].toString(),
      modoevaluacion: json['modoevaluacion'],
    );
  }
}




class Pago {
  final String idpagoevento;
  final String fecha;
  final String valor;
  final String comentario;

  Pago({required this.idpagoevento, required this.fecha, required this.valor, required this.comentario });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      idpagoevento: json['idpagoevento'].toString(),
      fecha: json['fecha'],
      valor: json['valor'],
      comentario: json['comentario'],
    );
  }
}


class Pagoevento {
  final String idpagoevento;
  final String idevento;
  final String idpersona;
  final DateTime fecha;
  final double valor;
  final String nombres;
  final String comentario;

  Pagoevento({required this.idpagoevento,required this.idevento,required this.idpersona, required this.fecha, required this.valor, required this.nombres, required this.comentario });

  factory Pagoevento.fromJson(Map<String, dynamic> json) {
    return Pagoevento(
      idpagoevento: json['idpagoevento'].toString(),
      idevento: json['idevento'].toString(),
      idpersona: json['idpersona'].toString(),
      fecha: DateTime.parse(json['fecha']),
      valor: double.parse(json['valor'].toString()),
      nombres: json['nombres'],
      comentario: json['comentario'],
    );
  }
Map<String, dynamic> toJson() {
    return {
      'idpagoevento': idpagoevento,
      'idevento': idevento,
      'fecha': fecha.toIso8601String(),
      'valor': valor,
      'idpersona': idpersona,
      'nombres': nombres,
      'comentario': comentario,
    };
  }





}







class DocumentoPortafolio {
  final String iddocumento;
  final String asunto;
  final String archivopdf;

  DocumentoPortafolio({
    required this.iddocumento,
    required this.asunto,
    required this.archivopdf,
  });

  factory DocumentoPortafolio.fromJson(Map<String, dynamic> json) {
    return DocumentoPortafolio(
      iddocumento: json['iddocumento']?.toString() ?? 'Desconocido',
      asunto: json['asunto'] ?? 'Sin asunto',
      archivopdf: json['archivopdf'] ?? '',
    );
  }
}

class Login {

  final String idpersona;
  final String email;
  final String password;

  Login({
    required this.idpersona,
    required this.email,
    required this.password,
  });

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
      idpersona: json['idpersona']?.toString() ?? 'Desconocido',
      email: json['email'] ?? 'Sin asunto',
      password: json['password'] ?? '',
    );
  }
}


class Vendedor {
  final int idvendedor;
  final int iddepartamento;
  final int idpersona;
  final String cedula;
  final String elvendedor;

  Vendedor({
    required this.idvendedor,
    required this.iddepartamento,
    required this.idpersona,
    required this.cedula,
    required this.elvendedor,
  });

  factory Vendedor.fromJson(Map<String, dynamic> json) {
    return Vendedor(
      idvendedor: int.parse(json['idvendedor']),
      iddepartamento: int.parse(json['iddepartamento']),
      idpersona: int.parse(json['idpersona']),
      cedula: json['cedula'],
      elvendedor: json['elvendedor'],
    );
  }
}



class Articulo {
  final int idarticulo;
  final String elarticulo;
  final String detalle;
  final String idpersona;
  final String elcustodio;
  final String idinstitucion;
  final String lainstitucion;
  final double precio; // Campo de precio

  Articulo({
    required this.idarticulo,
    required this.elarticulo,
    required this.detalle,
    required this.idpersona,
    required this.elcustodio,
    required this.idinstitucion,
    required this.lainstitucion,
    required this.precio,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      idarticulo: int.parse(json['idarticulo'].toString()),
      elarticulo: json['elarticulo'],
      detalle: json['detalle'],
      idpersona: json['idpersona'].toString(),
      elcustodio: json['elcustodio'],
      idinstitucion: json['idinstitucion'].toString(),
      lainstitucion: json['lainstitucion'],
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
    );
  }
}



class Producto {
  final int idproducto;
  final String elproducto;
  final String detalle;
  final String idpersona;
  final String elcustodio;
  final String idinstitucion;
  final String lainstitucion;
  final double precio; // Campo de precio

  Producto({
    required this.idproducto,
    required this.elproducto,
    required this.detalle,
    required this.idpersona,
    required this.elcustodio,
    required this.idinstitucion,
    required this.lainstitucion,
    required this.precio,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      idproducto: int.parse(json['idproducto'].toString()),
      elproducto: json['elproducto'],
      detalle: json['detalle'],
      idpersona: json['idpersona'].toString(),
      elcustodio: json['elcustodio'],
      idinstitucion: json['idinstitucion'].toString(),
      lainstitucion: json['lainstitucion'],
      precio: double.tryParse(json['precio'].toString()) ?? 0.0,
    );
  }
}







