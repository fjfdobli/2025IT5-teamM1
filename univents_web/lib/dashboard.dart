import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0; // Set default to Home tab (index 0)
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniVents Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation rail for desktop
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.business),
                label: Text('Organizations'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event),
                label: Text('Events'),
              ),
            ],
          ),

          // Content area
          Expanded(
            child:
                _selectedIndex == 0
                    ? const HomeTab()
                    : _selectedIndex == 1
                    ? const OrganizationsTab()
                    : const EventsTab(),
          ),
        ],
      ),
    );
  }
}

// Home tab for main dashboard overview
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UniVents Dashboard',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildDashboardCard(
                  context,
                  'Organizations',
                  Icons.business,
                  Colors.blue.shade100,
                  'Manage university organizations',
                  () {
                    // Navigate to Organizations tab
                    (context.findAncestorStateOfType<_DashboardScreenState>())
                        ?.setState(() {
                          (context
                                  .findAncestorStateOfType<
                                    _DashboardScreenState
                                  >())
                              ?._selectedIndex = 1;
                        });
                  },
                ),
                _buildDashboardCard(
                  context,
                  'Events',
                  Icons.event,
                  Colors.green.shade100,
                  'Manage campus events',
                  () {
                    // Navigate to Events tab
                    (context.findAncestorStateOfType<_DashboardScreenState>())
                        ?.setState(() {
                          (context
                                  .findAncestorStateOfType<
                                    _DashboardScreenState
                                  >())
                              ?._selectedIndex = 2;
                        });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Organization tab for CRUD operations
class OrganizationsTab extends StatefulWidget {
  const OrganizationsTab({super.key});

  @override
  State<OrganizationsTab> createState() => _OrganizationsTabState();
}

class _OrganizationsTabState extends State<OrganizationsTab> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _organizations = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  // Load organizations from Supabase
  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch organizations from Supabase
      final response = await supabase
          .from('organizations')
          .select('*')
          .order('name');

      setState(() {
        _organizations = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading organizations: $e';
        _isLoading = false;
      });
      print('Error loading organizations: $e');
    }
  }

  // Add organization to Supabase
  Future<void> _addOrganization(Map<String, dynamic> newOrganization) async {
    try {
      // Insert organization into Supabase
      final response =
          await supabase.from('organizations').insert(newOrganization).select();

      if (response.isNotEmpty) {
        setState(() {
          _organizations.add(response[0]);
        });

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Organization added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding organization: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding organization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update organization in Supabase
  Future<void> _updateOrganization(
    Map<String, dynamic> updatedOrganization,
  ) async {
    try {
      // Get the ID for the update
      final id = updatedOrganization['uid'];

      // Ensure the status is one of the valid values if it exists
      if (updatedOrganization['status'] != null) {
        final status = updatedOrganization['status'].toString();

        // Make sure status is one of the valid values
        if (!['active', 'deactivated'].contains(status)) {
          updatedOrganization['status'] =
              'active'; // Default to active if invalid
          print('Invalid status detected, defaulting to active');
        }
      }

      print(
        'Updating organization with full data: ${updatedOrganization['name']}',
      );

      // Perform the update with all fields
      await supabase
          .from('organizations')
          .update(updatedOrganization)
          .eq('uid', id);

      // Refresh the organizations list after update
      _loadOrganizations();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating organization: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating organization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Toggle organization status using the SQL function
  Future<void> _toggleOrganizationStatus(String orgUid) async {
    try {
      print('Toggling status for organization: $orgUid');

      // First get the current organization to check its status
      final response =
          await supabase
              .from('organizations')
              .select('*') // Get all fields to provide complete data on update
              .eq('uid', orgUid)
              .single();

      print('Current organization data: $response');

      // Determine the new status based on constraint values in the database
      // Database constraint: status = ANY (ARRAY['active'::text, 'deactivated'::text])
      final currentStatus = response['status'] as String? ?? 'active';
      final newStatus = currentStatus == 'active' ? 'deactivated' : 'active';

      print('Current status: $currentStatus, New status: $newStatus');

      // Update only the status field
      await supabase
          .from('organizations')
          .update({'status': newStatus})
          .eq('uid', orgUid);

      print('Successfully updated status to: $newStatus');

      // Refresh the organizations list
      _loadOrganizations();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error toggling organization status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling organization status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update the local list
  Future<void> _updateLocalOrganization(
    String id,
    Map<String, dynamic> updatedOrganization,
  ) async {
    try {
      setState(() {
        // Support both id and uid for compatibility during transition
        final index = _organizations.indexWhere(
          (org) => (org['id'] ?? org['uid']) == id,
        );
        if (index != -1) {
          _organizations[index] = updatedOrganization;
        }
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating organization: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating organization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete organization from Supabase
  Future<void> _deleteOrganization(String id) async {
    try {
      // Delete organization from Supabase using correct column name (uid)
      await supabase.from('organizations').delete().eq('uid', id);

      // Update the local list
      setState(() {
        // Support both id and uid for compatibility during transition
        _organizations.removeWhere((org) => (org['id'] ?? org['uid']) == id);
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Organization deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting organization: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting organization: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Upload organization logo to Supabase Storage
  Future<String?> _uploadOrganizationLogo(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      // Check if bucket exists, create if not
      try {
        await supabase.storage.getBucket('organization-logos');
      } catch (e) {
        // Bucket does not exist, create it
        try {
          await supabase.storage.createBucket(
            'organization-logos',
            const BucketOptions(
              public: true, // 5MB limit
            ),
          );
          print('Created organization-logos bucket');
        } catch (createError) {
          print('Error creating bucket: $createError');
          // Continue anyway as the error might be because the bucket already exists
        }
      }

      final fileExt = fileName.split('.').last;
      final filePath =
          'organization-logos/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to Supabase Storage
      await supabase.storage
          .from('organization-logos')
          .uploadBinary(filePath, imageBytes);

      // Get public URL
      final response = supabase.storage
          .from('organization-logos')
          .getPublicUrl(filePath);

      return response;
    } catch (e) {
      print('Error uploading logo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // File picker for image upload
  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;

        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading image...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        String? fileUrl;
        if (file.bytes != null) {
          // For web platform
          fileUrl = await _uploadOrganizationLogo(file.bytes!, fileName);
        }

        if (fileUrl != null) {
          controller.text = fileUrl;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking/uploading file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Organizations',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Organization'),
                onPressed: () => _showAddOrganizationDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage.isNotEmpty)
            Expanded(child: Center(child: Text(_errorMessage)))
          else if (_organizations.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No organizations found. Add your first organization!',
                ),
              ),
            )
          else
            Expanded(child: _buildOrganizationGrid()),
        ],
      ),
    );
  }

  Widget _buildOrganizationGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount =
            width < 600
                ? 1
                : width < 900
                ? 2
                : 3;

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _organizations.length,
          itemBuilder: (context, index) {
            final organization = _organizations[index];
            return _buildOrganizationCard(organization);
          },
        );
      },
    );
  }

  Widget _buildOrganizationCard(Map<String, dynamic> organization) {
    bool isVisible =
        organization['status'] == 'active'; // Only active is visible

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      // Add a colored border to indicate visibility status
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: !isVisible ? Colors.red.shade300 : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showOrganizationDetails(organization);
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo or placeholder
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            organization['logo'] != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    organization['logo'],
                                    fit: BoxFit.cover,
                                    // Add additional headers for CORS handling
                                    headers: const {
                                      'Access-Control-Allow-Origin': '*',
                                    },
                                    loadingBuilder: (
                                      context,
                                      child,
                                      loadingProgress,
                                    ) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                  : null,
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading logo: $error');
                                      // Check if URL is from Google search and replace with placeholder
                                      if (organization['logo'] != null &&
                                          organization['logo']
                                              .toString()
                                              .contains('google.com/url')) {
                                        // Update with a placeholder directly in the UI only
                                        // We'll handle actual DB updates when the user saves
                                      }
                                      return Center(
                                        child: Icon(
                                          Icons.business,
                                          size: 30,
                                          color: Colors.indigo[300],
                                        ),
                                      );
                                    },
                                  ),
                                )
                                : Center(
                                  child: Icon(
                                    Icons.business,
                                    size: 30,
                                    color: Colors.indigo[300],
                                  ),
                                ),
                      ),
                      const SizedBox(width: 16),
                      // Organization name and type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              organization['name'] ?? 'Unnamed Organization',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              organization['category'] ??
                                  organization['type'] ??
                                  'Category not specified',
                              style: TextStyle(color: Colors.grey[700]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Expanded(
                    child: Text(
                      organization['description'] ?? 'No description available',
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Contact info
                  if (organization['email'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            organization['email'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Visibility indicator
            if (!isVisible)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_off, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Hidden',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOrganizationDetails(Map<String, dynamic> organization) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxWidth: 700,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          organization['name'] ?? 'Organization Details',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo
                            if (organization['logo'] != null)
                              Center(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      organization['logo'],
                                      fit: BoxFit.cover,
                                      headers: const {
                                        'Access-Control-Allow-Origin': '*',
                                      },
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                          ),
                                        );
                                      },
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        print(
                                          'Error loading logo in dialog: $error',
                                        );
                                        // Check for Google search URLs in the dialog preview
                                        // We don't have direct access to the controller here, so we'll just
                                        // show a placeholder in the UI
                                        return Center(
                                          child: Icon(
                                            Icons.business,
                                            size: 60,
                                            color: Colors.indigo[300],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              )
                            else
                              Center(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.business,
                                      size: 60,
                                      color: Colors.indigo[300],
                                    ),
                                  ),
                                ),
                              ),

                            _buildDetailRow(
                              'Name',
                              organization['name'] ?? 'Not specified',
                            ),
                            _buildDetailRow(
                              'Acronym',
                              organization['acronym'] ?? 'Not specified',
                            ),
                            _buildDetailRow(
                              'Category',
                              organization['category'] ??
                                  organization['type'] ??
                                  'Not specified',
                            ),
                            _buildDetailRow(
                              'Contact Email',
                              organization['email'] ?? 'Not specified',
                            ),
                            // Add new fields for mobile and facebook
                            if (organization['mobile'] != null &&
                                organization['mobile'].toString().isNotEmpty)
                              _buildDetailRow('Mobile', organization['mobile']),
                            if (organization['facebook'] != null &&
                                organization['facebook'].toString().isNotEmpty)
                              _buildDetailRow(
                                'Facebook',
                                organization['facebook'],
                              ),
                            // Add visibility status information
                            _buildDetailRow(
                              'Status',
                              organization['status'] == 'deactivated'
                                  ? 'Deactivated (not visible in mobile app)'
                                  : 'Active (visible to all users)',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Actions
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showDeleteOrganizationDialog(organization);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                        const SizedBox(width: 8),
                        // Toggle visibility button
                        ElevatedButton.icon(
                          icon: Icon(
                            organization['status'] == 'deactivated'
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          label: Text(
                            organization['status'] == 'deactivated'
                                ? 'Activate'
                                : 'Deactivate',
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            // Show loading indicator
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Updating status...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                            // Toggle visibility
                            _toggleOrganizationStatus(organization['uid']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                organization['status'] == 'deactivated'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                            foregroundColor:
                                organization['status'] == 'deactivated'
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditOrganizationDialog(organization);
                          },
                          child: const Text('Edit Organization'),
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

  void _showDeleteOrganizationDialog(Map<String, dynamic> organization) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Organization'),
            content: Text(
              'Are you sure you want to delete "${organization['name']}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _deleteOrganization(
                    organization['id'] ?? organization['uid'],
                  );
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showAddOrganizationDialog() {
    // Create empty text editing controllers
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final acronymController = TextEditingController();
    final emailController = TextEditingController();
    final mobileController = TextEditingController();
    final facebookController = TextEditingController();
    final logoUrlController = TextEditingController();

    // Status dropdown value
    // Use valid values matching the constraint: 'active', 'inactive', 'archived'
    String selectedStatus = 'active';

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  clipBehavior: Clip.antiAlias,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    constraints: BoxConstraints(
                      maxWidth: 700,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Add Organization',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name field
                                    TextFormField(
                                      controller: nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Organization Name',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter organization name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Acronym field
                                    TextFormField(
                                      controller: acronymController,
                                      decoration: const InputDecoration(
                                        labelText: 'Acronym',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter organization acronym';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Category field (renamed from Type)
                                    DropdownButtonFormField<String>(
                                      value:
                                          categoryController.text.isEmpty
                                              ? null
                                              : categoryController.text,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'academic',
                                          child: Text('Academic'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'sports',
                                          child: Text('Sports'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'arts',
                                          child: Text('Arts'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'cultural',
                                          child: Text('Cultural'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'religious',
                                          child: Text('Religious'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'social',
                                          child: Text('Social'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'technology',
                                          child: Text('Technology'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'other',
                                          child: Text('Other'),
                                        ),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select an organization category';
                                        }
                                        return null;
                                      },
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          categoryController.text = newValue;
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Email field
                                    TextFormField(
                                      controller: emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Contact Email',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter contact email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Mobile field (optional)
                                    TextFormField(
                                      controller: mobileController,
                                      decoration: const InputDecoration(
                                        labelText: 'Mobile Number (Optional)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Facebook field (optional)
                                    TextFormField(
                                      controller: facebookController,
                                      decoration: const InputDecoration(
                                        labelText: 'Facebook (Optional)',
                                        border: OutlineInputBorder(),
                                        hintText:
                                            'Facebook page URL or username',
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Logo URL field with upload button
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: logoUrlController,
                                            decoration: const InputDecoration(
                                              labelText: 'Logo URL',
                                              border: OutlineInputBorder(),
                                              helperText:
                                                  'Enter URL or upload an image',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.upload),
                                          label: const Text('Upload'),
                                          onPressed:
                                              () => _pickAndUploadImage(
                                                logoUrlController,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Status dropdown
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: selectedStatus,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'active',
                                          child: Text('Active (Visible)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'deactivated',
                                          child: Text('Deactivated (Hidden)'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedStatus = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Actions
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      // Create new organization map
                                      final newOrganization = {
                                        'name': nameController.text,
                                        'acronym': acronymController.text,
                                        'category': categoryController.text,
                                        'email': emailController.text,
                                        'mobile':
                                            mobileController.text.isNotEmpty
                                                ? mobileController.text
                                                : null,
                                        'facebook':
                                            facebookController.text.isNotEmpty
                                                ? facebookController.text
                                                : null,
                                        'logo':
                                            logoUrlController.text.isNotEmpty
                                                ? logoUrlController.text
                                                : null,
                                        'status': selectedStatus,
                                      };

                                      // Add the organization
                                      _addOrganization(newOrganization);

                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text('Add Organization'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showEditOrganizationDialog(Map<String, dynamic> organization) {
    // Create text editing controllers initialized with current values
    final nameController = TextEditingController(
      text: organization['name'] ?? '',
    );
    final categoryController = TextEditingController(
      text: organization['category'] ?? organization['type'] ?? '',
    );
    final acronymController = TextEditingController(
      text: organization['acronym'] ?? '',
    );
    final emailController = TextEditingController(
      text: organization['email'] ?? '',
    );
    final mobileController = TextEditingController(
      text: organization['mobile'] ?? '',
    );
    final facebookController = TextEditingController(
      text: organization['facebook'] ?? '',
    );
    final logoUrlController = TextEditingController(
      text: organization['logo'] ?? '',
    );

    // Initialize status with valid value
    String selectedStatus = organization['status'] ?? 'active';

    // Ensure status is one of the valid values for the constraint
    if (!['active', 'deactivated'].contains(selectedStatus)) {
      selectedStatus = 'active'; // Default to active if invalid
    }

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  clipBehavior: Clip.antiAlias,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    constraints: BoxConstraints(
                      maxWidth: 700,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Edit Organization',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Logo preview (optional)
                                    if (organization['logo'] != null)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 24.0,
                                          ),
                                          child: Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.network(
                                                organization['logo'],
                                                fit: BoxFit.cover,
                                                headers: const {
                                                  'Access-Control-Allow-Origin':
                                                      '*',
                                                },
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  print(
                                                    'Error loading logo in edit dialog: $error',
                                                  );
                                                  // Check for Google search URLs
                                                  if (organization['logo'] !=
                                                          null &&
                                                      organization['logo']
                                                          .toString()
                                                          .contains(
                                                            'google.com/url',
                                                          )) {
                                                    // Just display a placeholder in the UI
                                                    // We don't have direct access to edit controllers here
                                                  }
                                                  return Center(
                                                    child: Icon(
                                                      Icons.business,
                                                      size: 60,
                                                      color: Colors.indigo[300],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Name field
                                    TextFormField(
                                      controller: nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Organization Name',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter organization name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Acronym field
                                    TextFormField(
                                      controller: acronymController,
                                      decoration: const InputDecoration(
                                        labelText: 'Acronym',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter organization acronym';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Category field (renamed from Type)
                                    DropdownButtonFormField<String>(
                                      value:
                                          categoryController.text.isEmpty
                                              ? null
                                              : categoryController.text,
                                      decoration: const InputDecoration(
                                        labelText: 'Category',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'academic',
                                          child: Text('Academic'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'sports',
                                          child: Text('Sports'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'arts',
                                          child: Text('Arts'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'cultural',
                                          child: Text('Cultural'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'religious',
                                          child: Text('Religious'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'social',
                                          child: Text('Social'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'technology',
                                          child: Text('Technology'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'other',
                                          child: Text('Other'),
                                        ),
                                      ],
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select an organization category';
                                        }
                                        return null;
                                      },
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          categoryController.text = newValue;
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Email field
                                    TextFormField(
                                      controller: emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Contact Email',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter contact email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email address';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Mobile field (optional)
                                    TextFormField(
                                      controller: mobileController,
                                      decoration: const InputDecoration(
                                        labelText: 'Mobile Number (Optional)',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Facebook field (optional)
                                    TextFormField(
                                      controller: facebookController,
                                      decoration: const InputDecoration(
                                        labelText: 'Facebook (Optional)',
                                        border: OutlineInputBorder(),
                                        hintText:
                                            'Facebook page URL or username',
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Logo URL field with upload button
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: logoUrlController,
                                            decoration: const InputDecoration(
                                              labelText: 'Logo URL',
                                              border: OutlineInputBorder(),
                                              helperText:
                                                  'Enter URL or upload a new image',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.upload),
                                          label: const Text('Upload'),
                                          onPressed:
                                              () => _pickAndUploadImage(
                                                logoUrlController,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Status dropdown
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: selectedStatus,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'active',
                                          child: Text('Active (Visible)'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'deactivated',
                                          child: Text('Deactivated (Hidden)'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedStatus = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Actions
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      // Create updated organization map
                                      final updatedOrganization = {
                                        'uid':
                                            organization['id'] ??
                                            organization['uid'], // Keep the same ID, using correct column name
                                        'name': nameController.text,
                                        'acronym': acronymController.text,
                                        'category': categoryController.text,
                                        'email': emailController.text,
                                        'mobile':
                                            mobileController.text.isNotEmpty
                                                ? mobileController.text
                                                : null,
                                        'facebook':
                                            facebookController.text.isNotEmpty
                                                ? facebookController.text
                                                : null,
                                        'logo':
                                            logoUrlController.text.isNotEmpty
                                                ? logoUrlController.text
                                                : null,
                                        'status': selectedStatus,
                                      };

                                      // Update the organization
                                      _updateOrganization(updatedOrganization);

                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text('Save Changes'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

// Events tab for CRUD operations
class EventsTab extends StatefulWidget {
  const EventsTab({super.key});

  @override
  State<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<EventsTab> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];
  String _errorMessage = '';
  String _validOrgId = ''; // Store a valid organization ID for new events

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadFirstOrganization(); // Get a valid organization ID for new events
  }

  // Load first organization to get a valid ID
  Future<void> _loadFirstOrganization() async {
    try {
      // Fetch the first organization from the database
      final response = await supabase
          .from('organizations')
          .select('uid')
          .limit(1);

      if (response.isNotEmpty) {
        setState(() {
          _validOrgId = response[0]['uid'];
          print('Found valid organization ID: $_validOrgId');
        });
      } else {
        print('No organizations found in database');
      }
    } catch (e) {
      print('Error loading organizations: $e');
    }
  }

  // Load events from Supabase

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch events from Supabase without specifying any order
      // Since we don't know for sure which columns exist
      final response = await supabase
          .from('events')
          .select('*, organizations(*)');

      setState(() {
        _events = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading events: $e';
        _isLoading = false;
      });
      print('Error loading events: $e');
    }
  }

  // Add event to Supabase
  Future<void> _addEvent(Map<String, dynamic> newEvent) async {
    try {
      // Insert event into Supabase
      final response = await supabase.from('events').insert(newEvent).select();

      if (response.isNotEmpty) {
        // Fetch the full event with organization details
        final fullEvent =
            await supabase
                .from('events')
                .select('*, organizations(*)')
                .eq('id', response[0]['id'])
                .single();

        setState(() {
          _events.add(fullEvent);
        });

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding event: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update event in Supabase
  Future<void> _updateEvent(Map<String, dynamic> updatedEvent) async {
    try {
      // Update event in Supabase using the correct column name (uid, not id)
      final id = updatedEvent['uid'];

      // Create a copy without the id field to avoid primary key updates
      final updateData = Map<String, dynamic>.from(updatedEvent);
      updateData.remove('id'); // Remove id if present to avoid conflicts

      await supabase.from('events').update(updateData).eq('uid', id);

      // Fetch the updated event with organization details
      final fullEvent =
          await supabase
              .from('events')
              .select('*, organizations(*)')
              .eq('uid', id)
              .single();

      // Update the local list
      setState(() {
        final index = _events.indexWhere((event) => event['uid'] == id);
        if (index != -1) {
          _events[index] = fullEvent;
        }
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating event: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete event from Supabase
  Future<void> _deleteEvent(String id) async {
    try {
      // Delete event from Supabase using the correct column name (uid, not id)
      await supabase.from('events').delete().eq('uid', id);

      // Update the local list
      setState(() {
        _events.removeWhere((event) => event['uid'] == id);
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error deleting event: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting event: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Get attendees for an event from Supabase
  Future<List<Map<String, dynamic>>> _getEventAttendees(String eventId) async {
    try {
      // Check if eventId is valid
      if (eventId.isEmpty) {
        return []; // Return empty array instead of null
      }

      // Fetch attendees from Supabase using the correct column name (eventid, not event_id)
      final response = await supabase
          .from('event_attendees')
          .select('*, accounts(*)')
          .eq('eventid', eventId);

      return response;
    } catch (e) {
      print('Error fetching attendees: $e');
      return [];
    }
  }

  // Upload event banner to Supabase Storage
  Future<String?> _uploadEventBanner(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final fileExt = fileName.split('.').last;
      final filePath =
          'event-banners/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to Supabase Storage
      await supabase.storage
          .from('event-banners')
          .uploadBinary(filePath, imageBytes);

      // Get public URL
      final response = supabase.storage
          .from('event-banners')
          .getPublicUrl(filePath);

      return response;
    } catch (e) {
      print('Error uploading banner: $e');
      return null;
    }
  }

  // File picker for image upload
  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;

        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading image...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        String? fileUrl;
        if (file.bytes != null) {
          // For web platform
          fileUrl = await _uploadEventBanner(file.bytes!, fileName);
        }

        if (fileUrl != null) {
          controller.text = fileUrl;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking/uploading file: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Events List',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Event'),
                onPressed: () => _showAddEventDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage.isNotEmpty)
            Expanded(child: Center(child: Text(_errorMessage)))
          else if (_events.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No events found. Add your first event!'),
              ),
            )
          else
            Expanded(child: _buildEventGrid()),
        ],
      ),
    );
  }

  Widget _buildEventGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount =
            width < 600
                ? 1
                : width < 900
                ? 2
                : 3;

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 16.0), // Add bottom padding
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.4, // Adjusted for better fit
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _events.length,
          itemBuilder: (context, index) {
            final event = _events[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    bool isVisible =
        event['status'] == 'active' || event['status'] == 'completed';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      // Add a colored border to indicate visibility status
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: !isVisible ? Colors.red.shade300 : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          _showEventDetails(event);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child:
                      event['banner'] != null
                          ? Image.network(
                            event['banner'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              // Check if the URL is from Google search results and replace with a safe placeholder
                              if (event['banner'] != null &&
                                  event['banner'].toString().contains(
                                    'google.com/url',
                                  )) {
                                // Just display a placeholder in the UI
                                // We'll handle database updates elsewhere
                              }
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          )
                          : Container(
                            color: Colors.indigo[100],
                            child: const Center(
                              child: Icon(Icons.event, size: 50),
                            ),
                          ),
                ),
                // Visibility indicator
                if (!isVisible)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Hidden',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? 'Unnamed Event',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event['location'] ?? 'Location not specified',
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  // Show event attendees dialog
  void _showEventAttendees(Map<String, dynamic> event) async {
    setState(() {
      _isLoading = true;
    });

    // Add null check to avoid crashes - using the correct column name (uid, not id)
    String? eventId = event['uid'] as String?;
    if (eventId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot view attendees: Event ID is missing'),
        ),
      );
      return;
    }

    final attendees = await _getEventAttendees(eventId);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxWidth: 700,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Attendees: ${event['title']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Content - Attendees List
                  Expanded(
                    child:
                        attendees.isEmpty
                            ? const Center(child: Text('No attendees yet'))
                            : ListView.builder(
                              itemCount: attendees.length,
                              itemBuilder: (context, index) {
                                final attendee = attendees[index];
                                final account = attendee['accounts'] ?? {};
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      (account['firstname'] ?? 'U').substring(
                                        0,
                                        1,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    '${account['firstname'] ?? ''} ${account['lastname'] ?? ''}',
                                  ),
                                  subtitle: Text(account['email'] ?? ''),
                                  trailing: Text(
                                    'Joined: ${attendee['created_at'] ?? 'Unknown'}',
                                  ),
                                );
                              },
                            ),
                  ),

                  // Actions
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
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

  void _showEventDetails(Map<String, dynamic> event) {
    final organization = event['organizations'] ?? {};

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              constraints: BoxConstraints(
                maxWidth: 700,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event['title'] ?? 'Event Details',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event['banner'] != null)
                            Container(
                              constraints: const BoxConstraints(maxHeight: 300),
                              width: double.infinity,
                              child: Image.network(
                                event['banner'],
                                fit: BoxFit.cover,
                                headers: const {
                                  'Access-Control-Allow-Origin': '*',
                                },
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                    'Error loading image in dialog: $error',
                                  );
                                  // Check for Google search URLs in the preview
                                  // We don't have direct access to the controller, just show a placeholder
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 8),
                                          Text('Image could not be loaded'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  'Organization',
                                  organization['name'] ?? 'Not specified',
                                ),
                                _buildDetailRow(
                                  'Location',
                                  event['location'] ?? 'Not specified',
                                ),
                                _buildDetailRow(
                                  'Description',
                                  event['description'] ?? 'No description',
                                ),
                                _buildDetailRow(
                                  'Type',
                                  event['type'] ?? 'Not specified',
                                ),
                                _buildDetailRow(
                                  'Tags',
                                  event['tag'] ?? 'No tags',
                                ),
                                _buildDetailRow(
                                  'Start Date',
                                  event['datetimestart'] != null
                                      ? _formatDate(event['datetimestart'])
                                      : 'Not specified',
                                ),
                                _buildDetailRow(
                                  'End Date',
                                  event['datetimeend'] != null
                                      ? _formatDate(event['datetimeend'])
                                      : 'Not specified',
                                ),
                                // Add visibility status information
                                _buildDetailRow(
                                  'Status',
                                  event['status'] == 'inactive'
                                      ? 'Inactive (not visible in mobile app)'
                                      : event['status'] == 'cancelled'
                                      ? 'Cancelled'
                                      : event['status'] == 'completed'
                                      ? 'Completed'
                                      : 'Active (visible to all users)',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showDeleteEventDialog(event);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                        const SizedBox(width: 8),
                        // Toggle visibility button
                        ElevatedButton.icon(
                          icon: Icon(
                            event['status'] == 'inactive'
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          label: Text(
                            event['status'] == 'inactive'
                                ? 'Activate'
                                : 'Deactivate',
                          ),
                          onPressed: () {
                            Navigator.pop(context);

                            // Toggle visibility
                            final updatedEvent = {...event};
                            // Remove organization object before update to avoid circular references
                            updatedEvent.remove('organizations');

                            // Update timestamps to proper format
                            try {
                              if (updatedEvent['datetimestart'] != null) {
                                final startDate = DateTime.parse(
                                  updatedEvent['datetimestart'],
                                );
                                updatedEvent['datetimestart'] =
                                    startDate.toIso8601String();
                              }

                              if (updatedEvent['datetimeend'] != null) {
                                final endDate = DateTime.parse(
                                  updatedEvent['datetimeend'],
                                );
                                updatedEvent['datetimeend'] =
                                    endDate.toIso8601String();
                              }
                            } catch (e) {
                              print(
                                'Error parsing dates during status toggle: $e',
                              );
                            }

                            // Use valid status values per schema constraints
                            updatedEvent['status'] =
                                event['status'] == 'inactive'
                                    ? 'active'
                                    : 'inactive';

                            // Events status can be: 'active', 'inactive', 'cancelled', 'completed'
                            _updateEvent(updatedEvent);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                event['status'] == 'inactive'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                            foregroundColor:
                                event['status'] == 'inactive'
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // View attendees button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.people),
                          label: const Text('View Attendees'),
                          onPressed: () {
                            Navigator.pop(context);
                            _showEventAttendees(event);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade100,
                            foregroundColor: Colors.indigo.shade800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showEditEventDialog(event);
                          },
                          child: const Text('Edit Event'),
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

  // Helper method to format dates for display
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  void _showDeleteEventDialog(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Event'),
            content: Text(
              'Are you sure you want to delete "${event['title']}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _deleteEvent(event['uid']); // Using the correct column name
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showAddEventDialog() {
    // Create empty text editing controllers
    final titleController = TextEditingController();
    final typeController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    final bannerUrlController = TextEditingController();
    final orgIdController = TextEditingController();
    // Tag controller removed as tag field doesn't exist in database

    // Status is used for visibility (hidden/visible)
    // Use valid event status values: 'active', 'inactive', 'cancelled', 'completed'
    String selectedStatus = 'active'; // default to active

    // Date controllers
    final startDateController = TextEditingController();
    final endDateController = TextEditingController();

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  clipBehavior: Clip.antiAlias,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    constraints: BoxConstraints(
                      maxWidth: 700,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Add Event',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title field
                                    TextFormField(
                                      controller: titleController,
                                      decoration: const InputDecoration(
                                        labelText: 'Event Title',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter event title';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Location field
                                    TextFormField(
                                      controller: locationController,
                                      decoration: const InputDecoration(
                                        labelText: 'Location',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter event location';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Event Type field - changed to dropdown to ensure valid types
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Event Type',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: typeController.text.isEmpty ? 'academic' : typeController.text,
                                      items: const [
                                        DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
                                        DropdownMenuItem(value: 'seminar', child: Text('Seminar')),
                                        DropdownMenuItem(value: 'conference', child: Text('Conference')),
                                        DropdownMenuItem(value: 'meetup', child: Text('Meetup')),
                                        DropdownMenuItem(value: 'party', child: Text('Party')),
                                        DropdownMenuItem(value: 'sports', child: Text('Sports')),
                                        DropdownMenuItem(value: 'concert', child: Text('Concert')),
                                        DropdownMenuItem(value: 'exhibition', child: Text('Exhibition')),
                                        DropdownMenuItem(value: 'competition', child: Text('Competition')),
                                        DropdownMenuItem(value: 'academic', child: Text('Academic')),
                                        DropdownMenuItem(value: 'social', child: Text('Social')),
                                        DropdownMenuItem(value: 'cultural', child: Text('Cultural')),
                                        DropdownMenuItem(value: 'other', child: Text('Other')),
                                      ],
                                      onChanged: (value) {
                                        typeController.text = value!;
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select an event type';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Tag field removed as it doesn't exist in the database

                                    // Organization ID field - hidden from UI but controller still used
                                    

                                    // Start Date field
                                    TextFormField(
                                      controller: startDateController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Start Date (YYYY-MM-DD HH:MM:SS)',
                                        border: OutlineInputBorder(),
                                        helperText:
                                            'Format: 2025-05-01 14:30:00',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter start date';
                                        }
                                        try {
                                          DateTime.parse(value);
                                        } catch (e) {
                                          return 'Invalid date format. Use YYYY-MM-DD HH:MM:SS';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // End Date field
                                    TextFormField(
                                      controller: endDateController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'End Date (YYYY-MM-DD HH:MM:SS)',
                                        border: OutlineInputBorder(),
                                        helperText:
                                            'Format: 2025-05-01 16:30:00',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter end date';
                                        }
                                        try {
                                          DateTime.parse(value);
                                        } catch (e) {
                                          return 'Invalid date format. Use YYYY-MM-DD HH:MM:SS';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Banner URL field
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: bannerUrlController,
                                            decoration: const InputDecoration(
                                              labelText: 'Banner Image URL',
                                              border: OutlineInputBorder(),
                                              helperText:
                                                  'Enter the full URL to the event banner image',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.upload),
                                          label: const Text('Upload'),
                                          onPressed:
                                              () => _pickAndUploadImage(
                                                bannerUrlController,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Description field
                                    TextFormField(
                                      controller: descriptionController,
                                      decoration: const InputDecoration(
                                        labelText: 'Description',
                                        border: OutlineInputBorder(),
                                        alignLabelWithHint: true,
                                      ),
                                      maxLines: 5,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter event description';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Status dropdown (for visibility)
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: selectedStatus,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'active',
                                          child: Text('Active'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'inactive',
                                          child: Text('Inactive'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'cancelled',
                                          child: Text('Cancelled'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'completed',
                                          child: Text('Completed'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedStatus = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Actions
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      // Create new event map with only essential fields
                                      // Simplified to match the actual database schema
                                      // Format timestamps correctly for PostgreSQL
                                      String formattedStartDate;
                                      String formattedEndDate;

                                      try {
                                        // Try to parse and format the date correctly
                                        final startDate = DateTime.parse(
                                          startDateController.text,
                                        );
                                        final endDate = DateTime.parse(
                                          endDateController.text,
                                        );

                                        // Format in ISO8601 format that PostgreSQL accepts
                                        formattedStartDate =
                                            startDate.toIso8601String();
                                        formattedEndDate =
                                            endDate.toIso8601String();

                                        final newEvent = {
                                          'title': titleController.text,
                                          'description':
                                              descriptionController.text,
                                          'location': locationController.text,
                                          'type': typeController.text.isEmpty ? 'other' : typeController.text,
                                          'orguid': orgIdController.text.isNotEmpty ? orgIdController.text : (_validOrgId.isNotEmpty ? _validOrgId : null), // Use valid organization ID from database
                                          'banner':
                                              bannerUrlController
                                                      .text
                                                      .isNotEmpty
                                                  ? bannerUrlController.text
                                                  : null,
                                          // Use properly formatted timestamps
                                          'datetimestart': formattedStartDate,
                                          'datetimeend': formattedEndDate,
                                          'status': selectedStatus,
                                        };

                                        // Check if we have a valid organization ID
                                        if (newEvent['orguid'] == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('No valid organization ID available. Please create an organization first.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } else {
                                          // Add the event
                                          _addEvent(newEvent);
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        // Show error for date parsing
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Invalid date format: $e. Use format YYYY-MM-DD HH:MM:SS',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Add Event'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showEditEventDialog(Map<String, dynamic> event) {
    // Create text editing controllers initialized with current values
    final titleController = TextEditingController(text: event['title'] ?? '');
    final typeController = TextEditingController(text: event['type'] ?? '');
    final descriptionController = TextEditingController(
      text: event['description'] ?? '',
    );
    final locationController = TextEditingController(
      text: event['location'] ?? '',
    );
    final bannerUrlController = TextEditingController(
      text: event['banner'] ?? '',
    );
    final orgIdController = TextEditingController(text: event['orguid'] ?? '');
    // Tag controller removed as tag field doesn't exist in database

    // Start and end date controllers
    final startDateController = TextEditingController(
      text: event['datetimestart'] ?? '',
    );
    final endDateController = TextEditingController(
      text: event['datetimeend'] ?? '',
    );

    // Status dropdown value
    // Use valid event status values from the schema constraint
    String selectedStatus = event['status'] ?? 'active';

    // Ensure it's a valid value according to the schema
    if (![
      'active',
      'inactive',
      'cancelled',
      'completed',
    ].contains(selectedStatus)) {
      selectedStatus = 'active'; // Default to active if invalid
    }

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  clipBehavior: Clip.antiAlias,
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    constraints: BoxConstraints(
                      maxWidth: 700,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Edit Event',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Content
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Banner preview (if available)
                                    if (event['banner'] != null)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 24.0,
                                          ),
                                          child: Container(
                                            constraints: const BoxConstraints(
                                              maxHeight: 200,
                                            ),
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                event['banner'],
                                                fit: BoxFit.cover,
                                                headers: const {
                                                  'Access-Control-Allow-Origin':
                                                      '*',
                                                },
                                                loadingBuilder: (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                              : null,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  print(
                                                    'Error loading banner in edit dialog: $error',
                                                  );
                                                  // Check for Google search URLs
                                                  if (event['banner'] != null &&
                                                      event['banner']
                                                          .toString()
                                                          .contains(
                                                            'google.com/url',
                                                          )) {
                                                    // Just display a placeholder in the UI
                                                    // We don't have direct access to the edit controllers here
                                                  }
                                                  return Center(
                                                    child: Icon(
                                                      Icons.image,
                                                      size: 60,
                                                      color: Colors.grey[400],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                    // Title field
                                    TextFormField(
                                      controller: titleController,
                                      decoration: const InputDecoration(
                                        labelText: 'Event Title',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter event title';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Location field
                                    TextFormField(
                                      controller: locationController,
                                      decoration: const InputDecoration(
                                        labelText: 'Location',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter event location';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Event Type field - changed to dropdown to ensure valid types
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Event Type',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: typeController.text.isEmpty ? 'academic' : typeController.text,
                                      items: const [
                                        DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
                                        DropdownMenuItem(value: 'seminar', child: Text('Seminar')),
                                        DropdownMenuItem(value: 'conference', child: Text('Conference')),
                                        DropdownMenuItem(value: 'meetup', child: Text('Meetup')),
                                        DropdownMenuItem(value: 'party', child: Text('Party')),
                                        DropdownMenuItem(value: 'sports', child: Text('Sports')),
                                        DropdownMenuItem(value: 'concert', child: Text('Concert')),
                                        DropdownMenuItem(value: 'exhibition', child: Text('Exhibition')),
                                        DropdownMenuItem(value: 'competition', child: Text('Competition')),
                                        DropdownMenuItem(value: 'academic', child: Text('Academic')),
                                        DropdownMenuItem(value: 'social', child: Text('Social')),
                                        DropdownMenuItem(value: 'cultural', child: Text('Cultural')),
                                        DropdownMenuItem(value: 'other', child: Text('Other')),
                                      ],
                                      onChanged: (value) {
                                        typeController.text = value!;
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please select an event type';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Tag field removed as it doesn't exist in the database

                                    // Organization ID field - hidden from UI but controller still used
                                    

                                    // Start Date field
                                    TextFormField(
                                      controller: startDateController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Start Date (YYYY-MM-DD HH:MM:SS)',
                                        border: OutlineInputBorder(),
                                        helperText:
                                            'Format: 2025-05-01 14:30:00',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter start date';
                                        }
                                        try {
                                          DateTime.parse(value);
                                        } catch (e) {
                                          return 'Invalid date format. Use YYYY-MM-DD HH:MM:SS';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // End Date field
                                    TextFormField(
                                      controller: endDateController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'End Date (YYYY-MM-DD HH:MM:SS)',
                                        border: OutlineInputBorder(),
                                        helperText:
                                            'Format: 2025-05-01 16:30:00',
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter end date';
                                        }
                                        try {
                                          DateTime.parse(value);
                                        } catch (e) {
                                          return 'Invalid date format. Use YYYY-MM-DD HH:MM:SS';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Banner URL field with upload button
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: bannerUrlController,
                                            decoration: const InputDecoration(
                                              labelText: 'Banner Image URL',
                                              border: OutlineInputBorder(),
                                              helperText:
                                                  'Enter the full URL to the event banner image',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.upload),
                                          label: const Text('Upload'),
                                          onPressed:
                                              () => _pickAndUploadImage(
                                                bannerUrlController,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Description field
                                    TextFormField(
                                      controller: descriptionController,
                                      decoration: const InputDecoration(
                                        labelText: 'Description',
                                        border: OutlineInputBorder(),
                                        alignLabelWithHint: true,
                                      ),
                                      maxLines: 5,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter event description';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Status dropdown (for visibility)
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Status',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: selectedStatus,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'active',
                                          child: Text('Active'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'inactive',
                                          child: Text('Inactive'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'cancelled',
                                          child: Text('Cancelled'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'completed',
                                          child: Text('Completed'),
                                        ),
                                      ],
                                      onChanged: (value) {
                                        setDialogState(() {
                                          selectedStatus = value!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Actions
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    if (formKey.currentState!.validate()) {
                                      // Format timestamps correctly for PostgreSQL
                                      String formattedStartDate;
                                      String formattedEndDate;

                                      try {
                                        // Try to parse and format the date correctly
                                        final startDate = DateTime.parse(
                                          startDateController.text,
                                        );
                                        final endDate = DateTime.parse(
                                          endDateController.text,
                                        );

                                        // Format in ISO8601 format that PostgreSQL accepts
                                        formattedStartDate =
                                            startDate.toIso8601String();
                                        formattedEndDate =
                                            endDate.toIso8601String();

                                        final updatedEvent = {
                                          'uid':
                                              event['uid'], // Keep the same ID using correct column name
                                          'title': titleController.text,
                                          'description':
                                              descriptionController.text,
                                          'location': locationController.text,
                                          'type': typeController.text.isEmpty ? 'other' : typeController.text,
                                          'orguid': orgIdController.text.isNotEmpty ? orgIdController.text : (_validOrgId.isNotEmpty ? _validOrgId : null), // Use valid organization ID from database
                                          'banner':
                                              bannerUrlController
                                                      .text
                                                      .isNotEmpty
                                                  ? bannerUrlController.text
                                                  : null,
                                          // Use properly formatted timestamps
                                          'datetimestart': formattedStartDate,
                                          'datetimeend': formattedEndDate,
                                          'status': selectedStatus,
                                        };

                                        // Check if we have a valid organization ID
                                        if (updatedEvent['orguid'] == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('No valid organization ID available. Please create an organization first.'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        } else {
                                          // Update the event
                                          _updateEvent(updatedEvent);
                                          Navigator.pop(context);
                                        }
                                      } catch (e) {
                                        // Show error for date parsing
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Invalid date format: $e. Use format YYYY-MM-DD HH:MM:SS',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Save Changes'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }
}
