import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qrollcall_mobile/core/theme/app_colors.dart';
import 'package:qrollcall_mobile/features/classes/presentation/controllers/admin_classes_controller.dart';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  String _locationName = '';
  int _geofenceRadius = 100;
  bool _isSaving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    
    final success = await context.read<AdminClassesController>().createClass({
      'name': _name,
      'description': _description,
      'location_name': _locationName,
      'default_geofence_radius_meters': _geofenceRadius,
    });

    setState(() => _isSaving = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create New Class'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Class Name',
                        fillColor: AppColors.surfaceContainerLow,
                        filled: true,
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => _name = val!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        fillColor: AppColors.surfaceContainerLow,
                        filled: true,
                      ),
                      onSaved: (val) => _description = val ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Default Location Name',
                        fillColor: AppColors.surfaceContainerLow,
                        filled: true,
                      ),
                      onSaved: (val) => _locationName = val ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Default Geofence Radius (meters)',
                        fillColor: AppColors.surfaceContainerLow,
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '100',
                      onSaved: (val) =>
                          _geofenceRadius = int.tryParse(val ?? '100') ?? 100,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                        ),
                        child: const Text('Create Class'),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
