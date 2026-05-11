import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/classes/presentation/controllers/admin_classes_controller.dart';
import 'package:qrollcall_mobile/features/classes/presentation/screens/create_class_screen.dart';
import 'package:qrollcall_mobile/features/classes/presentation/screens/admin_class_details_screen.dart';
import 'package:qrollcall_mobile/features/classes/presentation/controllers/admin_class_details_controller.dart';

enum AdminClassesExitAction { home, activity, profile }

class AdminClassesScreen extends StatefulWidget {
  const AdminClassesScreen({super.key});

  @override
  State<AdminClassesScreen> createState() => _AdminClassesScreenState();
}

class _AdminClassesScreenState extends State<AdminClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminClassesController>().loadClasses();
    });
  }

  Future<void> _openCreateClass() async {
    final controller = context.read<AdminClassesController>();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: controller,
          child: const CreateClassScreen(),
        ),
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminClassesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Classes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateClass,
        backgroundColor: AppColors.primaryContainer,
        child: const Icon(Icons.add),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => controller.loadClasses(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        controller.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  if (controller.createdClasses.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'You have not created any classes yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...controller.createdClasses.map(
                      (cls) => Card(
                        color: AppColors.surfaceContainerLow,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            cls['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            cls['location_name'] ?? 'No default location',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChangeNotifierProvider(
                                  create: (_) => AdminClassDetailsController(
                                    apiService: controller.apiService,
                                    classId: cls['id'],
                                  ),
                                  child: AdminClassDetailsScreen(className: cls['name'] ?? 'Class'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
