import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'evento.dart';
import 'api_service.dart';

class DocumentosPortafolioScreen extends StatefulWidget {
  final String idportafolio;

  const DocumentosPortafolioScreen({Key? key, required this.idportafolio}) : super(key: key);

  @override
  State<DocumentosPortafolioScreen> createState() => _DocumentosPortafolioScreenState();
}

class _DocumentosPortafolioScreenState extends State<DocumentosPortafolioScreen> {
  List<DocumentoPortafolio> documentos = [];
  List<DocumentoPortafolio> filteredDocumentos = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocumentos();
    _searchController.addListener(_filterDocumentos);
  }

  Future<void> _loadDocumentos() async {
    try {
      final docs = await ApiService.fetchDocumentosPortafolio(widget.idportafolio);
      setState(() {
        documentos = docs;
        filteredDocumentos = docs;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  void _filterDocumentos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredDocumentos = documentos
          .where((d) => d.asunto.toLowerCase().contains(query))
          .toList();
    });
  }


void _abrirPDF(String archivo) async {
  if (archivo.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay archivo PDF disponible')),
    );
    return;
  }

  final url = 'https://educaysoft.org/descargar.php?archivo=${Uri.encodeComponent(archivo)}';
  print('Abriendo URL: $url');

  if (await canLaunch(url)) {
    await launch(url);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se puede abrir el PDF: $url')),
    );
  }
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentos del Portafolio'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por asunto...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: filteredDocumentos.length,
              itemBuilder: (context, index) {
                final doc = filteredDocumentos[index];
                String urlPdf = doc.archivopdf != null                                                          
                     ? 'https://educaysoft.org/descargar.php?archivo=${doc.archivopdf}'
                     : '';

                return Card(
                  child: ListTile(
                    title: Text('Documento ID: ${doc.archivopdf}'),
                    subtitle: Text(doc.asunto),
                    trailing: Icon(Icons.picture_as_pdf, color: Colors.red),
                  onTap: urlPdf.isNotEmpty
                       ? () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => PDFViewerScreen(url: urlPdf),
                             ),
                           );
                         }
                       : null, // Deshabilitar tap si no hay URL



                  ),
                );
              },
            ),
    );
  }
}




// 🔽 Pantalla para visualizar el PDF descargado
 
class PDFViewerScreen extends StatefulWidget {
  final String url;

  const PDFViewerScreen({super.key, required this.url});

  @override
  _PDFViewerScreenState createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: PDF(
        fitEachPage: true,
      ).fromUrl(
        widget.url,
        placeholder: (progress) => Center(child: Text('$progress %')),
        errorWidget: (error) => Center(child: Text('Error: $error')),
      ),
    );
  }
}




















  
