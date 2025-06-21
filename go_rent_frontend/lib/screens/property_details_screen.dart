import 'package:flutter/material.dart';
import '../models/property.dart';
import '../models/floor.dart';
import '../services/api_service.dart';
import 'notifications_screen.dart';
import 'pending_payment_notifications_screen.dart';

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
    _apiService.loadCurrentUserId().then((_) {
      setState(() {}); // Rebuild to update UI with loaded userId
    });
    _loadPropertyDetails();
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

  Future<void> _showSendPaymentDialog(Floor floor) async {
    final amountController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Payment Notification'),
        content: TextField(
          controller: amountController,
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter payment amount',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              try {
                await _apiService.sendPaymentNotification(
                  propertyId: widget.property.id,
                  floorId: floor.id,
                  amount: amount,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment notification sent!')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Send'),
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
                          // DEBUG: Print tenant and currentUserId
                          // ignore: avoid_print
                          print('floor.tenant: \\${floor.tenant} (type: \\${floor.tenant.runtimeType}), currentUserId: \\${_apiService.currentUserId} (type: \\${_apiService.currentUserId.runtimeType})');
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    floor.status == 'occupied' ? Icons.person : 
                                    floor.status == 'pending' ? Icons.home : Icons.home,
                                    color: floor.status == 'occupied' ? Colors.blue : 
                                          floor.status == 'pending' ? Colors.green : Colors.green,
                                  ),
                                  title: Text(floor.name),
                                  subtitle: Column(
                                    
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Rent: ₹${floor.rent}/month'),
                                      if (floor.tenant != null)
                                        Text('Tenant: ${floor.tenant}'),
                                      if (floor.status == 'pending')
                                        Row(
                                          children: [
                                            const Text('Request Pending', 
                                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                            if (floor.tenant != null && floor.tenant == _apiService.currentUserId) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.touch_app, size: 16, color: Colors.orange),
                                              const Text('Tap to view', 
                                                style: TextStyle(color: Colors.orange, fontSize: 12)),
                                            ],
                                          ],
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    // If tenant and status is pending, navigate to pending payment notifications
                                    if (floor.status == 'pending' && 
                                        floor.tenant != null && 
                                        floor.tenant == _apiService.currentUserId) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PendingPaymentNotificationsScreen(
                                            property: widget.property,
                                            floor: floor,
                                          ),
                                        ),
                                      );
                                    }
                                  },
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
                                // Payment notification button for tenants
                                if (floor.tenant != null && floor.tenant == _apiService.currentUserId)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.payment),
                                        label: const Text('Send Payment Notification'),
                                        onPressed: () {
                                          _showSendPaymentDialog(floor);
                                        },
                                      ),
                                    ),
                                  ),
                              ],
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