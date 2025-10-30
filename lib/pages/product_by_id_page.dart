import 'package:flutter/material.dart';
import '../api_service.dart';

class ProductByIdPage extends StatefulWidget {
  const ProductByIdPage({super.key});
  @override
  State<ProductByIdPage> createState() => _ProductByIdPageState();
}

class _ProductByIdPageState extends State<ProductByIdPage> {
  final _idCtrl = TextEditingController();

  Map<String, dynamic>? product;
  String? error;
  bool loading = false;

  static final _uuidRegExp = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  bool get _validUuid => _uuidRegExp.hasMatch(_idCtrl.text.trim());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is String && _idCtrl.text.isEmpty) {
      _idCtrl.text = arg;
    }
  }

  Future<void> _fetch() async {
    final id = _idCtrl.text.trim();
    if (!_validUuid) {
      setState(() => error = 'El ID debe ser un UUID válido (v4).');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      product = null;
    });
    try {
      final data = await ApiService.getProductoById(id);
      setState(() => product = data);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = product;
    return Scaffold(
      appBar: AppBar(title: const Text('GET · /api/Productos/{id}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idCtrl,
              decoration: InputDecoration(
                labelText: 'UUID del producto',
                border: const OutlineInputBorder(),
                helperText: 'Ej: 3fa85f64-5717-4562-b3fc-2c963f66afa6',
                errorText: (_idCtrl.text.isEmpty || _validUuid)
                    ? null
                    : 'UUID inválido',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading || !_validUuid ? null : _fetch,
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
            ),
            const SizedBox(height: 24),
            if (loading) const LinearProgressIndicator(),
            if (error != null)
              Text(error!, style: const TextStyle(color: Colors.red)),
            if (info != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (info['nombre'] ?? info['Nombre'] ?? '(sin nombre)')
                            .toString(),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Precio: ${(info['precio'] ?? info['Precio'] ?? '')}  '
                          '·  Existencia: ${(info['existencia'] ?? info['Existencia'] ?? '')}'),
                      const SizedBox(height: 8),
                      SelectableText(
                        (info['id'] ?? info['Id'] ?? '').toString(),
                        // muestra el GUID completo
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
