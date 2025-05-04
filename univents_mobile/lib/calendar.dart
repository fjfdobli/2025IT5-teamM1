import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  List<EventData> _events = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    // Load the same events that are in the dashboard
    setState(() {
      _events = [
        EventData(
          id: '1',
          title: 'IT Week 2025',
          organizer: 'Computer Studies Cluster',
          date: DateTime(2025, 2, 24),
          time: '3:00 PM',
          location: 'Arrupe Hall',
          imagePath: 'path/to/event_banner2',
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
          imagePath: 'path/to/event_banner3',
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
          imagePath: 'path/to/event_banner4',
          bucketName: 'event-banners',
          isJoined: false,
        ),
      ];
    });
  }

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });
  }

  void _previousMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
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
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () {})],
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFEEEEF6),
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Center(
              child: Text(
                '~ Calendar ~',
                style: TextStyle(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Custom calendar implementation
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Month navigation
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Color(0xFF3949AB),
                        ),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        DateFormat(
                          'MMMM yyyy',
                        ).format(_focusedDay).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3949AB),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF3949AB),
                        ),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                ),

                // Days of week header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      Text(
                        'SUN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'MON',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'TUE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'WED',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'THU',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'FRI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'SAT',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Calendar grid
                _buildCalendarGrid(),
              ],
            ),
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 16.0),
            child: Divider(height: 1, thickness: 1),
          ),

          // Event information for selected day
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              _hasEventsForDay(_selectedDay)
                  ? 'Events on ${DateFormat('MMMM d').format(_selectedDay)}'
                  : 'No Events on ${DateFormat('MMMM d').format(_selectedDay)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF3949AB),
              ),
            ),
          ),

          // Event list for selected day
          if (_hasEventsForDay(_selectedDay))
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children:
                    _getEventsForDay(
                      _selectedDay,
                    ).map((event) => _buildEventCard(event)).toList(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1, // Calendar tab
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
          if (index != 1) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Get the first day of the month
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);

    // Determine which day of the week the first day falls on (0 = Sunday, 1 = Monday, etc.)
    final firstWeekday = firstDay.weekday % 7;

    // Get the number of days in the month
    final daysInMonth =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;

    // Calculate the number of rows needed for the grid
    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    // Get previous month's days to display
    final prevMonthDays = firstWeekday;
    final prevMonth = DateTime(_focusedDay.year, _focusedDay.month - 1, 0);
    final daysInPrevMonth = prevMonth.day;

    // Get next month's days to display
    final nextMonthDays = (rowCount * 7) - (firstWeekday + daysInMonth);

    List<Widget> rows = [];
    int dayCounter =
        1 - firstWeekday; // Start from the correct offset of previous month

    // Create rows
    for (int i = 0; i < rowCount; i++) {
      List<Widget> cells = [];

      // Create 7 cells for each day of the week
      for (int j = 0; j < 7; j++) {
        if (dayCounter <= 0) {
          // Previous month's days
          final prevMonthDay = daysInPrevMonth + dayCounter;
          cells.add(_buildDayCell(prevMonthDay, isCurrentMonth: false));
        } else if (dayCounter > daysInMonth) {
          // Next month's days
          final nextMonthDay = dayCounter - daysInMonth;
          cells.add(_buildDayCell(nextMonthDay, isCurrentMonth: false));
        } else {
          // Current month's days
          final isSelected =
              _selectedDay.year == _focusedDay.year &&
              _selectedDay.month == _focusedDay.month &&
              _selectedDay.day == dayCounter;

          final isToday =
              DateTime.now().year == _focusedDay.year &&
              DateTime.now().month == _focusedDay.month &&
              DateTime.now().day == dayCounter;

          cells.add(
            _buildDayCell(
              dayCounter,
              isCurrentMonth: true,
              isSelected: isSelected,
              isToday: isToday,
              hasEvents: _hasEventsForDay(
                DateTime(_focusedDay.year, _focusedDay.month, dayCounter),
              ),
            ),
          );
        }
        dayCounter++;
      }

      // Add row to the grid
      rows.add(
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: cells),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: rows),
    );
  }

  Widget _buildDayCell(
    int day, {
    bool isCurrentMonth = true,
    bool isSelected = false,
    bool isToday = false,
    bool hasEvents = false,
  }) {
    Color textColor = isCurrentMonth ? Colors.black : Colors.grey;
    Color backgroundColor = Colors.transparent;

    if (isSelected) {
      backgroundColor = const Color(0xFF3949AB);
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = const Color(0xFFDCE2FF);
    }

    return InkWell(
      onTap:
          isCurrentMonth
              ? () {
                _onDaySelected(
                  DateTime(_focusedDay.year, _focusedDay.month, day),
                );
              }
              : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        margin: const EdgeInsets.all(2),
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              color: textColor,
              fontWeight:
                  isToday || isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  bool _hasEventsForDay(DateTime day) {
    // Check if any event is on the selected day
    return _events.any(
      (event) =>
          event.date.year == day.year &&
          event.date.month == day.month &&
          event.date.day == day.day,
    );
  }

  List<EventData> _getEventsForDay(DateTime day) {
    // Filter events for the selected day
    return _events
        .where(
          (event) =>
              event.date.year == day.year &&
              event.date.month == day.month &&
              event.date.day == day.day,
        )
        .toList();
  }

  Widget _buildEventCard(EventData event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewEventDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventImage(event),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.organizer,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(event.time, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    event.location,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Join/Unjoin functionality
                      setState(() {
                        int index = _events.indexWhere((e) => e.id == event.id);
                        if (index != -1) {
                          _events[index] = EventData(
                            id: event.id,
                            title: event.title,
                            organizer: event.organizer,
                            date: event.date,
                            time: event.time,
                            location: event.location,
                            imagePath: event.imagePath,
                            bucketName: event.bucketName,
                            isJoined: !event.isJoined,
                          );
                        }
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          event.isJoined
                              ? Colors.grey
                              : const Color(0xFF3949AB),
                      foregroundColor:
                          event.isJoined ? Colors.black : Colors.white,
                    ),
                    child: Text(event.isJoined ? 'JOINED' : 'JOIN'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build event image with path mapping
  Widget _buildEventImage(EventData event) {
    final imageUrl = _getImageUrlFromPath(event.bucketName, event.imagePath);

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 30),
          );
        },
      ),
    );
  }

  String _getImageUrlFromPath(String bucket, String path) {
    // Same logic as in dashboard.dart
    if (path.contains('1') ||
        path.contains('banner1') ||
        path.contains('Mathlympics')) {
      return 'https://zsyxgeadumcnttknsfou.supabase.co/storage/v1/object/public/organization-logos/APTOP.jpg';
    } else if (path.contains('2') ||
        path.contains('banner2') ||
        path.contains('IT Week') ||
        path.contains('Computer')) {
      return 'https://zsyxgeadumcnttknsfou.supabase.co/storage/v1/object/public/organization-logos/Computer Studies Student Executive Council.jpg';
    } else if (path.contains('3') ||
        path.contains('banner3') ||
        path.contains('Culture') ||
        path.contains('Arts')) {
      return 'https://zsyxgeadumcnttknsfou.supabase.co/storage/v1/object/public/organization-logos/Ateneo Culture and Arts Cluster.jpg';
    } else if (path.contains('4') ||
        path.contains('banner4') ||
        path.contains('Samahan')) {
      return 'https://zsyxgeadumcnttknsfou.supabase.co/storage/v1/object/public/organization-logos/Samahan.jpg';
    }

    // For anything else, use the first logo
    return 'https://zsyxgeadumcnttknsfou.supabase.co/storage/v1/object/public/organization-logos/APTOP.jpg';
  }

  void _viewEventDetails(EventData event) {
    // Show dialog with event details
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(event.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event banner
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    _getImageUrlFromPath(event.bucketName, event.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.error)),
                      );
                    },
                  ),
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
                  setState(() {
                    int index = _events.indexWhere((e) => e.id == event.id);
                    if (index != -1) {
                      _events[index] = EventData(
                        id: event.id,
                        title: event.title,
                        organizer: event.organizer,
                        date: event.date,
                        time: event.time,
                        location: event.location,
                        imagePath: event.imagePath,
                        bucketName: event.bucketName,
                        isJoined: !event.isJoined,
                      );
                    }
                  });
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
}
