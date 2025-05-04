import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  final String? userEmail;

  const NotificationsScreen({super.key, this.userEmail});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _notifications = [];
  bool _showAllNotifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // In a real app, you would fetch notifications from Supabase
    // For demo purposes, we'll use mock data
    await Future.delayed(
      const Duration(milliseconds: 800),
    ); // Simulate network delay

    setState(() {
      _notifications = _getMockNotifications();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getMockNotifications() {
    // Create mock notifications based on your screenshot
    return [
      {
        'id': '1',
        'type': 'Event Update',
        'title': 'IT Week 2025 - Room Change',
        'description': 'Now in F503 instead of F610',
        'event_id': '2',
        'image': 'Computer Studies Student Executive Council.jpg',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)),
        'is_read': false,
      },
      {
        'id': '2',
        'type': 'Event Reminder',
        'title': 'Mathlympics 2025',
        'description': 'Tomorrow • 2:00 PM • J304 & J305',
        'event_id': '1',
        'image': 'APTOP.jpg',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)),
        'is_read': false,
      },
      {
        'id': '3',
        'type': 'Registration Confirmed',
        'title': 'Mathlympics 2025',
        'description': 'Your participation has been confirmed.',
        'event_id': '1',
        'image': 'check.png', // A check mark icon
        'created_at': DateTime.now().subtract(const Duration(hours: 8)),
        'is_read': true,
      },
      {
        'id': '4',
        'type': 'Event Update',
        'title': 'IT Week 2025 - Room Change',
        'description': 'Now in F610 instead of Arrupe Hall',
        'event_id': '2',
        'image': 'Computer Studies Student Executive Council.jpg',
        'created_at': DateTime.now().subtract(const Duration(hours: 13)),
        'is_read': true,
      },
      {
        'id': '5',
        'type': 'Event Reminder',
        'title': 'IT Week 2025',
        'description': 'Tomorrow • 3:00 PM • Arrupe Hall',
        'event_id': '2',
        'image': 'Computer Studies Student Executive Council.jpg',
        'created_at': DateTime.now().subtract(const Duration(days: 1)),
        'is_read': true,
      },
      {
        'id': '6',
        'type': 'Registration Confirmed',
        'title': 'IT Week 2025',
        'description': 'Your participation has been confirmed.',
        'event_id': '2',
        'image': 'check.png',
        'created_at': DateTime.now().subtract(const Duration(days: 1)),
        'is_read': true,
      },
      {
        'id': '7',
        'type': 'Account Created',
        'title': 'Welcome to UniVents!',
        'description': 'Your account has been created and verified.',
        'event_id': null,
        'image': 'addu_logo.png',
        'created_at': DateTime.now().subtract(
          const Duration(days: 1, hours: 1),
        ),
        'is_read': true,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Filter notifications based on read/unread if necessary
    final displayedNotifications =
        _showAllNotifications
            ? _notifications
            : _notifications.where((notif) => !notif['is_read']).toList();

    // Group notifications by date
    final Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

    for (var notification in displayedNotifications) {
      final DateTime createdAt = notification['created_at'];
      String dateKey;

      if (DateTime.now().difference(createdAt).inDays == 0) {
        dateKey = 'Today';
      } else if (DateTime.now().difference(createdAt).inDays == 1) {
        dateKey = 'Yesterday';
      } else {
        // For older notifications, use actual date
        dateKey = DateFormat('MMMM d').format(createdAt);
      }

      if (!groupedNotifications.containsKey(dateKey)) {
        groupedNotifications[dateKey] = [];
      }
      groupedNotifications[dateKey]!.add(notification);
    }

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
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
      ),
      body: Column(
        children: [
          // Header with title and filter toggle
          Container(
            color: const Color(0xFFEEEEF6),
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 16.0,
            ),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                // Toggle buttons for ALL/UNREAD
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3949AB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterButton('ALL', _showAllNotifications),
                      _buildFilterButton('UNREAD', !_showAllNotifications),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notifications list
          _isLoading
              ? const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
              : displayedNotifications.isEmpty
              ? const Expanded(child: Center(child: Text('No notifications')))
              : Expanded(
                child: ListView.builder(
                  itemCount: groupedNotifications.keys.length,
                  itemBuilder: (context, sectionIndex) {
                    final dateKey = groupedNotifications.keys.elementAt(
                      sectionIndex,
                    );
                    final notificationsInSection =
                        groupedNotifications[dateKey]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            dateKey,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),

                        // Notifications for this section
                        ...notificationsInSection.map((notification) {
                          return _buildNotificationTile(notification);
                        }),
                      ],
                    );
                  },
                ),
              ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Notifications tab
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
        onTap: (index) {
          if (index != 2) {
            // Not notifications tab
            Navigator.pop(context);
            // Navigation would be handled in the parent widget
          }
        },
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAllNotifications = text == 'ALL';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3949AB) : Colors.grey.shade500,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    // Choose icon based on notification type
    Widget leadingIcon;

    switch (notification['type']) {
      case 'Event Update':
      case 'Event Reminder':
        // Use organization logos for events
        leadingIcon = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/${notification['image']}',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to a placeholder icon if image fails to load
              return Container(
                width: 50,
                height: 50,
                color: Colors.grey.shade300,
                child: const Icon(Icons.event, color: Colors.grey),
              );
            },
          ),
        );
        break;
      case 'Registration Confirmed':
        leadingIcon = Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 30),
        );
        break;
      case 'Account Created':
        leadingIcon = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/addu_logo.png',
            width: 50,
            height: 50,
            fit: BoxFit.contain,
          ),
        );
        break;
      default:
        leadingIcon = Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.notifications, color: Colors.grey),
        );
    }

    return InkWell(
      onTap: () {
        // Mark as read when tapped
        setState(() {
          notification['is_read'] = true;
        });

        // Handle notification tap - navigate to event details, etc.
        if (notification['event_id'] != null) {
          // Navigate to event details
          Navigator.pop(context, {
            'action': 'viewEvent',
            'eventId': notification['event_id'],
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color:
              notification['is_read']
                  ? null
                  : Colors.blue.shade50.withOpacity(0.3),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon
            leadingIcon,
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification['type'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    notification['title'],
                    style: const TextStyle(fontSize: 14),
                  ),

                  // Description
                  Text(
                    notification['description'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Time ago
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                _getTimeAgo(notification['created_at']),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
