import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
const String _apiUrl = 'http://miapiunach.somee.com/api/Productos';

class Item {
  final String id;
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

  factory Item.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'];
    String idString;
    if (idValue is int) {
      idString = idValue.toString();
    } else if (idValue is String) {
      idString = idValue;
    } else {
      throw FormatException("El ID no es ni String ni Int: $idValue");
    }

    return Item(
      id: idString, 
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      existencia: json['existencia'] as int,
      fechaRegistro: json['fechaRegistro'] as String
    );
  }
  
  // 2. Método toMap() para preparar el cuerpo de la solicitud POST
  Map<String, dynamic> toMapForPost() {
    return {
      "nombre": nombre,
      "precio": precio,
      "existencia": existencia,
      "fechaRegistro": fechaRegistro,
    };
  }
}

// -----------------------------------------------------------------------------
// *************** FUNCIONES PARA CONSUMIR LA API ***************

// Función para obtener TODOS los productos (GET /api/Productos)
Future<List<Item>> fetchItems() async {
  final response = await http.get(Uri.parse(_apiUrl));
  
  if (response.statusCode == 200) {
    // Asumiendo que el cuerpo es un objeto con una clave 'results' que es una lista.
    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> results = data['results'];
    
    return results.map((json) => Item.fromJson(json)).toList();
  } else {
    throw Exception('Fallo al cargar productos: ${response.statusCode}');
  }
}

// 1. **NUEVA FUNCIÓN:** Obtener producto por ID (GET /api/Productos/{id})
Future<Item> fetchItemById(String id) async {
  final response = await http.get(Uri.parse('$_apiUrl/$id'));
  
  if (response.statusCode == 200) {
    // Asumiendo que la respuesta es el objeto JSON del producto
    return Item.fromJson(json.decode(response.body));
  } else {
    throw Exception('Fallo al cargar el producto con ID $id. Código: ${response.statusCode}');
  }
}

// Función para crear un nuevo producto (POST /api/Productos)
Future<Item> createItem(Item newItem) async {
  final url = Uri.parse(_apiUrl);
  final headers = {"Content-Type": "application/json"};
  final body = jsonEncode(newItem.toMapForPost());

  debugPrint('Enviando cuerpo POST: $body');

  final response = await http.post(
    url,
    headers: headers,
    body: body,
  );

  if (response.statusCode >= 200 && response.statusCode <= 202) {
    return Item.fromJson(jsonDecode(response.body));
  } else {
    debugPrint('Fallo al crear item: ${response.statusCode} - ${response.body}');
    throw Exception('Fallo al crear item. Código de estado: ${response.statusCode}');
  }
}

// 2. **NUEVA FUNCIÓN:** Eliminar producto (DELETE /api/Productos/{id})
Future<void> deleteItem(String id) async {
  final response = await http.delete(Uri.parse('$_apiUrl/$id'));
  
  // Un DELETE exitoso generalmente devuelve 200 (OK) o 204 (No Content)
  if (response.statusCode == 200 || response.statusCode == 204) {
    debugPrint('Producto con ID $id eliminado exitosamente.');
    // No hay cuerpo de respuesta que parsear
  } else {
    debugPrint('Fallo al eliminar producto: ${response.statusCode} - ${response.body}');
    throw Exception('Fallo al eliminar producto. Código de estado: ${response.statusCode}');
  }
}

// -----------------------------------------------------------------------------

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

// Página Principal (Stateful para manejar el estado de la API)
class ProductsListPage extends StatefulWidget {
  const ProductsListPage({super.key});

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  List<Item> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Función para consumir la API (GET ALL)
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<Item> fetchedItems = await fetchItems();

      setState(() {
        _items = fetchedItems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar datos: $e');
      setState(() {
        _isLoading = false;
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')),
        );
      }
    }
  }
  
  // Función para CREAR un producto y refrescar la lista
  Future<void> _createNewProduct() async {
    final newItem = Item(
      id: "PENDING_ID", // Este ID se reemplazará en toMapForPost()
      nombre: 'Nuevo Producto Test ${DateTime.now().second}',
      precio: 105.50,
      existencia: 5,
      fechaRegistro: DateTime.now().toIso8601String(),
    );

    try {
      await createItem(newItem);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto creado exitosamente!')),
        );
      }
      _fetchProducts(); // Refrescar la lista
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear producto: $e')),
        );
      }
    }
  }

  // **NUEVA FUNCIÓN:** Eliminar un producto y refrescar la lista
  Future<void> _deleteProductAndRefreshList(String id) async {
    try {
      await deleteItem(id);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto con ID $id eliminado!')),
        );
      }
      // Volver a cargar la lista después de la eliminación exitosa
      _fetchProducts(); 
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar producto: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Productos'),
        backgroundColor: Colors.blue.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('No hay productos disponibles.'))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          // Pasar la función de eliminación como callback
                          return ProductListItem(
                            item: item,
                            onDelete: _deleteProductAndRefreshList,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewProduct,
        tooltip: 'Agregar Producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}

//Widget para cada Item (AHORA con un botón de eliminación)
class ProductListItem extends StatelessWidget {
  final Item item;
  // Callback para la eliminación
  final Function(String id) onDelete; 

  const ProductListItem({
    super.key, 
    required this.item,
    required this.onDelete,
  });

  // Función para mostrar el diálogo de confirmación
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar el producto "${item.nombre}" (ID: ${item.id})?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(ctx).pop(); // Cerrar diálogo
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(ctx).pop(); // Cerrar diálogo
              onDelete(item.id); // Llamar a la función de eliminación
            },
          ),
        ],
      ),
    );
  }

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
                    'ID: ${item.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Nombre: ${item.nombre}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Existencia: ${item.existencia.toString()}',
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha: ${item.fechaRegistro.split('T')[0]}', // Mostrar solo la fecha
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Precio: \$${item.precio.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // **NUEVO** Botón de eliminación
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context), // Mostrar diálogo de confirmación
            ),
          ],
        ),
      ),
    );
  }
}