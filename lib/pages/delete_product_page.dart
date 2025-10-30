import 'package:flutter/material.dart';
import '../api_service.dart';

class DeleteProductPage extends StatefulWidget {
  const DeleteProductPage({super.key});
  @override
  State<DeleteProductPage> createState() => _DeleteProductPageState();
}

class _DeleteProductPageState extends State<DeleteProductPage> {
  final _idCtrl = TextEditingController();
  bool loading = false;
  String? message;

  Future<void> _delete() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() { loading = true; message = null; });
    try {
      await ApiService.deleteProducto(id);
      setState(() => message = 'Eliminado: $id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto $id eliminado')),
        );
      }
    } catch (e) {
      setState(() => message = 'Error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DELETE · /api/Productos/{id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idCtrl,
              decoration: const InputDecoration(
                  labelText: 'UUID del producto', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : _delete,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Eliminar'),
            ),
            if (loading) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
            if (message != null) Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(message!,
                style: TextStyle(color: message!.startsWith('Error') ? Colors.red : Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
