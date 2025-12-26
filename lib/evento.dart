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
        cedula: json['cedula'] ?? '',
        lapersona: json['lapersona'] ?? '',
      );
    }
  }









class SesionEvento {
  final String idsesionevento;
  final String unidadsilabo;
  final String tema;
  final String temasilabo;
  final String temacorto;
  final String fecha;
  final String idevento;
  final String idcumplimientosesion;
  final String metodologia;
  final String evaluacion;
  final String duracionminutos;
  final String idtema;
  final String numerosesion;

  SesionEvento({required this.idsesionevento, required this.fecha,required this.unidadsilabo , required this.tema, required this.temasilabo, required this.temacorto, required this.idevento, required this.idcumplimientosesion, required this.metodologia,required this.evaluacion, required this.duracionminutos, required this.idtema, required this.numerosesion });

  factory SesionEvento.fromJson(Map<String, dynamic> json) {
    return SesionEvento(
      idsesionevento: json['idsesionevento'].toString(),
      unidadsilabo: json['unidadsilabo'],
      tema: json['tema'],
      temasilabo: json['temasilabo'],
      temacorto: json['temacorto'],
      fecha: json['fecha'],
      idevento: json['idevento'].toString(),
      idcumplimientosesion: json['idcumplimientosesion'],
      metodologia: json['metodologia'] ?? '',
      evaluacion: json['evaluacion'] ?? '',
      duracionminutos: (json['duracionminutos'] ?? '') .toString(),
      idtema: json['idtema']?.toString() ?? '',
      numerosesion: json['numerosesion']?.toString() ?? '',
    );
  }
}



class Tema {
  final String idtema;
  final String nombrecorto;
  final String nombrelargo;
  final String numerosesion;
  final String objetivoaprendizaje;
  final String experiencia;
  final String reflexion;
  final String secuencia;
  final String aprendizajeautonomo;
  final String idunidadsilabo;
  final String launidadsilabo;
  final String unidad;
  final String idsilabo;
  final String duracionminutos;
  final String idvideotutorial;
  final String idreactivo;
  final String idmodoevaluacion;
  final String enlace;
  final String linkpresentacion;
  final String idaula;

  Tema({
    required this.idtema,
    required this.nombrecorto,
    required this.nombrelargo,
    required this.numerosesion,
    required this.objetivoaprendizaje,
    required this.experiencia,
    required this.reflexion,
    required this.secuencia,
    required this.aprendizajeautonomo,
    required this.idunidadsilabo,
    required this.launidadsilabo,
    required this.unidad,
    required this.idsilabo,
    required this.duracionminutos,
    required this.idvideotutorial,
    required this.idreactivo,
    required this.idmodoevaluacion,
    required this.enlace,
    required this.linkpresentacion,
    required this.idaula,
  });

  factory Tema.fromJson(Map<String, dynamic> json) {
    return Tema(
      idtema: json['idtema']?.toString() ?? '',
      nombrecorto: json['nombrecorto'] ?? '',
      nombrelargo: json['nombrelargo'] ?? '',
      numerosesion: json['numerosesion']?.toString() ?? '',
      objetivoaprendizaje: json['objetivoaprendizaje'] ?? '',
      experiencia: json['experiencia'] ?? '',
      reflexion: json['reflexion'] ?? '',
      secuencia: json['secuencia'] ?? '',
      aprendizajeautonomo: json['aprendizajeautonomo'] ?? '',
      idunidadsilabo: json['idunidadsilabo']?.toString() ?? '',
      launidadsilabo: json['launidadsilabo'] ?? '',
      unidad: json['unidad'] ?? '',
      idsilabo: json['idsilabo']?.toString() ?? '',
      duracionminutos: json['duracionminutos']?.toString() ?? '',
      idvideotutorial: json['idvideotutorial']?.toString() ?? '',
      idreactivo: json['idreactivo']?.toString() ?? '',
      idmodoevaluacion: json['idmodoevaluacion']?.toString() ?? '',
      enlace: json['enlace'] ?? '',
      linkpresentacion: json['linkpresentacion'] ?? '',
      idaula: json['idaula']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'idtema': idtema,
    'nombrecorto': nombrecorto,
    'nombrelargo': nombrelargo,
    'numerosesion': numerosesion,
    'objetivoaprendizaje': objetivoaprendizaje,
    'experiencia': experiencia,
    'reflexion': reflexion,
    'secuencia': secuencia,
    'aprendizajeautonomo': aprendizajeautonomo,
    'idunidadsilabo': idunidadsilabo,
    'launidadsilabo': launidadsilabo,
    'unidad': unidad,
    'idsilabo': idsilabo,
    'duracionminutos': duracionminutos,
    'idvideotutorial': idvideotutorial,
    'idreactivo': idreactivo,
    'idmodoevaluacion': idmodoevaluacion,
    'linkpresentacion': linkpresentacion,
    'idaula': idaula,
  };
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
  final String ponderacion;
  final double ayuda;
  final String idpersona;
  final String nombres;
  final String comentario;

  Participacion({
      required this.idparticipacion, 
      required this.idevento,
      required this.fecha, 
      required this.porcentaje, 
      required this.ponderacion, 
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
      ponderacion: json['ponderacion'].toString(),
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
      'ponderacion': ponderacion,
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
  final String ponderacion;
  final String comentario;
  final String idmodoevaluacion;
  final String modoevaluacion;

  Nota({required this.idparticipacion, required this.fecha, required this.porcentaje, required this.ponderacion, required this.comentario, required this.idmodoevaluacion, required this.modoevaluacion});

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      idparticipacion: json['idparticipacion'].toString(),
      fecha: json['fecha'],
      porcentaje: json['porcentaje'],
      ponderacion: json['ponderacion'],
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
//  final String password;

  Login({
    required this.idpersona,
    required this.email,
  //  required this.password,
  });

  factory Login.fromJson(Map<String, dynamic> json) {
    return Login(
      idpersona: json['idpersona']?.toString() ?? 'Desconocido',
      email: json['email'] ?? 'Sin correo',
 //     password: json['password'] ?? '',
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







// Agrega esta clase al final del archivo o donde prefieras
class Cumplimiento {
  final String idcumplimiento;
  final String fechahora;
  final int cumplimiento; // 1 o 0

  Cumplimiento({required this.idcumplimiento, required this.fechahora, required this.cumplimiento});

  factory Cumplimiento.fromJson(Map<String, dynamic> json) {
    return Cumplimiento(
      idcumplimiento: json['idcumplimientomedicacion'].toString(),
      fechahora: json['fechahora'],
     cumplimiento: int.tryParse(json['cumplimiento'].toString()) ?? 0,
    );
  }
}

// Actualiza esta clase existente

class DetalleMedicacion {
  final String iddetallemedicacion;
  final String idmedicacion;
  final String elmedicamento;
  final String detalle;
  final String detallemedicamento;
  final String fechadesde;
  final String fechahasta;
  final double porcentaje; // <-- NUEVO CAMPO
  // 🎯 NUEVO CAMPO: Ultima fecha en que se registró un cumplimiento
  final String? ultimaFechaCumplimiento;

  DetalleMedicacion({
    required this.iddetallemedicacion,
    required this.idmedicacion,
    required this.elmedicamento,
    required this.detalle,
    required this.detallemedicamento,
    required this.fechadesde,
    required this.fechahasta,
    required this.porcentaje, // <-- Requerido
    this.ultimaFechaCumplimiento, // 🎯 AÑADIR A CONSTRUCTOR
  });

  factory DetalleMedicacion.fromJson(Map<String, dynamic> json) {
    return DetalleMedicacion(
      iddetallemedicacion: json['iddetallemedicacion'].toString(),
      idmedicacion: json['idmedicacion'].toString(),
      elmedicamento: json['elmedicamento'] ?? '',
      detalle: json['detalle'] ?? '',
      detallemedicamento: json['detallemedicamento'] ?? '',
      fechadesde: json['fechadesde'] ?? '',
      fechahasta: json['fechahasta'] ?? '',
      // Leemos el porcentaje calculado por PHP. Si es null es 0.0
      porcentaje: double.tryParse(json['porcentaje'].toString()) ?? 0.0,
      // 🎯 NUEVA LÍNEA: Leer el valor del JSON (asumiendo que la API lo proporcionará)
      ultimaFechaCumplimiento: json['ultima_fecha_cumplimiento'],
    );
  }
}












// 1. Modifica la clase Medicacion existente
class Medicacion {
  final String idmedicacion;
  final String nombre;
  final String? tipo;
  final int idtipomedicacion;
  final int idestadomedicacion; // NUEVO
   final String fechadesde;
  final String fechahasta;
  final String elestadomedicacion; // NUEVO
  List<DetalleMedicacion> detalles;

  Medicacion({
    required this.idmedicacion,
    required this.nombre,
    this.tipo,
    required this.idtipomedicacion,
    required this.idestadomedicacion,
    required this.elestadomedicacion,
    required this.detalles,
    required this.fechadesde,
    required this.fechahasta,

  });

  factory Medicacion.fromJson(Map<String, dynamic> json) {
    List<DetalleMedicacion> listaDetalles = [];
    if (json['detalles'] != null) {
      listaDetalles = (json['detalles'] as List)
          .map((i) => DetalleMedicacion.fromJson(i))
          .toList();
    }

    return Medicacion(
      idmedicacion: json['idmedicacion'].toString(),
      // Mapeo flexible para nombre (por si la vista o tabla cambian)
      nombre: json['lamedicacion'] ?? json['nombre'] ?? 'Sin nombre',
      tipo: json['eltipomedicacion'] ?? json['tipo'] ?? '',
      idtipomedicacion: int.tryParse(json['idtipomedicacion'].toString()) ?? 1,
      // Valores por defecto si vienen nulos
      idestadomedicacion: int.tryParse(json['idestadomedicacion'].toString()) ?? 1,
      elestadomedicacion: json['elestadomedicacion'] ?? 'Activo',
      fechadesde: json['fechadesde'] ?? '',
      fechahasta: json['fechahasta'] ?? '',
      detalles: listaDetalles,
    );
  }
}



// 2. Agrega la nueva clase para Signos Vitales al final del archivo
class SignoVital {
  final String idsignovital;
  final String valor;
  final int idtiposignovital; // 1=Presión, 2=Temperatura, etc. (según tu lógica)
  final DateTime fecha;

  SignoVital({
    required this.idsignovital,
    required this.valor,
    required this.idtiposignovital,
    required this.fecha,
  });

  factory SignoVital.fromJson(Map<String, dynamic> json) {
    return SignoVital(
      idsignovital: json['idsignovital'].toString(),
      valor: json['valor'] ?? '',
      idtiposignovital: int.tryParse(json['idtiposignovital'].toString()) ?? 0,
      fecha: DateTime.tryParse(json['fechahora'] ?? '') ?? DateTime.now(),
    );
  }
}




class MedicamentoVista {
  final String idMedicamento;
  final String nombre;
  final String detalle;
  final String detallemedicamento;
  int totalRegistros; // Nuevo campo

  MedicamentoVista({
    required this.idMedicamento, 
    required this.nombre, 
    required this.detalle,
    required this.detallemedicamento,
    this.totalRegistros = 1,
  });

  factory MedicamentoVista.fromJson(Map<String, dynamic> json) {
    return MedicamentoVista(
      idMedicamento: json['idmedicamento'].toString(),
      nombre: json['elmedicamento'] ?? '',
      detalle: json['detalle'] ?? '',
      detallemedicamento: json['detallemedicamento'] ?? '',
    );
  }
}





