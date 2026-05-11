import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/classes/presentation/controllers/student_class_details_controller.dart';

class StudentClassDetailsScreen extends StatefulWidget {
  const StudentClassDetailsScreen({super.key, required this.className});
  
  final String className;

  @override
  State<StudentClassDetailsScreen> createState() => _StudentClassDetailsScreenState();
}

class _StudentClassDetailsScreenState extends State<StudentClassDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentClassDetailsController>().loadDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StudentClassDetailsController>();
    final details = controller.classDetails;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.className),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null
              ? _buildErrorView(controller.errorMessage!)
              : details == null
                  ? const Center(child: Text('No details found', style: TextStyle(color: AppColors.textSecondary)))
                  : _buildDetailsView(details),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<StudentClassDetailsController>().loadDetails(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsView(Map<String, dynamic> details) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildInfoCard(
          icon: Icons.school_rounded,
          title: 'Class Information',
          items: [
            _InfoRow(label: 'Name', value: details['name'] ?? 'N/A'),
            _InfoRow(label: 'Code', value: details['class_code'] ?? 'None'),
            _InfoRow(label: 'Location', value: details['location_name'] ?? 'Remote/TBD'),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          icon: Icons.person_rounded,
          title: 'Instructor',
          items: [
             _InfoRow(label: 'Teacher ID', value: '#${details['teacher_user_id']}'),
             const Text('Additional teacher info can be added here once profiles are expanded.', 
               style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
        const SizedBox(height: 20),
        _buildAttendanceSummary(),
      ],
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required List<Widget> items}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryContainer, size: 24),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),
          ...items,
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryContainer.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 16),
          Text(
            'Individual class statistics will be available in the full release. Please check the main dashboard for your overall attendance rate.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
