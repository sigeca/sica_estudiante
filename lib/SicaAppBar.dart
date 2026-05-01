import 'package:flutter/material.dart';
import 'CartController.dart';
import 'CarritoProducto.dart';

class SicaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String idpersona;
  final String cedula;
  final List<Widget>? actions;
  final bool showLogout;
  final VoidCallback? onLogout;
  final String? title;

  const SicaAppBar({
    Key? key,
    required this.idpersona,
    required this.cedula,
    this.actions,
    this.showLogout = false,
    this.onLogout,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Row(
        children: [
          Image.network(
            'https://educaysoft.org/sica/images/logo.jpg',
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.school, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title ?? 'SICA - Educaysoft',
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<int>(
          valueListenable: CartController().cartCount,
          builder: (context, count, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CarritoProductoPage(
                          idpersona: idpersona,
                          cedula: cedula,
                        ),
                      ),
                    ).then((_) => CartController().updateCartCount(idpersona));
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (actions != null) ...actions!,
        if (showLogout)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: onLogout,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
