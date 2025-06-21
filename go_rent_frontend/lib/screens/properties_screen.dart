import 'package:flutter/material.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import 'property_details_screen.dart';
import 'notifications_screen.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({Key? key}) : super(key: key);

  @override
  _PropertiesScreenState createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  List<Property> _managedProperties = [];
  List<Property> _tenantProperties = [];
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _apiService.loadSessionToken();
    _loadProperties();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _apiService.getNotifications();
      setState(() {
        _unreadNotifications = notifications.where((n) => !n.isRead).length;
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final managedResult = await _apiService.getUserProperties();
      final tenantResult = await _apiService.getUserTenantProperties();

      setState(() {
        _managedProperties = managedResult ?? [];
        _tenantProperties = tenantResult ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading properties: $e');
      setState(() {
        _error = 'Failed to load properties. Please try again.';
        _isLoading = false;
        _managedProperties = [];
        _tenantProperties = [];
      });
    }
  }

  Future<void> _showAddPropertyDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Property Name',
                hintText: 'Enter property name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Enter property address',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty || addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final success = await _apiService.addProperty(
                  nameController.text,
                  addressController.text,
                );

                if (success) {
                  Navigator.pop(context);
                  _loadProperties(); // Refresh the properties list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Property added successfully')),
                  );
                } else {
                  throw Exception('Failed to add property');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildManagedPropertiesFragment() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProperties,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_managedProperties.isEmpty) {
      return const Center(
        child: Text('No managed properties found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _managedProperties.length,
      itemBuilder: (context, index) {
        final property = _managedProperties[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(Icons.home, color: Colors.blue),
            title: Text(property.name),
            subtitle: Text(property.address),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PropertyDetailsScreen(property: property),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTenantPropertiesFragment() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProperties,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_tenantProperties.isEmpty) {
      return const Center(
        child: Text('No tenant properties found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tenantProperties.length,
      itemBuilder: (context, index) {
        final property = _tenantProperties[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(Icons.home, color: Colors.green),
            title: Text(property.name),
            subtitle: Text(property.address),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PropertyDetailsScreen(property: property),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Managed Properties' : 'Tenant Properties'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
                  // Mark notifications as read when user clicks the notification icon
                  try {
                    await _apiService.markNotificationsAsRead();
                    // Update the unread count to 0
                    setState(() {
                      _unreadNotifications = 0;
                    });
                  } catch (e) {
                    print('Error marking notifications as read: $e');
                  }
                  
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                  _loadNotifications();
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProperties,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProperties,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildManagedPropertiesFragment(),
                      _buildTenantPropertiesFragment(),
                    ],
                  ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddPropertyDialog,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.manage_accounts),
            label: 'Managed',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Tenant',
          ),
        ],
      ),
    );
  }
}
