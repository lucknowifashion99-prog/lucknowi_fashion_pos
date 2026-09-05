import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/staff.dart';
import '../../providers/staff_provider.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
    });
  }

  // =========================================================
  // ADD / EDIT STAFF
  // =========================================================

  Future<void> _showStaffDialog({
    Staff? staff,
  }) async {
    final isEdit = staff != null;

    final nameController = TextEditingController(
      text: staff?.name ?? '',
    );

    final usernameController = TextEditingController(
      text: staff?.username ?? '',
    );

    final passwordController = TextEditingController(
      text: staff?.password ?? '',
    );

    String selectedRole = staff?.role ?? 'Staff';

    try {
      await showDialog(
        context: context,
        builder: (dialogContext) {
          final formKey =
          GlobalKey<FormState>();

          bool obscurePassword = true;

          return StatefulBuilder(
            builder: (
                context,
                setDialogState,
                ) {
              return AlertDialog(
                title: Text(
                  isEdit
                      ? 'Edit Staff'
                      : 'Add Staff',
                ),
                content: SizedBox(
                  width: 430,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          // NAME
                          TextFormField(
                            controller:
                            nameController,
                            decoration:
                            const InputDecoration(
                              labelText: 'Staff Name',
                              prefixIcon:
                              Icon(
                                Icons.person,
                              ),
                              border:
                              OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Please enter staff name';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // USERNAME
                          TextFormField(
                            controller:
                            usernameController,
                            decoration:
                            const InputDecoration(
                              labelText: 'Username',
                              prefixIcon:
                              Icon(
                                Icons
                                    .account_circle,
                              ),
                              border:
                              OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Please enter username';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // PASSWORD
                          TextFormField(
                            controller:
                            passwordController,
                            obscureText:
                            obscurePassword,
                            decoration:
                            InputDecoration(
                              labelText: 'Password',
                              prefixIcon:
                              const Icon(
                                Icons.lock,
                              ),
                              suffixIcon:
                              IconButton(
                                onPressed: () {
                                  setDialogState(
                                        () {
                                      obscurePassword =
                                      !obscurePassword;
                                    },
                                  );
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons
                                      .visibility_off
                                      : Icons
                                      .visibility,
                                ),
                              ),
                              border:
                              const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value
                                      .trim()
                                      .isEmpty) {
                                return 'Please enter password';
                              }

                              if (value.trim().length <
                                  4) {
                                return 'Password must be at least 4 characters';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ROLE
                          DropdownButtonFormField<String>(
                            initialValue:
                            selectedRole,
                            decoration:
                            const InputDecoration(
                              labelText: 'Role',
                              prefixIcon:
                              Icon(
                                Icons
                                    .admin_panel_settings,
                              ),
                              border:
                              OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Admin',
                                child:
                                Text('Admin'),
                              ),
                              DropdownMenuItem(
                                value: 'Staff',
                                child:
                                Text('Staff'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }

                              setDialogState(() {
                                selectedRole =
                                    value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                    const Text('Cancel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (!formKey
                          .currentState!
                          .validate()) {
                        return;
                      }

                      final now =
                      DateTime.now()
                          .toIso8601String();

                      final newStaff = Staff(
                        id: staff?.id,
                        name: nameController
                            .text
                            .trim(),
                        username:
                        usernameController
                            .text
                            .trim(),
                        password:
                        passwordController
                            .text
                            .trim(),
                        role: selectedRole,
                        isActive:
                        staff?.isActive ??
                            true,
                        createdAt:
                        staff?.createdAt ??
                            now,
                      );

                      try {
                        final provider =
                        context.read<
                            StaffProvider>();

                        if (isEdit) {
                          await provider
                              .updateStaff(
                            newStaff,
                          );
                        } else {
                          await provider
                              .addStaff(
                            newStaff,
                          );
                        }

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                        );

                        ScaffoldMessenger
                            .of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Staff updated successfully'
                                  : 'Staff added successfully',
                            ),
                            backgroundColor:
                            Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger
                            .of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed: $e',
                            ),
                            backgroundColor:
                            Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(
                      Icons.save,
                    ),
                    label: Text(
                      isEdit
                          ? 'Update'
                          : 'Save',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      usernameController.dispose();
      passwordController.dispose();
    }
  }

  // =========================================================
  // DELETE STAFF
  // =========================================================

  Future<void> _deleteStaff(
      Staff staff,
      ) async {
    if (staff.id == null) {
      return;
    }

    final provider =
    context.read<StaffProvider>();

    if (provider.loggedInStaff?.id ==
        staff.id) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot delete the currently logged-in account.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    final confirm =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Staff',
          ),
          content: Text(
            'Delete ${staff.name} permanently?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await provider.deleteStaff(
        staff.id!,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Staff deleted successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete staff: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // ACTIVE / INACTIVE
  // =========================================================

  Future<void> _changeStatus(
      Staff staff,
      bool active,
      ) async {
    if (staff.id == null) {
      return;
    }

    final provider =
    context.read<StaffProvider>();

    if (provider.loggedInStaff?.id ==
        staff.id &&
        !active) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot deactivate the currently logged-in account.',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    try {
      await provider.setStaffActive(
        staff.id!,
        active,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            active
                ? 'Staff activated'
                : 'Staff deactivated',
          ),
          backgroundColor:
          active
              ? Colors.green
              : Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // STAFF CARD
  // =========================================================

  Widget _staffCard(
      BuildContext context,
      Staff staff,
      ) {
    final isAdmin =
        staff.role == 'Admin';

    final isActive =
        staff.isActive;

    return Card(
      elevation: 2,
      margin:
      const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor:
          isAdmin
              ? Colors.deepPurple
              .withValues(
            alpha: 0.12,
          )
              : Colors.blue.withValues(
            alpha: 0.12,
          ),
          child: Icon(
            isAdmin
                ? Icons.admin_panel_settings
                : Icons.person,
            color: isAdmin
                ? Colors.deepPurple
                : Colors.blue,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                staff.name,
                style: const TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green
                    .withValues(
                  alpha: 0.12,
                )
                    : Colors.red.withValues(
                  alpha: 0.12,
                ),
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Text(
                isActive
                    ? 'Active'
                    : 'Inactive',
                style: TextStyle(
                  color: isActive
                      ? Colors.green
                      : Colors.red,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding:
          const EdgeInsets.only(top: 5),
          child: Text(
            '@${staff.username} • ${staff.role}',
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showStaffDialog(
                staff: staff,
              );
            }

            if (value == 'status') {
              _changeStatus(
                staff,
                !staff.isActive,
              );
            }

            if (value == 'delete') {
              _deleteStaff(staff);
            }
          },
          itemBuilder: (context) {
            return [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading:
                  Icon(Icons.edit),
                  title:
                  Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: 'status',
                child: ListTile(
                  leading: Icon(
                    staff.isActive
                        ? Icons.block
                        : Icons.check_circle,
                  ),
                  title: Text(
                    staff.isActive
                        ? 'Deactivate'
                        : 'Activate',
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ];
          },
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(
      builder: (
          context,
          provider,
          child,
          ) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Staff Management',
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: provider.loading
                    ? null
                    : provider.loadStaff,
                icon: const Icon(
                  Icons.refresh,
                ),
                tooltip: 'Refresh',
              ),
            ],
          ),

          // =================================================
          // ADD STAFF
          // =================================================

          floatingActionButton:
          FloatingActionButton.extended(
            onPressed: () {
              _showStaffDialog();
            },
            icon: const Icon(
              Icons.person_add,
            ),
            label: const Text(
              'Add Staff',
            ),
          ),

          // =================================================
          // BODY
          // =================================================

          body: provider.loading
              ? const Center(
            child:
            CircularProgressIndicator(),
          )
              : provider.staff.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 80,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No Staff Found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            onRefresh:
            provider.loadStaff,
            child: ListView.builder(
              padding:
              const EdgeInsets.all(
                16,
              ),
              itemCount:
              provider.staff.length,
              itemBuilder:
                  (context, index) {
                final staff =
                provider.staff[
                index];

                return _staffCard(
                  context,
                  staff,
                );
              },
            ),
          ),
        );
      },
    );
  }
}