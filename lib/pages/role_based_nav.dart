import 'package:flutter/material.dart';
import 'admin_page.dart';
import 'profile_page.dart';
import 'list_apply_page.dart';
import 'review_page.dart';

class RoleBasedNav extends StatefulWidget {
  final String? role;
  const RoleBasedNav({required this.role});

  @override
  _RoleBasedNavState createState() => _RoleBasedNavState();
}

class _RoleBasedNavState extends State<RoleBasedNav> {
  late List<Widget> pages;
  late List<BottomNavigationBarItem> items;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.role == "admin") {
      pages = [AdminPage(), ProfilePage()];
      items = [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Profile"),
      ];
    }
    if (widget.role == "appliciant") {
      pages = [ListApplyPage(), ProfilePage()];
      items = [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Profile"),
      ];
    }
    if (widget.role == "reviewer") {
      pages = [ReviewPage(), ProfilePage()];
      items = [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: "Profile"),
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.blueGrey,
        items: items,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
