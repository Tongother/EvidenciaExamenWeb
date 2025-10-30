import 'package:flutter/material.dart';
import 'pages/products_list_page.dart';
import 'pages/product_by_id_page.dart';
import 'pages/create_product_page.dart';
import 'pages/delete_product_page.dart';

void main() {
  runApp(const ProductosApp());
}

class ProductosApp extends StatelessWidget {
  const ProductosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productos API',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/list': (_) => const ProductsListPage(),
        '/byId': (_) => const ProductByIdPage(),
        '/create': (_) => const CreateProductPage(),
        '/delete': (_) => const DeleteProductPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final buttons = [
      ('GET /api/Productos', '/list', Icons.list),
      ('GET /api/Productos/{id}', '/byId', Icons.search),
      ('POST /api/Productos', '/create', Icons.add),
      ('DELETE /api/Productos/{id}', '/delete', Icons.delete),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Productos API · Demo')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: buttons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final (label, route, icon) = (buttons[i].$1, buttons[i].$2, buttons[i].$3);
          return ListTile(
            leading: Icon(icon),
            title: Text(label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, route),
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
        },
      ),
    );
  }
}
