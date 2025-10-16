
class Portafolio {                                                                                               
    final String idportafolio;
    final String elperiodo;
    final String lapersona;
  
    Portafolio({required this.elperiodo, required this.idportafolio, required this.lapersona});
  
    factory Portafolio.fromJson(Map<String, dynamic> json) {
      return Portafolio(
        idportafolio: json['idportafolio'].toString(),
        elperiodo: json['elperiodo'],
        lapersona: json['lapersona'],
      );
    }
  }
  

