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
  int _geofenceRadius = 300;
  bool _isSaving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    final success = await context.read<AdminClassesController>().createClass({
      'name': _name.trim(),
      'description': _description.trim().isEmpty ? null : _description.trim(),
      'location_name':
          _locationName.trim().isEmpty ? null : _locationName.trim(),
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
      body:
          _isSaving
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
                        validator: (val) {
                          final value = val?.trim() ?? '';
                          if (value.isEmpty) return 'Class name is required';
                          if (value.length < 2) {
                            return 'Class name must be at least 2 characters';
                          }
                          return null;
                        },
                        onSaved: (val) => _name = val?.trim() ?? '',
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
                        initialValue: '300',
                        validator: (val) {
                          final radius = int.tryParse(val?.trim() ?? '');
                          if (radius == null) return 'Enter a number';
                          if (radius < 25 || radius > 10000) {
                            return 'Use a radius between 25 and 10000 meters';
                          }
                          return null;
                        },
                        onSaved:
                            (val) =>
                                _geofenceRadius =
                                    int.tryParse(val?.trim() ?? '300') ?? 300,
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
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Create Class',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
