import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_service.dart';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _precio = TextEditingController();
  final _existencia = TextEditingController(text: '0');

  bool loading = false;
  Map<String, dynamic>? created;

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() {
      loading = true;
      created = null;
    });

    try {
      final result = await ApiService.createProducto(
        nombre: _nombre.text.trim(),
        precio: num.parse(_precio.text.trim()),
        existencia: int.parse(_existencia.text.trim()),
      );

      setState(() => created = result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto creado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _existencia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POST · /api/Productos')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'El nombre es requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _precio,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'El precio es requerido';
                final n = num.tryParse(v);
                if (n == null) return 'Debe ser numérico';
                if (n < 0) return 'No puede ser negativo';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _existencia,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Existencia',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'La existencia es requerida';
                final n = int.tryParse(v);
                if (n == null) return 'Debe ser entero';
                if (n < 0) return 'No puede ser negativo';
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: loading ? null : _submit,
              icon: const Icon(Icons.save),
              label: const Text('Crear'),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (created != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(created),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
