import 'package:flutter/material.dart';

class ListApplyPage extends StatefulWidget {
  const ListApplyPage({Key? key}) : super(key: key);

  @override
  _ListApplyPage createState() => _ListApplyPage();
}

class _ListApplyPage extends State<ListApplyPage> {
  List<String> _mockDocuments = ["transcript.pdf", "cv.pdf"];

  List<Map<String, String>> _applications = [
    {'id': '1', 'title': 'Internship at XYZ Corp', 'status': 'Pending'},
    {'id': '2', 'title': 'Research Assistant at Uni', 'status': 'Approved'},
    {'id': '3', 'title': 'Summer Practice in IT', 'status': 'Rejected'},
  ];
  void _showApplicationDetails(BuildContext context, Map<String, String> app) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 50,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.assignment),
                title: Text(app['title'] ?? ''),
                subtitle: Text("Status: ${app['status']}"),
              ),
              SizedBox(height: 16),
              Text(
                "Attached Documents",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ..._mockDocuments.map(
                (doc) => ListTile(
                  leading: Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(doc),
                  trailing: Icon(Icons.download),
                  onTap: () {},
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.attach_file),
                label: Text("Attach Document"),
                onPressed: () {
                  setState(() {
                    _mockDocuments.add(
                      "new_document_${_mockDocuments.length + 1}.pdf",
                    );
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _createNewApplication() {
    setState(() {
      _applications.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': 'New Application',
        'status': 'Pending',
      });
    });
  }

  void _editApplication(int index) {
    final currentTitle = _applications[index]['title']!;
    setState(() {
      _applications[index]['title'] = "$currentTitle (Edited)";
    });
  }

  void _deleteApplication(int index) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('Delete Application'),
            content: Text('Are you sure you want to delete this application?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _applications.removeAt(index);
                  });
                  Navigator.pop(context);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Applications"),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _applications.isEmpty
                ? Center(child: Text("No applications submitted yet."))
                : ListView.builder(
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final app = _applications[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(Icons.assignment),
                        title: Text(app['title'] ?? ''),
                        subtitle: Text("Status: ${app['status']}"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _editApplication(index);
                            if (value == 'delete') _deleteApplication(index);
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                        ),
                        onTap: () => _showApplicationDetails(context, app),
                      ),
                    );
                  },
                ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewApplication,
        label: Text("New Application"),
        icon: Icon(Icons.add),
      ),
    );
  }
}
