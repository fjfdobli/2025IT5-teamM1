import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'login.dart';
import 'dart:io';
import 'calendar.dart';
import 'notifications.dart';
import 'profile.dart';

class EventData {
  final String id;
  final String title;
  final String organizer;
  final DateTime date;
  final String time;
  final String location;
  final String imagePath;
  final String bucketName;
  final bool isJoined;

  EventData({
    required this.id,
    required this.title,
    required this.organizer,
    required this.date,
    required this.time,
    required this.location,
    required this.imagePath,
    required this.bucketName,
    this.isJoined = false,
  });
}

class HomeScreen extends StatefulWidget {
  final String? userEmail;
  final String? userRole;

  const HomeScreen({super.key, this.userEmail, this.userRole = 'student'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  String? _userEmail;
  String? _userRole;
  bool _isLoading = true;
  bool _isMenuOpen = false;
  List<EventData> _events = [];
  List<EventData> _filteredEvents = []; // For search results
  String _currentTab = 'All';
  String _currentView = 'My Events';

  // Search controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize with values passed from login screen
    _userEmail = widget.userEmail;
    _userRole = widget.userRole;

    // If no values were passed, try to load from Supabase
    if (_userEmail == null) {
      _loadUserDetails();
    } else {
      _isLoading = false;
    }

    // Load event data
    _loadEvents();

    // Initialize filtered events
    _filteredEvents = _events;

    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
    
    // No longer testing image access since we're using local assets
    // _testImageAccess();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Search functionality
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterEvents();
    });
  }

  // Filter events based on search query and current tab
  void _filterEvents() {
    if (_searchQuery.isEmpty && _currentTab == 'All') {
      _filteredEvents = _events;
      return;
    }

    _filteredEvents =
        _events.where((event) {
          // First filter by category tab
          bool matchesCategory =
              _currentTab == 'All' ||
              event.title.toLowerCase().contains(_currentTab.toLowerCase()) ||
              event.organizer.toLowerCase().contains(_currentTab.toLowerCase());

          // Then filter by search query if present
          bool matchesSearch =
              _searchQuery.isEmpty ||
              event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              event.organizer.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              event.location.toLowerCase().contains(_searchQuery.toLowerCase());

          return matchesCategory && matchesSearch;
        }).toList();
  }

  // Method to test direct access to an image
  Future<void> _testImageAccess() async {
    try {
      // Since event bucket images don't work, test all organization logo images
      final orgBucket = 'organization-logos';

      // List all organization logo files from the screenshot
      final List<String> orgLogos = [
        'APTOP.jpg',
        'Ateneo Culture and Arts Cluster.jpg',
        'Ateneo Japanese & Kendo Community.jpg',
        'Ateneo Repertory Company.jpg',
        'Ateneo Samahan Productions.jpg',
        'Ateneo Student Parking Spaces.jpg',
        'Cateneo.jpg',
        'Computer Studies Student Executive Council.jpg',
        'RCV.jpg',
        'Samahan.jpg',
        'Samahan Logistics Department.jpg',
      ];

      developer.log('Testing all organization logos for accessibility:');

      // Create an HTTP client to test the URLs
      final http = HttpClient();

      for (var logo in orgLogos) {
        try {
          final url =
              'https://zsyxgeadumcnttknsfou.supabase.co/storage/v1/object/public/$orgBucket/$logo';
          final request = await http.getUrl(Uri.parse(url));
          final response = await request.close();

          if (response.statusCode == 200) {
            developer.log('✅ SUCCESS: Logo "$logo" IS accessible');
          } else {
            developer.log(
              '❌ ERROR: Logo "$logo" is NOT accessible (${response.statusCode})',
            );
          }
        } catch (e) {
          developer.log('❌ EXCEPTION testing logo "$logo": $e');
        }
      }

      // Create an image URL using our getImageUrlFromPath function and test it
      try {
        final testUrl = getImageUrlFromPath(
          'event-banners',
          'path/to/event_banner1',
        );
        developer.log('Testing URL from getImageUrlFromPath: $testUrl');

        final request = await http.getUrl(Uri.parse(testUrl));
        final response = await request.close();

        if (response.statusCode == 200) {
          developer.log('SUCCESS: URL from getImageUrlFromPath is accessible');
        } else {
          developer.log(
            'ERROR: URL from getImageUrlFromPath is NOT accessible',
          );
        }
      } catch (e) {
        developer.log('Exception testing URL from getImageUrlFromPath: $e');
      }

      http.close();
    } catch (e) {
      developer.log('Exception in image access test: $e');
    }
  }

  // Map placeholder paths to actual image filenames using direct asset loading
  String getImageUrlFromPath(String bucket, String path) {
    // IMPORTANT: Since we're having issues with Supabase storage URLs returning HTML,
    // let's use local assets instead which are guaranteed to work

    // Log what's happening for debugging
    developer.log('Using local asset images instead of Supabase storage');
    
    // Instead of remote URL, use a fallback local image that's guaranteed to work
    // This will use the ADDU logo from the assets folder
    return 'assets/images/addu_logo.png';
  }

  Future<void> _loadEvents() async {
    try {
      // Sample data with the paths from your database
      setState(() {
        _events = [
          EventData(
            id: '1',
            title: 'IT Week 2025',
            organizer: 'Computer Studies Cluster',
            date: DateTime(2025, 2, 24),
            time: '3:00 PM',
            location: 'Arrupe Hall',
            imagePath: 'path/to/event_banner2', // Maps to Computer Studies logo
            bucketName: 'event-banners',
            isJoined: true,
          ),
          EventData(
            id: '2',
            title: 'Creative Arts Festival',
            organizer: 'Ateneo Culture and Arts Council',
            date: DateTime(2025, 3, 15),
            time: '6:00 PM',
            location: 'Martin Hall',
            imagePath: 'path/to/event_banner3', // Maps to Arts logo
            bucketName: 'event-banners',
            isJoined: false,
          ),
          EventData(
            id: '3',
            title: 'Samahan Week',
            organizer: 'Samahan',
            date: DateTime(2025, 4, 5),
            time: '9:00 AM',
            location: 'Finster Hall',
            imagePath: 'path/to/event_banner4', // Maps to Samahan logo
            bucketName: 'event-banners',
            isJoined: false,
          ),
        ];

        // Initialize filtered events with all events
        _filteredEvents = _events;
      });
    } catch (e) {
      developer.log('Error loading events: $e');
    }
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Very simple approach - just check if we have a current user
      final currentUser = _supabase.auth.currentUser;

      if (currentUser != null) {
        developer.log('Current user found: ${currentUser.id}');
        developer.log('Email: ${currentUser.email}');

        // Set email and default role to student per exam requirements
        setState(() {
          _userEmail = currentUser.email ?? "Google User";
          _userRole = 'student'; // Default role per exam requirements
          _isLoading = false;
        });
      } else {
        developer.log('No user found - redirecting to login');
        setState(() {
          _isLoading = false;
        });

        // Redirect to login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      developer.log('Error getting user: $e');
      setState(() {
        _userEmail = "Google User";
        _userRole = 'student'; // Always default to student
        _isLoading = false;
      });
    }
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _viewEventDetails(EventData event) {
    // Simple show dialog with event details
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(event.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event banner - using path mapping approach
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _buildDetailImage(event),
                ),
                const SizedBox(height: 16),
                // Event details
                Text(
                  event.organizer,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMMM d, yyyy').format(event.date),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(event.time, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      event.location,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Join/Unjoin functionality
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      event.isJoined ? Colors.grey : const Color(0xFF3949AB),
                  foregroundColor: event.isJoined ? Colors.black : Colors.white,
                ),
                child: Text(event.isJoined ? 'JOINED' : 'JOIN'),
              ),
            ],
          ),
    );
  }

  // Method to build detail image with local assets
  Widget _buildDetailImage(EventData event) {
    final assetPath = getImageUrlFromPath(event.bucketName, event.imagePath);
    developer.log('Using asset path: $assetPath');

    // Use direct asset image instead of network image
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        developer.log('Error loading detail image: $error');
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Navigation methods
  void _navigateToCalendar() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => CalendarScreen()));
  }

  void _navigateToNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(userEmail: _userEmail),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) =>
                ProfileScreen(userEmail: _userEmail, userRole: _userRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/addu_logo.png', height: 30),
            const SizedBox(width: 8),
            const Text(
              'UNIVENTS',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF3949AB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _toggleMenu,
            tooltip: 'Menu',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Search bar - now connected to controller
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _filterEvents();
                        });
                      },
                    ),
                  ),

                  // Category tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _buildCategoryTab('All'),
                        const SizedBox(width: 8),
                        _buildCategoryTab('Sports'),
                        const SizedBox(width: 8),
                        _buildCategoryTab('Arts'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            // Filter functionality
                          },
                        ),
                      ],
                    ),
                  ),

                  // View selector (My Events/Upcoming Events)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          _currentView,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onPressed: () {
                            setState(() {
                              _currentView =
                                  _currentView == 'My Events'
                                      ? 'Upcoming Events'
                                      : 'My Events';
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Event list - now showing filtered events
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadUserDetails,
                      child:
                          _filteredEvents.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isEmpty
                                          ? 'No events found'
                                          : 'No events match your search "$_searchQuery"',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: _filteredEvents.length,
                                itemBuilder: (context, index) {
                                  final event = _filteredEvents[index];
                                  return _buildEventCard(event);
                                },
                              ),
                    ),
                  ),
                ],
              ),

          // Side Menu - shown when menu button is pressed
          if (_isMenuOpen)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.7,
              child: GestureDetector(
                onTap: () {}, // Prevent taps from closing the menu
                child: Container(
                  color: const Color(0xFFEAEAF6),
                  child: Column(
                    children: [
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: const Color(0xFF3949AB),
                              child: Text(
                                _userEmail != null
                                    ? _userEmail!.substring(0, 2).toUpperCase()
                                    : 'JD',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userEmail ?? 'John Michael Doe III',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '$_userRole\nID: 2202201427440',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.dark_mode),
                              onPressed: () {
                                // Toggle dark mode
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMenuOption(Icons.calendar_month, 'My Events'),
                      _buildMenuOption(Icons.settings, 'Settings'),
                      _buildMenuOption(Icons.help, 'Help & Support'),
                      _buildMenuOption(Icons.logout, 'Log Out', isLogout: true),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/addu_logo.png',
                              height: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'UNIVENTS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3949AB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Dark overlay when menu is open
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(color: Colors.black54),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3949AB),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 0,
        onTap: (index) {
          // Handle navigation
          switch (index) {
            case 0:
              // Already on home screen
              break;
            case 1:
              _navigateToCalendar();
              break;
            case 2:
              _navigateToNotifications();
              break;
            case 3:
              _navigateToProfile();
              break;
          }
        },
      ),
    );
  }

  Widget _buildCategoryTab(String label) {
    final isSelected = _currentTab == label;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          _currentTab = label;
          _filterEvents(); // Filter events when tab changes
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF3949AB) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildMenuOption(
    IconData icon,
    String label, {
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF3949AB), size: 28),
      title: Text(
        label,
        style: TextStyle(
          color: isLogout ? Colors.red : const Color(0xFF3949AB),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          label == 'Settings' || label == 'Help & Support'
              ? const Icon(Icons.chevron_right, color: Color(0xFF3949AB))
              : null,
      onTap: () {
        if (isLogout) {
          _supabase.auth.signOut();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        // Handle other menu options
      },
    );
  }

  Widget _buildEventCard(EventData event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewEventDetails(event),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date container
            Container(
              width: 80,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFF3949AB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('d').format(event.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(event.date).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Event details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event image - using path mapping approach
                        _buildEventImage(event),
                        const SizedBox(width: 12),

                        // Event info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                event.organizer,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    event.time,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '•',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () => _viewEventDetails(event),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3949AB),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(80, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text('VIEW'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Join/Unjoin functionality
                            setState(() {
                              // Find the event in the original list and toggle its state
                              final eventIndex = _events.indexWhere(
                                (e) => e.id == event.id,
                              );
                              if (eventIndex != -1) {
                                final updatedEvents = List<EventData>.from(
                                  _events,
                                );
                                final currentEvent = _events[eventIndex];

                                // Create a new event with toggled isJoined state
                                final updatedEvent = EventData(
                                  id: currentEvent.id,
                                  title: currentEvent.title,
                                  organizer: currentEvent.organizer,
                                  date: currentEvent.date,
                                  time: currentEvent.time,
                                  location: currentEvent.location,
                                  imagePath: currentEvent.imagePath,
                                  bucketName: currentEvent.bucketName,
                                  isJoined: !currentEvent.isJoined,
                                );

                                updatedEvents[eventIndex] = updatedEvent;
                                _events = updatedEvents;

                                // Update filtered events as well
                                _filterEvents();
                              }
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                event.isJoined
                                    ? const Color(0xFF3949AB)
                                    : Colors.grey,
                          ),
                          child: Text(event.isJoined ? 'JOINED' : 'JOIN'),
                        ),
                      ],
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

  // Build event image with local assets
  Widget _buildEventImage(EventData event) {
    final assetPath = getImageUrlFromPath(event.bucketName, event.imagePath);
    developer.log('Using asset path for event: $assetPath');

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          developer.log('Error loading event image: $error');
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 30),
            ),
          );
        },
      ),
    );
  }
}
