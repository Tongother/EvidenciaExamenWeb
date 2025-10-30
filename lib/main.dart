import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String _apiUrl = 'http://miapiunach.somee.com/api/Productos';

// -----------------------------------------------------------------------------
// *************** CLASE MODELO ***************

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

  // Constructor factory ajustado para manejar el ID como String (GUID)
  factory Item.fromJson(Map<String, dynamic> json) {
    // 1. Asegurar que 'id' es tratado como String, asumiendo GUID.
    final idValue = json['id'];
    String idString;
    if (idValue is String) {
      idString = idValue;
    } else {
      // Manejar el caso si el ID viene como int (aunque el ejemplo es String)
      idString = idValue.toString();
    }

    return Item(
      id: idString, 
      nombre: json['nombre'] as String,
      // 2. Usar 'num' para ser flexible con int o double y convertir a double.
      precio: (json['precio'] as num).toDouble(),
      existencia: json['existencia'] as int,
      fechaRegistro: json['fechaRegistro'] as String // ISO 8601 string
    );
  }

  Map<String, dynamic> toMapForPost() {
    // 3. No incluir el ID en el POST/CREATE, ya que el servidor lo asigna.
    return {
      "nombre": nombre,
      "precio": precio,
      "existencia": existencia,
      // La API podría esperar la fecha como está (ISO 8601) o solo la fecha
      "fechaRegistro": fechaRegistro, 
    };
  }
}

// -----------------------------------------------------------------------------
// *************** FUNCIONES PARA CONSUMIR LA API ***************

Future<List<Item>> fetchItems() async {
  final response = await http.get(Uri.parse(_apiUrl));
  
  if (response.statusCode == 200) {
    // A. AJUSTE CRUCIAL: Se asume que la respuesta es DIRECTAMENTE una lista (List<dynamic>)
    // de productos, NO un Map con una clave 'results'.
    final List<dynamic> jsonList = json.decode(response.body); 
    
    // Si tu API *realmente* devuelve: `{"results": [...]}`
    // entonces usa: 
    // final Map<String, dynamic> data = json.decode(response.body);
    // final List<dynamic> jsonList = data['results'] as List<dynamic>;
    
    return jsonList.map((json) => Item.fromJson(json)).toList();
  } else {
    debugPrint('Fallo al cargar productos: ${response.statusCode} - ${response.body}');
    throw Exception('Fallo al cargar productos: ${response.statusCode}');
  }
}

// 1. Obtener producto por ID (GET /api/Productos/{id})
Future<Item> fetchItemById(String id) async {
  final response = await http.get(Uri.parse('$_apiUrl/$id'));
  
  if (response.statusCode == 200) {
    return Item.fromJson(json.decode(response.body));
  } else {
    debugPrint('Fallo al cargar el producto con ID $id. Código: ${response.statusCode} - ${response.body}');
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

  // Un POST exitoso puede devolver 200, 201 (Created), o 202 (Accepted)
  if (response.statusCode >= 200 && response.statusCode <= 202) {
    // Si el servidor devuelve el objeto creado, lo parseamos.
    return Item.fromJson(jsonDecode(response.body));
  } else {
    debugPrint('Fallo al crear item: ${response.statusCode} - ${response.body}');
    throw Exception('Fallo al crear item. Código de estado: ${response.statusCode}');
  }
}

// 2. Eliminar producto (DELETE /api/Productos/{id})
Future<void> deleteItem(String id) async {
  final response = await http.delete(Uri.parse('$_apiUrl/$id'));
  
  // Un DELETE exitoso generalmente devuelve 200 (OK) o 204 (No Content)
  if (response.statusCode == 200 || response.statusCode == 204) {
    debugPrint('Producto con ID $id eliminado exitosamente.');
  } else {
    debugPrint('Fallo al eliminar producto: ${response.statusCode} - ${response.body}');
    throw Exception('Fallo al eliminar producto. Código de estado: ${response.statusCode}');
  }
}

// -----------------------------------------------------------------------------
// *************** INTERFAZ DE USUARIO (SIN CAMBIOS FUNCIONALES MAYORES) ***************

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
        // Cambiado a un esquema de color más moderno, aunque opcional
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ProductsListPage(),
    );
  }
}

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
      // Uso de `mounted` es correcto antes de llamar a `ScaffoldMessenger`
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: ${e.toString()}'), 
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Función para CREAR un producto y refrescar la lista
  Future<void> _createNewProduct() async {
    // Usar la fecha/hora actual en formato ISO 8601 que la API espera
    final isoDate = DateTime.now().toIso8601String(); 
    final newItem = Item(
      // El ID no es relevante para el POST, pero la clase Item lo requiere.
      // Se usará el ID devuelto por la API en la respuesta del POST.
      id: "PENDING_ID", 
      nombre: 'Producto #${_items.length + 1} - ${DateTime.now().second}',
      precio: 105.50,
      existencia: 5,
      fechaRegistro: isoDate,
    );

    try {
      // Se utiliza el item devuelto por createItem (que incluye el ID real)
      await createItem(newItem); 
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto creado exitosamente!'), backgroundColor: Colors.green),
        );
      }
      _fetchProducts(); // Refrescar la lista para ver el nuevo item
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear producto: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Función para Eliminar un producto y refrescar la lista
  Future<void> _deleteProductAndRefreshList(String id) async {
    try {
      await deleteItem(id);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Producto con ID $id eliminado!'), backgroundColor: Colors.orange),
        );
      }
      _fetchProducts(); 
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar producto: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Productos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary, // Usar el tema
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
              Navigator.of(ctx).pop(); 
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () {
              Navigator.of(ctx).pop(); 
              onDelete(item.id); 
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
            // Icono decorativo
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(
                Icons.inventory_2_outlined,
                color: Theme.of(context).primaryColor,
                size: 40,
              ),
            ),
            // Detalles del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${item.nombre}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${item.id}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Existencia: ${item.existencia}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Precio: \$${item.precio.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Registro: ${item.fechaRegistro}', 
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Botón de eliminación
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context), 
            ),
          ],
        ),
      ),
    );
  }
}