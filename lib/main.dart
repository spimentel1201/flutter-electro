import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/services/api_service.dart';
import 'package:electro_workshop/services/auth_service.dart';
import 'package:electro_workshop/services/inventory_service.dart';
import 'package:electro_workshop/screens/login_screen.dart';
import 'package:electro_workshop/screens/home_screen.dart';

// Service locator
final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Register services
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(baseUrl: 'https://api.example.com/v1'),
  );
  
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(apiService: getIt<ApiService>()),
  );
  
  getIt.registerLazySingleton<InventoryService>(
    () => InventoryService(apiService: getIt<ApiService>()),
  );
}

void main() {
  // Initialize service locator
  setupServiceLocator();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electro Workshop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          secondary: Colors.amber,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // List of workshop items/equipment
  final List<Map<String, dynamic>> _workshopItems = [
    {
      'name': 'Soldering Iron',
      'category': 'Tools',
      'status': 'Available',
      'location': 'Cabinet A',
    },
    {
      'name': 'Oscilloscope',
      'category': 'Test Equipment',
      'status': 'In Use',
      'location': 'Workbench 2',
    },
    {
      'name': 'Arduino Uno',
      'category': 'Components',
      'status': 'Available',
      'location': 'Drawer B',
    },
    {
      'name': 'Multimeter',
      'category': 'Test Equipment',
      'status': 'Available',
      'location': 'Cabinet C',
    },
  ];

  // Filter options
  String _filterCategory = 'All';
  final List<String> _categories = ['All', 'Tools', 'Test Equipment', 'Components'];

  // Navigation index
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Filter items based on selected category
    final filteredItems = _filterCategory == 'All'
        ? _workshopItems
        : _workshopItems.where((item) => item['category'] == _filterCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // TODO: Implement profile/login functionality
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Electro Workshop',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Repair Management System',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('Repair Orders'),
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventory'),
              onTap: () {
                setState(() => _currentIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customers'),
              onTap: () {
                setState(() => _currentIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale),
              title: const Text('Sales'),
              onTap: () {
                setState(() => _currentIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                setState(() => _currentIndex = 5);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _getPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Repairs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show different action based on current page
          switch (_currentIndex) {
            case 1: // Repair Orders
              // TODO: Add new repair order
              break;
            case 2: // Inventory
              // TODO: Add new inventory item
              break;
            case 3: // Customers
              // TODO: Add new customer
              break;
            default:
              // Default action
              break;
          }
        },
        tooltip: 'Add New',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return _buildDashboardPage();
      case 1:
        return _buildRepairOrdersPage();
      case 2:
        return _buildInventoryPage();
      case 3:
        return _buildCustomersPage();
      case 4:
        return _buildSalesPage();
      case 5:
        return _buildSettingsPage();
      default:
        return _buildDashboardPage();
    }
  }

  Widget _buildDashboardPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Dashboard stats cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Pending Repairs', '12', Colors.orange),
                _buildStatCard('Completed Today', '5', Colors.green),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Low Stock Items', '8', Colors.red),
                _buildStatCard('Active Technicians', '3', Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        width: 150,
        height: 100,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryPage() {
    return Column(
      children: [
        // Category filter dropdown
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text('Filter by: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _filterCategory,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _filterCategory = newValue;
                    });
                  }
                },
                items: _categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        
        // Workshop items list
        Expanded(
          child: ListView.builder(
            itemCount: _workshopItems.length,
            itemBuilder: (context, index) {
              final item = _workshopItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(item['name']),
                  subtitle: Text('${item['category']} • ${item['location']}'),
                  trailing: Chip(
                    label: Text(item['status']),
                    backgroundColor: item['status'] == 'Available' 
                        ? Colors.green[100] 
                        : Colors.orange[100],
                  ),
                  onTap: () {
                    // TODO: Show item details
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRepairOrdersPage() {
    // Placeholder for repair orders page
    return const Center(
      child: Text('Repair Orders - Coming Soon'),
    );
  }

  Widget _buildCustomersPage() {
    // Placeholder for customers page
    return const Center(
      child: Text('Customers - Coming Soon'),
    );
  }

  Widget _buildSalesPage() {
    // Placeholder for sales page
    return const Center(
      child: Text('Sales - Coming Soon'),
    );
  }

  Widget _buildSettingsPage() {
    // Placeholder for settings page
    return const Center(
      child: Text('Settings - Coming Soon'),
    );
  }
}
