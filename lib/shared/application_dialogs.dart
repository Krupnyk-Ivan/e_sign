import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'application_controller.dart';

class ApplicationDialogs {
  static void showApplicationDetails(
    BuildContext context,
    DocumentSnapshot appDoc,
    ApplicationController controller,
  ) {
    final appData = appDoc.data() as Map<String, dynamic>;
    final appId = appDoc.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.assignment),
                    title: Text(appData['title'] ?? 'Application'),
                    subtitle: Text("Status: ${appData['status'] ?? 'Unknown'}"),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Attached Documents",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (appData['documents'] != null)
                    ...(appData['documents'] as List<dynamic>).map(
                      (doc) => ListTile(
                        leading: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red,
                        ),
                        title: Text(doc['name'] ?? 'Document'),
                        trailing: const Icon(Icons.download),
                        onTap:
                            () => controller.downloadDocument(
                              documentName: doc['name'],
                              applicationId: appId,
                            ),
                      ),
                    ),
                  if (appData['documentPath'] != null)
                    ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.red,
                      ),
                      title: const Text('Main Document'),
                      trailing: const Icon(Icons.download),
                      onTap:
                          () => controller.downloadMainDocument(
                            documentUrl: appData['documentPath'],
                            applicationId: appId,
                          ),
                    ),
                  if (appData['signaturePath'] != null)
                    ListTile(
                      leading: const Icon(Icons.verified, color: Colors.green),
                      title: const Text('Digital Signature'),
                      trailing: const Icon(Icons.download),
                      onTap:
                          () => controller.downloadSignature(
                            signatureUrl: appData['signaturePath'],
                            applicationId: appId,
                          ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.attach_file),
                          label: const Text("Attach Document"),
                          onPressed: () async {
                            await controller.attachDocument(appId);
                            setModalState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (appData['status'] == 'submitted' ||
                          appData['status'] == 'pending')
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Sign Document"),
                            onPressed:
                                () =>
                                    showSignDialog(context, appDoc, controller),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showTemplateSelectionDialog(
    BuildContext context,
    ApplicationController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Application Template'),
          content: SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: controller.getDocumentTemplates(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading templates: ${snapshot.error}'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No templates available.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final templateTitle = data['title'] as String? ?? 'Unnamed';
                    final templatePath = data['storagePath'] as String?;

                    return ListTile(
                      leading: const Icon(Icons.description),
                      title: Text(templateTitle),
                      subtitle:
                          templatePath != null
                              ? const Text('Has template document')
                              : null,
                      onTap: () async {
                        Navigator.pop(context);
                        await controller.createApplicationFromTemplate(
                          doc.id,
                          templateTitle,
                          templatePath,
                        );
                      },
                    );
                  },
                );
              },
            ),
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
  }

  static void showSignDialog(
    BuildContext context,
    DocumentSnapshot appDoc,
    ApplicationController controller,
  ) {
    final TextEditingController passwordController = TextEditingController();
    String jksPassword = '';
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final appData = appDoc.data() as Map<String, dynamic>;
            return AlertDialog(
              title: const Text('Sign Document'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sign "${appData['title'] ?? 'Application'}" with your digital certificate?',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Keystore Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    enabled: !isLoading,
                    onChanged: (value) => jksPassword = value,
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Signing document...'),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon:
                      isLoading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.edit),
                  label: Text(isLoading ? 'Signing...' : 'Sign'),
                  onPressed:
                      isLoading
                          ? null
                          : () async {
                            setDialogState(() => isLoading = true);
                            await controller.signWithJKS(
                              appDoc.id,
                              jksPassword,
                            );
                            Navigator.of(dialogContext).pop();
                          },
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showEditDialog(
    BuildContext context,
    DocumentSnapshot appDoc,
    ApplicationController controller,
  ) {
    final appData = appDoc.data() as Map<String, dynamic>;
    final TextEditingController titleController = TextEditingController();
    titleController.text = appData['title'] ?? '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Application'),
            content: TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Application Title',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    await controller.updateApplication(
                      appDoc.id,
                      titleController.text,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  static void showDeleteDialog(
    BuildContext context,
    DocumentSnapshot appDoc,
    ApplicationController controller,
  ) {
    final appData = appDoc.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Application'),
            content: Text(
              'Are you sure you want to delete "${appData['title'] ?? 'this application'}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.deleteApplication(appDoc.id);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
