import 'package:flutter/material.dart';
import '../models/property.dart';
import '../models/floor.dart';
import '../services/api_service.dart';
import 'notifications_screen.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({Key? key, required this.property}) : super(key: key);

  @override
  _PropertyDetailsScreenState createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  List<Floor> _floors = [];
  Property? _property;
  int _unreadNotifications = 0;
  bool _isManager = false;

  @override
  void initState() {
    super.initState();
    _loadPropertyDetails();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _apiService.getNotifications();
      setState(() {
        _unreadNotifications = notifications.where((n) => n.status == 'pending').length;
      });
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _loadPropertyDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.getPropertyDetails(widget.property.id);
      
      setState(() {
        _property = result['property'];
        _floors = result['floors'];
        _isManager = result['is_manager'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (e.toString().contains('Session expired')) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<void> _showAddFloorDialog() async {
    final nameController = TextEditingController();
    final rentController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Floor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Floor Name',
                hintText: 'e.g., Ground Floor, First Floor',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rentController,
              decoration: const InputDecoration(
                labelText: 'Monthly Rent',
                hintText: 'Enter amount in rupees',
              ),
              keyboardType: TextInputType.number,
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
              if (nameController.text.isEmpty || rentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final rent = int.tryParse(rentController.text);
                if (rent == null) {
                  throw Exception('Invalid rent amount');
                }

                final success = await _apiService.addFloor(
                  widget.property.id,
                  nameController.text,
                  rent,
                );

                if (success) {
                  Navigator.pop(context);
                  _loadPropertyDetails();
                } else {
                  throw Exception('Failed to add floor');
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

  Future<void> _showAddTenantDialog(Floor floor) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tenant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tenant Name',
                hintText: 'Enter tenant name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter tenant phone number',
              ),
              keyboardType: TextInputType.phone,
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
              if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final success = await _apiService.addTenantToFloor(
                  widget.property.id,
                  floor.id,
                  nameController.text,
                  phoneController.text,
                );

                if (success) {
                  Navigator.pop(context);
                  _loadPropertyDetails();
                } else {
                  throw Exception('Failed to add tenant');
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

  Future<void> _showRemoveTenantDialog(Floor floor) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Tenant'),
        content: const Text('Are you sure you want to remove the tenant from this floor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final success = await _apiService.removeTenantFromFloor(
                  widget.property.id,
                  floor.id,
                );

                if (success) {
                  Navigator.pop(context);
                  _loadPropertyDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tenant removed successfully')),
                  );
                } else {
                  throw Exception('Failed to remove tenant');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUpdateFloorDialog(Floor floor) async {
    final nameController = TextEditingController(text: floor.name);
    final rentController = TextEditingController(text: floor.rent.toString());

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Floor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Floor Name',
                hintText: 'e.g., Ground Floor, First Floor',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: rentController,
              decoration: const InputDecoration(
                labelText: 'Monthly Rent',
                hintText: 'Enter amount in rupees',
              ),
              keyboardType: TextInputType.number,
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
              if (nameController.text.isEmpty || rentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                final rent = int.tryParse(rentController.text);
                if (rent == null) {
                  throw Exception('Invalid rent amount');
                }

                final success = await _apiService.updateFloor(
                  widget.property.id,
                  floor.id,
                  nameController.text,
                  rent,
                );

                if (success) {
                  Navigator.pop(context);
                  _loadPropertyDetails();
                } else {
                  throw Exception('Failed to update floor');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showTenantRequestDialog(Floor floor) {
    final phoneController = TextEditingController();
    List<String> allPhones = [];
    List<String> filteredPhones = [];
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Send Tenant Request'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          phoneController.clear();
                          setState(() {
                            filteredPhones = [];
                          });
                        },
                      ),
                    ),
                    onTap: () async {
                      if (allPhones.isEmpty) {
                        setState(() {
                          isLoading = true;
                        });
                        try {
                          allPhones = await _apiService.getUserPhones();
                          setState(() {
                            filteredPhones = allPhones;
                            isLoading = false;
                          });
                        } catch (e) {
                          setState(() {
                            isLoading = false;
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      }
                    },
                    onChanged: (value) {
                      setState(() {
                        filteredPhones = allPhones
                            .where((phone) => phone.contains(value))
                            .toList();
                      });
                    },
                  ),
                if (filteredPhones.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredPhones.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(filteredPhones[index]),
                          onTap: () {
                            phoneController.text = filteredPhones[index];
                            setState(() {
                              filteredPhones = [];
                            });
                          },
                        );
                      },
                    ),
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
                  if (phoneController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a phone number')),
                    );
                    return;
                  }

                  try {
                    final success = await _apiService.sendTenantRequest(
                      widget.property.id,
                      floor.id,
                      phoneController.text,
                    );

                    if (success) {
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tenant request sent successfully')),
                        );
                        await _loadPropertyDetails(); // Refresh property details
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      // Show error message first
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      
                      // Wait for the snackbar to be visible
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      // Then close the dialog and refresh
                      Navigator.pop(context);
                      await _loadPropertyDetails();
                    }
                  }
                },
                child: const Text('Send Request'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCancelRequestDialog(Floor floor) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this tenant request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final success = await _apiService.deleteNotification(floor.notificationId!);
                if (success) {
                  Navigator.pop(context);
                  _loadPropertyDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request cancelled successfully')),
                  );
                } else {
                  throw Exception('Failed to cancel request');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_property?.name ?? widget.property.name),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () async {
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
                          onPressed: _loadPropertyDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _floors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No floors added yet'),
                            if (_isManager) ...[
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _showAddFloorDialog,
                                child: const Text('Add First Floor'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _floors.length,
                        itemBuilder: (context, index) {
                          final floor = _floors[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: Icon(
                                floor.status == 'occupied' ? Icons.person : 
                                floor.status == 'pending' ? Icons.hourglass_empty : Icons.home,
                                color: floor.status == 'occupied' ? Colors.blue : 
                                      floor.status == 'pending' ? Colors.orange : Colors.green,
                              ),
                              title: Text(floor.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Rent: ₹${floor.rent}/month'),
                                  if (floor.tenant != null)
                                    Text('Tenant: ${floor.tenant}'),
                                  if (floor.status == 'pending')
                                    const Text('Request Pending', 
                                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: _isManager ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showUpdateFloorDialog(floor),
                                  ),
                                  if (floor.tenant != null)
                                    IconButton(
                                      icon: const Icon(Icons.person_remove, color: Colors.red),
                                      onPressed: () => _showRemoveTenantDialog(floor),
                                    )
                                  else if (floor.status == 'pending' && floor.notificationId != null)
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.orange),
                                      onPressed: () => _showCancelRequestDialog(floor),
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(Icons.person_add, color: Colors.green),
                                      onPressed: () => _showTenantRequestDialog(floor),
                                    ),
                                ],
                              ) : null,
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: _isManager ? FloatingActionButton(
        onPressed: _showAddFloorDialog,
        child: const Icon(Icons.add),
      ) : null,
    );
  }
} 