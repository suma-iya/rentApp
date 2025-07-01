import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/property.dart';
import '../services/api_service.dart';
import 'property_details_screen.dart';
import 'notifications_screen.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({Key? key}) : super(key: key);

  @override
  _PropertiesScreenState createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  int _selectedIndex = 0;
  List<Property> _managedProperties = [];
  List<Property> _tenantProperties = [];
  int _unreadNotifications = 0;

  late AnimationController _fabAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _fabAnimation;

  // Modern color schemes
  final Color _managedColor = const Color(0xFF6366F1); // Modern indigo
  final Color _tenantColor = const Color(0xFF10B981); // Modern emerald
  final Color _backgroundColor = const Color(0xFFF8FAFC);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF1E293B);
  final Color _textSecondary = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initialize();
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
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

      _listAnimationController.forward();
      if (_selectedIndex == 0) {
        _fabAnimationController.forward();
      }
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
    HapticFeedback.mediumImpact();
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _managedColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_home_rounded,
                  color: _managedColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add New Property',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new property listing to manage',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _buildModernTextField(
                controller: nameController,
                label: 'Property Name',
                hint: 'Enter property name',
                icon: Icons.home_rounded,
            ),
            const SizedBox(height: 16),
              _buildModernTextField(
              controller: addressController,
                label: 'Address',
                hint: 'Enter property address',
                icon: Icons.location_on_rounded,
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _managedColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
            onPressed: () async {
              if (nameController.text.isEmpty || addressController.text.isEmpty) {
                          _showSnackBar('Please fill all fields', isError: true);
                return;
              }

              try {
                final success = await _apiService.addProperty(
                  nameController.text,
                  addressController.text,
                );

                if (success) {
                  Navigator.pop(context);
                            _loadProperties();
                            _showSnackBar('Property added successfully');
                } else {
                  throw Exception('Failed to add property');
                }
              } catch (e) {
                          _showSnackBar('Error: $e', isError: true);
                        }
                      },
                      child: const Text(
                        'Add Property',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 16,
            color: _textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textSecondary),
            prefixIcon: Icon(icon, color: _managedColor),
            filled: true,
            fillColor: _managedColor.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _managedColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : _managedColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildManagedPropertiesFragment() {
    return _buildPropertiesFragment(
      properties: _managedProperties,
      themeColor: _managedColor,
      isManaged: true,
      emptyIcon: Icons.business_rounded,
      emptyTitle: 'No managed properties yet',
      emptySubtitle: 'Add your first property to get started',
      loadingText: 'Loading managed properties...',
    );
  }

  Widget _buildTenantPropertiesFragment() {
    return _buildPropertiesFragment(
      properties: _tenantProperties,
      themeColor: _tenantColor,
      isManaged: false,
      emptyIcon: Icons.person_rounded,
      emptyTitle: 'No tenant properties found',
      emptySubtitle: 'You\'ll see properties where you\'re a tenant here',
      loadingText: 'Loading tenant properties...',
    );
  }

  Widget _buildPropertiesFragment({
    required List<Property> properties,
    required Color themeColor,
    required bool isManaged,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required String loadingText,
  }) {
    if (_isLoading) {
      return _buildLoadingState(themeColor, loadingText);
    }

    if (_error != null) {
      return _buildErrorState(themeColor);
    }

    if (properties.isEmpty) {
      return _buildEmptyState(
        themeColor,
        emptyIcon,
        emptyTitle,
        emptySubtitle,
        isManaged,
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_backgroundColor, themeColor.withOpacity(0.02)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AnimatedBuilder(
                    animation: _listAnimationController,
                    builder: (context, child) {
                      final animationValue = Curves.easeOutCubic.transform(
                        (_listAnimationController.value - (index * 0.1))
                            .clamp(0.0, 1.0),
                      );
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - animationValue)),
                        child: Opacity(
                          opacity: animationValue,
                          child: Container(
          margin: const EdgeInsets.only(bottom: 16),
                            child: _buildModernPropertyCard(
                              properties[index],
                              themeColor,
                              isManaged,
                            ),
                          ),
                ),
              );
            },
                  );
                },
                childCount: properties.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Color themeColor, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: themeColor,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color themeColor) {
      return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProperties,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
        ),
      );
    }

  Widget _buildEmptyState(
    Color themeColor,
    IconData icon,
    String title,
    String subtitle,
    bool showAddButton,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (showAddButton) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddPropertyDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Property'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernPropertyCard(Property property, Color themeColor, bool isManaged) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: themeColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
            onTap: () {
            HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PropertyDetailsScreen(property: property),
                ),
              );
            },
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Hero(
                  tag: 'property_${property.id}',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeColor.withOpacity(0.2),
                          themeColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isManaged ? Icons.business_rounded : Icons.person_rounded,
                      color: themeColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeColor.withOpacity(0.2),
                              themeColor.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isManaged ? 'Managed Property' : 'Tenant Property',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: themeColor,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _selectedIndex == 0 ? _managedColor : _tenantColor;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Managed Properties' : 'Tenant Properties',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: currentColor,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                onPressed: () async {
                  HapticFeedback.lightImpact();
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
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
          ),
        ],
      ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.red.shade500,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Are you sure you want to logout?',
                          style: TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (shouldLogout == true) {
                await _apiService.clearSessionToken();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildManagedPropertiesFragment(),
                      _buildTenantPropertiesFragment(),
                    ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton.extended(
              onPressed: _showAddPropertyDialog,
                backgroundColor: _managedColor,
                foregroundColor: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add Property',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
          setState(() {
            _selectedIndex = index;
          });
            if (index == 0) {
              _fabAnimationController.forward();
            } else {
              _fabAnimationController.reverse();
            }
        },
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: currentColor.withOpacity(0.15),
          destinations: [
          NavigationDestination(
              icon: Icon(Icons.business_rounded, color: _managedColor.withOpacity(0.6)),
              selectedIcon: Icon(Icons.business_rounded, color: _managedColor),
            label: 'Managed',
          ),
          NavigationDestination(
              icon: Icon(Icons.person_rounded, color: _tenantColor.withOpacity(0.6)),
              selectedIcon: Icon(Icons.person_rounded, color: _tenantColor),
            label: 'Tenant',
          ),
        ],
        ),
      ),
    );
  }
}