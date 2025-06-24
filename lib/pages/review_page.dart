import 'package:e_sign/shared/application_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../shared/review_logic_controller.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_sign/shared/application_controller.dart';
import 'package:flutter/material.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({Key? key}) : super(key: key);

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final ReviewLogicController _controller;
  late Stream<QuerySnapshot> _applicationsStream;

  bool _isLoading = false;
  String _searchQuery = '';
  String _statusFilter = 'all';
  ApplicationController applicationController = ApplicationController();

  @override
  void initState() {
    super.initState();
    _controller = ReviewLogicController();
    _initializeStream();
  }

  void _initializeStream() {
    _applicationsStream = _controller.getApplicationsStream(_statusFilter);
  }

  void _updateFilters() {
    setState(() {
      _initializeStream();
    });
  }

  Future<void> _downloadDocument(Map<String, dynamic> appData) async {
    setState(() => _isLoading = true);

    try {
      final filePath = await _controller.downloadDocument(appData);
      if (mounted) {
        _showSuccessSnackBar('Document downloaded to: $filePath');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to download document: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showReviewDialog(DocumentSnapshot appDoc) async {
    final appData = appDoc.data() as Map<String, dynamic>;
    final applicationId = appDoc.id;

    String? jksPassword;
    String? reviewerCertPath;
    String rejectionReason = '';
    bool isProcessing = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.rate_review, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Review: ${appData['title'] ?? 'Untitled'}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(appData),
                    const SizedBox(height: 16),
                    _buildDocumentReviewSection(appData),
                    const SizedBox(height: 16),
                    _buildDigitalSignatureSection(
                      appDoc,
                      (password) => jksPassword = password,
                      () => jksPassword,
                    ),
                    const SizedBox(height: 16),
                    _buildRejectionReasonField(
                      (reason) => rejectionReason = reason,
                    ),
                    if (isProcessing) _buildProcessingIndicator(),
                  ],
                ),
              ),
              actions: _buildDialogActions(
                context,
                setStateDialog,
                applicationId,
                appData,
                isProcessing,
                () => rejectionReason,
                () => jksPassword,
                () => reviewerCertPath,
                (processing) => isProcessing = processing,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> appData) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Application Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Template:', appData['templateId'] ?? 'N/A'),
            _buildInfoRow('Student ID:', appData['studentId'] ?? 'N/A'),
            _buildInfoRow('Status:', appData['status'] ?? 'pending'),
            _buildInfoRow(
              'Created:',
              _controller.formatDate(appData['createdAt']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDocumentReviewSection(Map<String, dynamic> appData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Document Review',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.download),
                label: Text(
                  _isLoading ? 'Downloading...' : 'Download Document',
                ),
                onPressed: _isLoading ? null : () => _downloadDocument(appData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalSignatureSection(
    DocumentSnapshot appDoc,
    Function(String) onPasswordChanged,
    String? Function() getPassword,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digital Signature',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Keystore Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    onChanged: onPasswordChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text("Sign"),
                onPressed: () async {
                  final password = getPassword();
                  if (password != null && password.isNotEmpty) {
                    await applicationController.signWithJKS(
                      appDoc.id,
                      password,
                    );
                  } else {
                    _showErrorSnackBar('Please enter keystore password');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionReasonField(Function(String) onChanged) {
    return TextField(
      decoration: const InputDecoration(
        labelText: 'Rejection Reason (if rejecting)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.comment),
      ),
      maxLines: 3,
      onChanged: onChanged,
    );
  }

  Widget _buildProcessingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Processing...'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDialogActions(
    BuildContext context,
    StateSetter setStateDialog,
    String applicationId,
    Map<String, dynamic> appData,
    bool isProcessing,
    String Function() getRejectionReason,
    String? Function() getJksPassword,
    String? Function() getReviewerCertPath,
    Function(bool) setProcessing,
  ) {
    return [
      TextButton(
        onPressed: isProcessing ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed:
            isProcessing
                ? null
                : () => _rejectApplication(
                  context,
                  setStateDialog,
                  applicationId,
                  getRejectionReason(),
                  setProcessing,
                ),
        child: const Text('Reject', style: TextStyle(color: Colors.red)),
      ),
      ElevatedButton(
        onPressed:
            isProcessing
                ? null
                : () => _approveApplication(
                  context,
                  setStateDialog,
                  applicationId,
                  appData,
                  getJksPassword(),
                  getReviewerCertPath(),
                  setProcessing,
                ),
        child: const Text('Approve'),
      ),
    ];
  }

  Future<void> _rejectApplication(
    BuildContext context,
    StateSetter setStateDialog,
    String applicationId,
    String rejectionReason,
    Function(bool) setProcessing,
  ) async {
    setProcessing(true);
    setStateDialog(() {});

    try {
      await _controller.rejectApplication(
        applicationId: applicationId,
        rejectionReason: rejectionReason,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar('Application rejected successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to reject application: ${e.toString()}');
      }
    } finally {
      setProcessing(false);
      setStateDialog(() {});
    }
  }

  Future<void> _approveApplication(
    BuildContext context,
    StateSetter setStateDialog,
    String applicationId,
    Map<String, dynamic> appData,
    String? jksPassword,
    String? reviewerCertPath,
    Function(bool) setProcessing,
  ) async {
    setProcessing(true);
    setStateDialog(() {});

    try {
      final message = await _controller.approveApplication(
        applicationId: applicationId,
        appData: appData,
        jksPassword: jksPassword,
        reviewerCertPath: reviewerCertPath,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar(message);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to approve application: ${e.toString()}');
      }
    } finally {
      setProcessing(false);
      setStateDialog(() {});
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  List<DocumentSnapshot> _filterDocuments(List<DocumentSnapshot> docs) {
    return _controller.filterDocuments(docs, _searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Review Applications'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStatusFilters(),
          _buildApplicationsList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search applications...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('All', 'all'),
          _buildFilterChip('Pending', 'pending'),
          _buildFilterChip('Approved', 'approved'),
          _buildFilterChip('Rejected', 'rejected'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _statusFilter = value;
            _updateFilters();
          });
        },
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue.shade700,
      ),
    );
  }

  Widget _buildApplicationsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _applicationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = _filterDocuments(snapshot.data!.docs);

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _initializeStream();
              });
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildApplicationCard(doc, data);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading applications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No applications match your search'
                : 'No applications found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Applications assigned to you will appear here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final status = data['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(_getStatusIcon(status), color: statusColor),
        ),
        title: Text(
          data['title'] ?? 'Untitled Application',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Student: ${data['studentId'] ?? 'Unknown'}'),
            Text('Template: ${data['templateId'] ?? 'N/A'}'),
            Text('Created: ${_controller.formatDate(data['createdAt'])}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showReviewDialog(doc),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }
}
