import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    // Mensaje de bienvenida
    _messages.add(
      ChatMessage(
        text: '¡Hola! Soy tu Asistente Virtual. Estoy aquí para ayudarte con información y dudas sobre los reglamentos de la Universidad Técnica Luis Vargas Torres. ¿En qué te puedo ayudar hoy?',
        isUser: false,
      ),
    );
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) => print('Error stt: $errorNotification'),
      );
      setState(() {});
    } catch (e) {
      print('Error inicializando speech_to_text: $e');
    }
  }

  void _listen() async {
    if (!_isListening && _speechEnabled) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) => setState(() {
          _controller.text = val.recognizedWords;
          // Para colocar el cursor al final del texto
          _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
        }),
        localeId: 'es_ES', // Recomendado forzar español
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    final response = await ApiService.chatWithAgenteIa(text);

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente Reglamentos (IA)'),
        backgroundColor: const Color(0xFF2D3142),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.15,
              child: Image.network(
                'https://educaysoft.org/sica/images/logoeysutlvt.png',
                width: 250,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.school_outlined, size: 120, color: Colors.grey),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: msg.isUser ? Colors.blue[600] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                            bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(0),
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Pregunta sobre reglamentos...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      backgroundColor: _isListening ? Colors.red : Colors.blue[600],
                      child: IconButton(
                        icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
                        onPressed: _speechEnabled ? _listen : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reconocimiento de voz no disponible o sin permisos.')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    CircleAvatar(
                      backgroundColor: Colors.blue[600],
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
