import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api_service.dart';

class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});
  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getProductos();
  }

  void _openById(String id) {
    Navigator.pushNamed(context, '/byId', arguments: id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GET · /api/Productos')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(
              error: snap.error.toString(),
              onRetry: () => setState(() => _future = ApiService.getProductos()),
            );
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Sin productos'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = items[i];
              final nombre = (p['nombre'] ?? p['Nombre'] ?? '(sin nombre)').toString();
              final precio = (p['precio'] ?? p['Precio'] ?? '').toString();
              final existencia = (p['existencia'] ?? p['Existencia'] ?? '').toString();
              final id = (p['id'] ?? p['Id'] ?? '').toString();

              return ListTile(
                onTap: id.isNotEmpty ? () => _openById(id) : null,
                leading: const Icon(Icons.inventory_2),
                title: Text(nombre),
                subtitle: Text('Precio: $precio  ·  Existencia: $existencia'),
                trailing: SizedBox(
                  width: 220,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SelectableText(
                          id, // 👈 UUID completo visible/seleccionable
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copiar id',
                        icon: const Icon(Icons.copy),
                        onPressed: id.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ID copiado')),
                                );
                              },
                      ),
                    ],
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
