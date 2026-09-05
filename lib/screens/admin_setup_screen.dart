import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/staff.dart';
import '../providers/staff_provider.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() =>
      _AdminSetupScreenState();
}

class _AdminSetupScreenState
    extends State<AdminSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _usernameController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // =========================================================
  // CREATE ADMIN
  // =========================================================

  Future<void> _createAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    try {
      final provider =
      context.read<StaffProvider>();

      // =====================================================
      // CHECK USERNAME
      // =====================================================

      final existing =
      await provider.getStaffByUsername(
        _usernameController.text.trim(),
      );

      if (existing != null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Username already exists.',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      // =====================================================
      // CREATE ADMIN
      // =====================================================

      final admin = Staff(
        name: _nameController.text.trim(),
        username:
        _usernameController.text.trim(),
        password:
        _passwordController.text,
        role: 'Admin',
        isActive: true,
        createdAt:
        DateTime.now().toIso8601String(),
      );

      await provider.addStaff(admin);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admin account created successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // =====================================================
      // LOGIN SCREEN
      // =====================================================

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin setup failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 460,
            ),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      // =================================================
                      // ICON
                      // =================================================

                      CircleAvatar(
                        radius: 42,
                        backgroundColor:
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 44,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Admin Setup',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Create your administrator account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                          Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // =================================================
                      // NAME
                      // =================================================

                      TextFormField(
                        controller:
                        _nameController,
                        textInputAction:
                        TextInputAction.next,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Admin Name',
                          hintText:
                          'Enter admin name',
                          prefixIcon:
                          Icon(Icons.person),
                          border:
                          OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Please enter admin name';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // USERNAME
                      // =================================================

                      TextFormField(
                        controller:
                        _usernameController,
                        textInputAction:
                        TextInputAction.next,
                        decoration:
                        const InputDecoration(
                          labelText:
                          'Username',
                          hintText:
                          'Create username',
                          prefixIcon:
                          Icon(Icons.person_outline),
                          border:
                          OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final username =
                              value?.trim() ?? '';

                          if (username.isEmpty) {
                            return 'Please enter username';
                          }

                          if (username.length < 3) {
                            return 'Username must be at least 3 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // PASSWORD
                      // =================================================

                      TextFormField(
                        controller:
                        _passwordController,
                        obscureText:
                        _obscurePassword,
                        textInputAction:
                        TextInputAction.next,
                        decoration:
                        InputDecoration(
                          labelText:
                          'Password',
                          hintText:
                          'Create password',
                          prefixIcon:
                          const Icon(
                            Icons.lock,
                          ),
                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword =
                                !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons
                                  .visibility_off,
                            ),
                          ),
                          border:
                          const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please enter password';
                          }

                          if (value.length < 4) {
                            return 'Password must be at least 4 characters';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // CONFIRM PASSWORD
                      // =================================================

                      TextFormField(
                        controller:
                        _confirmPasswordController,
                        obscureText:
                        _obscureConfirmPassword,
                        textInputAction:
                        TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_saving) {
                            _createAdmin();
                          }
                        },
                        decoration:
                        InputDecoration(
                          labelText:
                          'Confirm Password',
                          hintText:
                          'Enter password again',
                          prefixIcon:
                          const Icon(
                            Icons.lock_reset,
                          ),
                          suffixIcon:
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons
                                  .visibility_off,
                            ),
                          ),
                          border:
                          const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty) {
                            return 'Please confirm password';
                          }

                          if (value !=
                              _passwordController.text) {
                            return 'Passwords do not match';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // =================================================
                      // ROLE
                      // =================================================

                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                            Colors.grey.shade300,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons
                                  .admin_panel_settings,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Role: Admin',
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // =================================================
                      // CREATE BUTTON
                      // =================================================

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child:
                        ElevatedButton.icon(
                          onPressed:
                          _saving
                              ? null
                              : _createAdmin,
                          icon: _saving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(
                            Icons
                                .admin_panel_settings,
                          ),
                          label: Text(
                            _saving
                                ? 'Creating...'
                                : 'CREATE ADMIN',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'This account will have full access to the POS.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}