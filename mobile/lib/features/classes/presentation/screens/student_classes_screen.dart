import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/classes/presentation/controllers/student_classes_controller.dart';
import 'package:qrollcall_mobile/features/classes/data/classes_api_service.dart';
import 'package:qrollcall_mobile/features/classes/presentation/controllers/student_class_details_controller.dart';
import 'package:qrollcall_mobile/features/classes/presentation/screens/student_class_details_screen.dart';
import 'package:qrollcall_mobile/features/auth/data/firebase_auth_service.dart';

enum ClassesExitAction { home, scan, history, profile }

class StudentClassesScreen extends StatefulWidget {
  const StudentClassesScreen({super.key});

  @override
  State<StudentClassesScreen> createState() => _StudentClassesScreenState();
}

class _StudentClassesScreenState extends State<StudentClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentClassesController>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentClassesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Classes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => controller.loadData(),
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
                  if (controller.invitations.isNotEmpty) ...[
                    Text(
                      'Pending Invitations',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ...controller.invitations.map((inv) => _buildInviteCard(context, controller, inv)),
                    const SizedBox(height: 32),
                  ],
                  Text(
                    'Joined Classes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (controller.joinedClasses.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'You have not joined any classes yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...controller.joinedClasses.map((cls) => _buildClassCard(context, cls)),
                ],
              ),
            ),
    );
  }

  Widget _buildInviteCard(BuildContext context, StudentClassesController controller, dynamic inv) {
    return Card(
      color: AppColors.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inv['class_name'] ?? 'Unknown Class',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Teacher: ${inv['teacher_name']}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.declineInvitation(inv['id'] as int),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.acceptInvitation(inv['id'] as int),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.textPrimary,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, dynamic cls) {
    return Card(
      color: AppColors.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          cls['location_name'] ?? 'No location set',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => StudentClassDetailsController(
                  classId: cls['id'] as int,
                  apiService: ClassesApiService(
                    firebaseAuthService: context.read<FirebaseAuthService>(),
                  ),
                ),
                child: StudentClassDetailsScreen(className: cls['name'] ?? 'Class Details'),
              ),
            ),
          );
        },
      ),
    );
  }
}
