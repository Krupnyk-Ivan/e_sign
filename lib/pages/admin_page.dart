import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../shared/admin_controller.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminController(),
      child: const AdminPageView(),
    );
  }
}

class AdminPageView extends StatelessWidget {
  const AdminPageView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: Consumer<AdminController>(
        builder: (context, controller, child) {
          return StreamBuilder<List<Map<String, String>>>(
            stream: controller.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No users found."));
              }

              bool _initialized = false;

              if (!_initialized && snapshot.hasData) {
                _initialized = true;
                controller.updateUsers(snapshot.data!);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await controller.loadReviewers();
                },
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    _SearchBar(),
                    const SizedBox(height: 20),
                    _UserList(),
                    const SizedBox(height: 40),
                    _DocumentTemplatesSection(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context, listen: false);

    return TextField(
      controller: controller.searchController,
      decoration: InputDecoration(
        labelText: 'Search Users',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        final users = controller.filteredUsers;
        final visibleUsers =
            controller.expanded ? users : users.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Users",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (visibleUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text("No users match your search.")),
              )
            else
              ...visibleUsers.map((user) => _UserCard(user: user)),
            if (users.length > 5)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.toggleExpanded,
                  icon: Icon(
                    controller.expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(controller.expanded ? "Show Less" : "Show All"),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, String> user;

  const _UserCard({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context, listen: false);
    final String role = user['role'] ?? 'N/A';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(user['email'] ?? 'No Email'),
        subtitle: Text(
          "Role: ${role[0].toUpperCase()}${role.substring(1)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: controller.getRoleColor(role),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showRoleSelectionDialog(context, user),
      ),
    );
  }

  Future<void> _showRoleSelectionDialog(
    BuildContext context,
    Map<String, String> user,
  ) async {
    final controller = Provider.of<AdminController>(context, listen: false);

    final selectedRole = await showDialog<String>(
      context: context,
      builder: (context) {
        const roles = ['applicant', 'reviewer', 'admin'];
        return AlertDialog(
          title: Text("Change Role for ${user['email']}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                roles
                    .map(
                      (role) => ListTile(
                        title: Text(role[0].toUpperCase() + role.substring(1)),
                        onTap: () => Navigator.pop(context, role),
                      ),
                    )
                    .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (selectedRole != null && selectedRole != user['role']) {
      try {
        await controller.updateUserRole(user['id']!, selectedRole);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("User role updated to $selectedRole"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class _DocumentTemplatesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Document Templates",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _DocumentTemplatesCard(),
        const SizedBox(height: 20),
        _TemplateList(),
      ],
    );
  }
}

class _DocumentTemplatesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.description, size: 28, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Manage Existing Templates",
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
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showUploadTemplateDialog(context),
                icon: const Icon(Icons.add),
                label: const Text("Upload New Template"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadTemplateDialog(BuildContext context) {
    final controller = Provider.of<AdminController>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<AdminController>(
          builder: (context, controller, child) {
            return AlertDialog(
              title: const Text('Upload New Document Template'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller.templateTitleController,
                      decoration: InputDecoration(
                        labelText: 'Template Title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await controller.pickTemplateFile();
                          if (context.mounted) {
                            Navigator.pop(context);
                            _showUploadTemplateDialog(context);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select File'),
                    ),
                    if (controller.selectedTemplateFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          'Selected: ${controller.selectedTemplateFile!.path.split('/').last}',
                        ),
                      ),
                    const SizedBox(height: 20),
                    _ReviewerSelector(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    controller.clearTemplateForm();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      controller.isLoading
                          ? null
                          : () async {
                            try {
                              await controller.uploadTemplate();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Document template uploaded successfully!",
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                  child:
                      controller.isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Upload Template'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ReviewerSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AdminController>(
      builder: (context, controller, child) {
        return TextFormField(
          readOnly: true,
          decoration: const InputDecoration(labelText: 'Select Reviewer'),
          controller: TextEditingController(
            text: controller.selectedReviewerId,
          ),
          onTap: () async {
            final selected = await showModalBottomSheet<String>(
              context: context,
              builder:
                  (context) => ListView(
                    children:
                        controller.reviewers.map((reviewer) {
                          final email = reviewer['email'].toString();
                          return ListTile(
                            title: Text(email),
                            onTap: () => Navigator.pop(context, reviewer['id']),
                          );
                        }).toList(),
                  ),
            );
            if (selected != null) {
              controller.setSelectedReviewerId(selected);
            }
          },
        );
      },
    );
  }
}

class _TemplateList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context, listen: false);

    return StreamBuilder(
      stream: controller.getDocumentTemplatesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Error loading templates: ${snapshot.error}"),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No document templates found."));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final templateData = doc.data() as Map<String, dynamic>;
            final title = templateData['title'] ?? 'No Title';
            final storagePath = templateData['storagePath'] ?? '';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(title),
                trailing: Consumer<AdminController>(
                  builder: (context, controller, child) {
                    return IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed:
                          controller.isLoading
                              ? null
                              : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Delete Template'),
                                        content: Text(
                                          'Are you sure you want to delete "$title"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirmed == true) {
                                  try {
                                    await controller.deleteTemplate(
                                      doc.id,
                                      storagePath,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Template deleted successfully!",
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceFirst(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
