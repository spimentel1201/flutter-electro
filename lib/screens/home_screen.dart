import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:electro_workshop/services/auth_service.dart';
import 'package:electro_workshop/models/user.dart';
import 'package:electro_workshop/screens/clients/client_list_screen.dart';
import 'package:electro_workshop/screens/inventory/inventory_list_screen.dart';
import 'package:electro_workshop/screens/quotes/quote_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = GetIt.instance<AuthService>();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _currentUser = _authService.currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Electro Workshop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Implement logout functionality
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message with user name
              Text(
                'Bienvenido ${_currentUser?.name ?? "Usuario"}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              // Grid of module buttons
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildModuleButton(
                      title: 'Clientes',
                      icon: Icons.people,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ClientListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModuleButton(
                      title: 'Órdenes de Reparación',
                      icon: Icons.build,
                      onTap: () {
                        // Por ahora mostramos un mensaje ya que la pantalla no está implementada
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Módulo de Órdenes de Reparación en desarrollo'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildModuleButton(
                      title: 'Presupuestos',
                      icon: Icons.description,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const QuoteListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModuleButton(
                      title: 'Ventas',
                      icon: Icons.point_of_sale,
                      onTap: () {
                        // Por ahora mostramos un mensaje ya que la pantalla no está implementada
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Módulo de Ventas en desarrollo'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _buildModuleButton(
                      title: 'Inventario',
                      icon: Icons.inventory,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const InventoryListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildModuleButton(
                      title: 'Usuarios',
                      icon: Icons.person,
                      onTap: () {
                        // Por ahora mostramos un mensaje ya que la pantalla no está implementada
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Módulo de Usuarios en desarrollo'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}