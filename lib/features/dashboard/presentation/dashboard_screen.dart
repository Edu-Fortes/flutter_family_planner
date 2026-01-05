import 'package:flutter/material.dart';
import '../../grocery/presentation/grocery_screen.dart';
import '../../calendar/presentation/calendar_screen.dart';
import '../../tasks/presentation/tasks_screen.dart'; // Import new screen
import 'dashboard_overview.dart'; // We will move the summary layout here

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // The list of "Dedicated Screens"
  final List<Widget> _pages = [
    const DashboardOverview(), // Index 0: The Summary View
    const GroceryScreen(), // Index 1
    const CalendarScreen(), // Index 2
    const TasksScreen(), // Index 3: The dedicated Task Manager
    const Center(child: Text("Members Screen (Coming Soon)")), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // --- SIDE NAVIGATION BAR ---
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
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Grocery'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: Text('Calendar'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: Text('Tasks'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Family'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // --- MAIN CONTENT AREA ---
          Expanded(
            child: _pages[_selectedIndex], // Switches the screen
          ),
        ],
      ),
    );
  }
}
