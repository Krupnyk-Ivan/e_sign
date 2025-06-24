import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:e_sign/services/database_service.dart';
import 'package:e_sign/services/application_service.dart';
import 'package:e_sign/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminController extends ChangeNotifier {
  // Services
  final DatabaseService _databaseService = DatabaseService();
  final ApplicationService _applicationService = ApplicationService();
  final StorageService _storageService = StorageService();

  // State variables
  bool _requiresReview = true;
  bool _requiresSignature = true;
  String? _selectedReviewerId = "";
  List<Map<String, dynamic>> _reviewers = [];
  File? _selectedTemplateFile;
  List<Map<String, String>> _allUsers = [];
  List<Map<String, String>> _filteredUsers = [];
  bool _expanded = false;
  bool _isLoading = false;

  // Controllers
  final TextEditingController searchController = TextEditingController();
  final TextEditingController templateTitleController = TextEditingController();

  // Getters
  bool get requiresReview => _requiresReview;
  bool get requiresSignature => _requiresSignature;
  String? get selectedReviewerId => _selectedReviewerId;
  List<Map<String, dynamic>> get reviewers => _reviewers;
  File? get selectedTemplateFile => _selectedTemplateFile;
  List<Map<String, String>> get allUsers => _allUsers;
  List<Map<String, String>> get filteredUsers => _filteredUsers;
  bool get expanded => _expanded;
  bool get isLoading => _isLoading;

  AdminController() {
    searchController.addListener(_filterUsers);
    _initialize();
  }

  Future<void> _initialize() async {
    await loadReviewers();
  }

  // User Management Logic
  void updateUsers(List<Map<String, String>> users) {
    _allUsers = users;
    _filterUsers();
    notifyListeners();
  }

  void _filterUsers() {
    final query = searchController.text.toLowerCase();
    if (query.isEmpty) {
      _filteredUsers = _allUsers;
    } else {
      _filteredUsers =
          _allUsers.where((user) {
            return user['email']?.toLowerCase().contains(query) ?? false;
          }).toList();
    }
    notifyListeners();
  }

  void toggleExpanded() {
    _expanded = !_expanded;
    notifyListeners();
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.update(
        path: "users/$userId",
        data: {"role": newRole},
      );

      _isLoading = false;
      notifyListeners();
      return; // Success - no error to throw
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception("Failed to update role: $e");
    }
  }

  Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.deepPurple;
      case 'reviewer':
        return Colors.blue;
      case 'applicant':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Template Management Logic
  Future<void> loadReviewers() async {
    try {
      _isLoading = true;
      notifyListeners();

      List<Map<String, dynamic>> fetchedReviewers =
          await _databaseService.getReviewers();
      print('Reviewer IDs for dropdown:');
      for (var r in fetchedReviewers) {
        print(r['id']);
      }

      _reviewers = fetchedReviewers;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception("Failed to load reviewers: $e");
    }
  }

  void setRequiresReview(bool value) {
    _requiresReview = value;
    notifyListeners();
  }

  void setRequiresSignature(bool value) {
    _requiresSignature = value;
    notifyListeners();
  }

  void setSelectedReviewerId(String? reviewerId) {
    _selectedReviewerId = reviewerId;
    notifyListeners();
  }

  Future<void> pickTemplateFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        _selectedTemplateFile = File(result.files.single.path!);
        notifyListeners();
      }
    } catch (e) {
      throw Exception("Failed to pick file: $e");
    }
  }

  Future<void> uploadTemplate() async {
    if (_selectedTemplateFile == null || templateTitleController.text.isEmpty) {
      throw Exception(
        "Please select a file and enter a title for the template.",
      );
    }

    try {
      _isLoading = true;
      notifyListeners();

      final fileName = _selectedTemplateFile!.path.split('/').last;
      final templateStoragePath = await _storageService.uploadTemplate(
        _selectedTemplateFile!,
        fileName,
      );

      await _applicationService.addDocumentTemplateWithSettings(
        title: templateTitleController.text,
        storagePath: templateStoragePath,
        targetUsers: [],
        reviewerId: _selectedReviewerId,
        requiresReview: _requiresReview,
        requiresSignature: _requiresSignature,
      );

      // Reset form
      _selectedTemplateFile = null;
      templateTitleController.clear();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception("Failed to upload template: $e");
    }
  }

  Future<void> deleteTemplate(String templateId, String storagePath) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _storageService.deleteFileByPath(storagePath);
      await _applicationService.deleteDocumentTemplate(templateId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception("Failed to delete template: $e");
    }
  }

  void clearTemplateForm() {
    _selectedTemplateFile = null;
    templateTitleController.clear();
    notifyListeners();
  }

  // Streams for reactive UI
  Stream<List<Map<String, String>>> getUsersStream() {
    return _databaseService.getUsersStream();
  }

  Stream<QuerySnapshot> getDocumentTemplatesStream() {
    return _applicationService.getDocumentTemplates();
  }

  @override
  void dispose() {
    searchController.removeListener(_filterUsers);
    searchController.dispose();
    templateTitleController.dispose();
    super.dispose();
  }
}
