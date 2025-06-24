import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../shared/application_controller.dart';
import '../shared/application_dialogs.dart';

class ListApplyPage extends StatefulWidget {
  const ListApplyPage({Key? key}) : super(key: key);

  @override
  _ListApplyPageState createState() => _ListApplyPageState();
}

class _ListApplyPageState extends State<ListApplyPage> {
  late ApplicationController _controller;
  late Stream<QuerySnapshot> _applicationsStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _applicationsStream = _controller.getApplicationsStream();
  }

  void _initializeController() {
    _controller = ApplicationController(
      onError: _showError,
      onSuccess: _showSuccess,
      onLoadingChanged: (loading) => setState(() => _isLoading = loading),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleMenuAction(String action, DocumentSnapshot appDoc) {
    switch (action) {
      case 'edit':
        ApplicationDialogs.showEditDialog(context, appDoc, _controller);
        break;
      case 'delete':
        ApplicationDialogs.showDeleteDialog(context, appDoc, _controller);
        break;
      case 'sign':
        ApplicationDialogs.showSignDialog(context, appDoc, _controller);
        break;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No applications submitted yet.",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tap the + button to create your first application",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(DocumentSnapshot appDoc) {
    final appData = appDoc.data() as Map<String, dynamic>;
    final status = appData['status'] ?? 'unknown';
    final title = appData['title'] ?? 'Application';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _controller.getStatusColor(status).withOpacity(0.1),
          child: Icon(
            _controller.getStatusIcon(status),
            color: _controller.getStatusColor(status),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Row(
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: _controller.getStatusColor(status),
            ),
            const SizedBox(width: 4),
            Text(
              status,
              style: TextStyle(
                color: _controller.getStatusColor(status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: _buildPopupMenu(appDoc, status),
        onTap:
            () => ApplicationDialogs.showApplicationDetails(
              context,
              appDoc,
              _controller,
            ),
      ),
    );
  }

  Widget _buildPopupMenu(DocumentSnapshot appDoc, String status) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(value, appDoc),
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            if (status.toLowerCase() == 'pending' ||
                status.toLowerCase() == 'submitted')
              const PopupMenuItem(
                value: 'sign',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Sign'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
    );
  }

  Widget _buildApplicationsList(List<DocumentSnapshot> docs) {
    final sortedDocs = _controller.sortApplications(docs);

    return ListView.builder(
      itemCount: sortedDocs.length,
      itemBuilder: (context, index) {
        return _buildApplicationCard(sortedDocs[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Applications"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              _showSuccess('Applications refreshed');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: _applicationsStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error!);
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            return _buildApplicationsList(snapshot.data!.docs);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => ApplicationDialogs.showTemplateSelectionDialog(
              context,
              _controller,
            ),
        label: const Text("New Application"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
