import 'package:flutter/material.dart';
import 'MedicacionGestionPage.dart';
import 'AlimentacionGestionPage.dart';
import 'EjercitacionGestionPage.dart';

class SicaDrawer extends StatelessWidget {
  final String idpersona;
  final String cedula;

  const SicaDrawer({
    Key? key,
    required this.idpersona,
    required this.cedula,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2D3142),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Icon(Icons.school, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  'Menú Principal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.store),
            title: const Text('Marketplace'),
            children: [
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.fastfood, size: 20)),
                title: const Text('Venta de alimentos', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.real_estate_agent, size: 20)),
                title: const Text('Alquiler', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.point_of_sale, size: 20)),
                title: const Text('Ventas', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.miscellaneous_services, size: 20)),
                title: const Text('Servicios', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.account_balance, size: 20)),
                title: const Text('Préstamos', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.health_and_safety),
            title: const Text('Salud'),
            initiallyExpanded: true,
            children: [
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.medication, size: 20)),
                title: const Text('Medicación', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicacionGestionPage(
                        idpersona: idpersona,
                        cedula: cedula,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.restaurant, size: 20)),
                title: const Text('Alimentación', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlimentacionGestionPage(
                        idpersona: idpersona,
                        cedula: cedula,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.fitness_center, size: 20)),
                title: const Text('Ejercitación', style: TextStyle(fontSize: 14)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EjercitacionGestionPage(
                        idpersona: idpersona,
                        cedula: cedula,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
