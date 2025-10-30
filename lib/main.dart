import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Clase para representar un objeto de la API, en este caso un 'Todo'
class Item {
  final int id;
  final String nombre;
  final double precio;
  final int existencia;
  final String fechaRegistro;

  Item({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.existencia,
    required this.fechaRegistro
  });

  // Constructor factory para crear una instancia de Todo desde un mapa JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      nombre: json['nombre'],
      precio: json['precio'],
      existencia: json['existencia'],
      fechaRegistro: json['fechaRegistro']
    );
  }
}

// Función asíncrona para consumir la API
Future<Item> fetchItems() async {
  // 1. Define la URL de la API
  final response = await http.get(Uri.parse('http://miapiunach.somee.com/api/Productos'));
  
  // 2. Verifica si la petición fue exitosa (código de estado 200)
  if (!(response.statusCode == 200)){
    throw Exception('Failed to load todo');
  }
  return Item.fromJson(jsonDecode(response.body));
}

// // Ejemplo de cómo llamar a la función (puedes poner esto en initState de un StatefulWidget)
// void main() async {
//   try {
//     Item item = await fetchTodo();
//     print('Datos obtenidos:');
//     print('ID: ${todo.id}');
//     print('Título: ${todo.title}');
//     print('Completado: ${todo.completed}');
//   } catch (e) {
//     print('Error: $e');
//   }
// }
// // -----------------------------------------------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productos UNACH',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProductsListPage(),
    );
  }
}

// -----------------------------------------------------------------------------

// 2. Página Principal (Stateful para manejar el estado de la API)
class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  List<Item> _item = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Función para consumir la API
  Future<void> _fetchProducts() async {
    const url = 'http://miapiunach.somee.com/api/Productos';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Decodificar el JSON
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];

        // Mapear los resultados a la lista de objetos Character
        setState(() {
          _item = results.map((json) => Item.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Fallo al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      // Manejo de errores
      debugPrint('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
        // Opcional: mostrar un mensaje de error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Productos'),
        backgroundColor: Colors.blue.shade600,
      ),
      // El widget COLUMN es la estructura principal vertical
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[        
          //Mapeo de productos
          Expanded( // IMPORTANT: Expanded para que el ListView ocupe el espacio restante
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _item.length,
                    itemBuilder: (context, index) {
                      final item = _item[index];
                      // Cada item de la lista usa el CharacterListItem
                      return ProductListItem(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

//Widget para cada Item
class ProductListItem extends StatelessWidget {
  final Item item;

  const ProductListItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: <Widget>[      
            // Detalles del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.id.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.existencia.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.fechaRegistro,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.precio.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}