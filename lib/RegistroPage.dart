// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _fechanacimientoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _password2Controller = TextEditingController();

  // Selected values for dropdowns
  String? _selectedSexo;
  String? _selectedPais;
  String? _selectedEvento;

  // Lists for dropdowns
  List<Map<String, dynamic>> _sexos = [];
  List<Map<String, dynamic>> _paises = [];
  List<Map<String, dynamic>> _eventos = [];

  bool _isLoading = false;
  bool _isFetchingData = true;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final sexosData = await ApiService.fetchSexos();
      final paisesData = await ApiService.fetchPaises();
      final eventosData = await ApiService.fetchEventosRegistro();

      if (mounted) {
        setState(() {
          _sexos = sexosData;
          _paises = paisesData;
          _eventos = eventosData;
          _isFetchingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos iniciales: $e')),
        );
        setState(() => _isFetchingData = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fechanacimientoController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSexo == null || _selectedPais == null || _selectedEvento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona todos los campos obligatorios.')),
      );
      return;
    }
    if (_passwordController.text != _password2Controller.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.register(
        idevento: _selectedEvento!,
        cedula: _cedulaController.text.trim(),
        apellidos: _apellidosController.text.trim(),
        nombres: _nombresController.text.trim(),
        email: _emailController.text.trim(),
        idsexo: _selectedSexo!,
        fechanacimiento: _fechanacimientoController.text,
        telefono: _telefonoController.text.trim(),
        idpais: _selectedPais!,
        password: _passwordController.text,
      );

      if (result['resultado'] != 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro/Actualización exitosa. Ahora puedes iniciar sesión.')),
        );
        Navigator.pop(context); // Volver al login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error en el registro. Es posible que el usuario ya exista.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Registro de Usuario', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.shade700, Colors.blue.shade400],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.person_add_outlined, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Crea tu cuenta o recupera tu acceso',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                  shadowColor: Colors.black54,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDropdown(
                            label: 'Evento',
                            value: _selectedEvento,
                            items: _eventos,
                            idKey: 'idevento',
                            displayKey: 'titulo',
                            onChanged: (val) => setState(() => _selectedEvento = val),
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _cedulaController,
                            label: 'Cédula',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.length != 10 ? 'Cédula inválida (10 dígitos)' : null,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _apellidosController,
                            label: 'Apellidos',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _nombresController,
                            label: 'Nombres',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Correo Electrónico',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => val == null || !val.contains('@') ? 'Correo inválido' : null,
                          ),
                          const SizedBox(height: 15),
                          _buildDropdown(
                            label: 'Sexo',
                            value: _selectedSexo,
                            items: _sexos,
                            idKey: 'idsexo',
                            displayKey: 'nombre',
                            onChanged: (val) => setState(() => _selectedSexo = val),
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _fechanacimientoController,
                            label: 'Fecha de Nacimiento',
                            icon: Icons.calendar_today_outlined,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _telefonoController,
                            label: 'Teléfono',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 15),
                          _buildDropdown(
                            label: 'País',
                            value: _selectedPais,
                            items: _paises,
                            idKey: 'idpais',
                            displayKey: 'nombre',
                            onChanged: (val) => setState(() => _selectedPais = val),
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Nueva Contraseña',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _password2Controller,
                            label: 'Repetir Contraseña',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('GUARDAR DATOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '¿Ya tienes una cuenta? Iniciar sesión',
                    style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      validator: validator ?? (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        errorStyle: const TextStyle(height: 0.8),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String idKey,
    required String displayKey,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item[idKey].toString(),
          child: Text(
            item[displayKey].toString(),
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      validator: (val) => val == null ? 'Selección requerida' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label == 'Sexo' ? Icons.people_outline : (label == 'País' ? Icons.public : Icons.event),
          color: Colors.blueAccent,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
