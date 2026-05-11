import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/classes/presentation/controllers/admin_class_details_controller.dart';

class AdminClassDetailsScreen extends StatefulWidget {
  const AdminClassDetailsScreen({super.key, required this.className});
  
  final String className;

  @override
  State<AdminClassDetailsScreen> createState() => _AdminClassDetailsScreenState();
}

class _AdminClassDetailsScreenState extends State<AdminClassDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminClassDetailsController>().loadDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showInviteDialog() async {
    final controller = context.read<AdminClassDetailsController>();
    final identifierController = TextEditingController();
    bool isUsername = false;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Invite Student', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('By Email', style: TextStyle(color: Colors.white)),
                      Switch(
                        value: isUsername,
                        onChanged: (val) => setState(() => isUsername = val),
                        activeColor: AppColors.primaryContainer,
                      ),
                      const Text('By Username', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: identifierController,
                    decoration: InputDecoration(
                      labelText: isUsername ? 'Student Username' : 'Student Email',
                      fillColor: AppColors.surfaceContainerLow,
                      filled: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final identifier = identifierController.text.trim();
                          if (identifier.isEmpty) return;
                          
                          setState(() => isSubmitting = true);
                          final success = await controller.inviteUser(identifier, isUsername: isUsername);
                          if (success && ctx.mounted) {
                            Navigator.of(ctx).pop();
                          } else {
                            setState(() => isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
                  child: isSubmitting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Invite'),
                )
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminClassDetailsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.className),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryContainer,
          labelColor: AppColors.primaryContainer,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Roster'),
            Tab(text: 'Invitations'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInviteDialog,
        backgroundColor: AppColors.primaryContainer,
        icon: const Icon(Icons.person_add),
        label: const Text('Invite'),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRosterTab(controller),
                _buildInvitationsTab(controller),
              ],
            ),
    );
  }

  Widget _buildRosterTab(AdminClassDetailsController controller) {
    if (controller.students.isEmpty) {
      return const Center(
        child: Text('No students in this class yet.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: controller.students.length,
      itemBuilder: (context, index) {
        final student = controller.students[index];
        return Card(
          color: AppColors.surfaceContainerLow,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(student['full_name'] ?? 'Unknown', style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text(student['email'] ?? '', style: const TextStyle(color: AppColors.textSecondary)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                student['status'] ?? 'ACTIVE',
                style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitationsTab(AdminClassDetailsController controller) {
    if (controller.invitations.isEmpty) {
      return const Center(
        child: Text('No sent invitations.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: controller.invitations.length,
      itemBuilder: (context, index) {
        final inv = controller.invitations[index];
        final identifier = inv['invited_email'] ?? inv['invited_username'] ?? 'Unknown';
        final status = inv['status'] ?? 'PENDING';
        
        Color statusColor = AppColors.textSecondary;
        if (status == 'ACCEPTED') statusColor = AppColors.success;
        if (status == 'DECLINED' || status == 'EXPIRED') statusColor = AppColors.error;

        return Card(
          color: AppColors.surfaceContainerLow,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(identifier, style: const TextStyle(color: AppColors.textPrimary)),
            subtitle: Text('Added: ${inv['created_at'].toString().split('T').first}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            trailing: Text(
              status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
