import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:e_sign/pages/register_page.dart';
import 'package:e_sign/services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'reset_password_page.dart';
import '../pages/role_based_nav.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPage createState() => _AdminPage();
}

class _AdminPage extends State<AdminPage> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: Container(
        padding: EdgeInsets.all(32),
        child: ListView(
          children: [
            Column(
              children: [
                SizedBox(height: 10),

                FutureBuilder<List<Map<String, String>>>(
                  future: DatabaseService().getUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Text("Error loading users");
                    }

                    final users = snapshot.data ?? [];

                    final visibleUsers =
                        _expanded ? users : users.take(5).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(Icons.group, color: Colors.blue, size: 40),
                              SizedBox(width: 8),
                              Text(
                                "Recent Users",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),
                        ...visibleUsers.map((user) {
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(user['email'] ?? ''),
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.person, color: Colors.blue),
                              ),
                              subtitle: Row(
                                children: [
                                  Text("Role: "),
                                  Text(
                                    user['role'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),

                              style: ListTileStyle.list,
                              onTap: () async {
                                final selectedRole = await showDialog<String>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Select Role'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            title: Text('Appliciant'),
                                            onTap:
                                                () => Navigator.pop(
                                                  context,
                                                  'appliciant',
                                                ),
                                          ),
                                          ListTile(
                                            title: Text('Reviewer'),
                                            onTap:
                                                () => Navigator.pop(
                                                  context,
                                                  'reviewer',
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                if (selectedRole != null) {
                                  final userId = user['id']!;
                                  final path = "users/$userId";
                                  final data = {"role": selectedRole};

                                  await DatabaseService().update(
                                    path: path,
                                    data: data,
                                  );
                                  setState(() {});
                                  print('User role updated to $selectedRole');
                                }
                              },

                              trailing: Icon(Icons.chevron_right),
                            ),
                          );
                        }),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _expanded = !_expanded;
                              });
                            },
                            icon: Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                            ),
                            label: Text(_expanded ? "Show Less" : "Show All"),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 40),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Navigate to templates view
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.description, size: 28, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "View Document Templates",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
