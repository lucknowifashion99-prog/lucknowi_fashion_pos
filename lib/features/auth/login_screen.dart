import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/staff_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _login() async {
    if (_loading) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      final success = await context
          .read<StaffProvider>()
          .login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Invalid username or password, or account is inactive.',
              ),
              backgroundColor: Colors.red,
            ),
          );

        return;
      }

      // =====================================================
      // LOGIN SUCCESS
      // =====================================================
      //
      // app.dart Consumer<StaffProvider> automatically
      // DashboardScreen show karega.
      //
      // Isliye yahan Navigator ki zarurat nahi hai.
      // =====================================================

    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Login failed: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // =================================================
                        // LOGO
                        // =================================================

                        CircleAvatar(
                          radius: 42,
                          backgroundColor:
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            Icons.store,
                            size: 46,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'Lucknowi Fashion',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'POS Login',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                            Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // =================================================
                        // USERNAME
                        // =================================================

                        TextFormField(
                          controller:
                          _usernameController,
                          enabled: !_loading,
                          textInputAction:
                          TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.username,
                          ],
                          decoration:
                          InputDecoration(
                            labelText: 'Username',
                            hintText:
                            'Enter username',
                            prefixIcon:
                            const Icon(
                              Icons
                                  .account_circle,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(14),
                            ),
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

                        const SizedBox(height: 16),

                        // =================================================
                        // PASSWORD
                        // =================================================

                        TextFormField(
                          controller:
                          _passwordController,
                          enabled: !_loading,
                          obscureText:
                          _obscurePassword,
                          textInputAction:
                          TextInputAction.done,
                          autofillHints: const [
                            AutofillHints.password,
                          ],
                          onFieldSubmitted: (_) {
                            _login();
                          },
                          decoration:
                          InputDecoration(
                            labelText: 'Password',
                            hintText:
                            'Enter password',
                            prefixIcon:
                            const Icon(
                              Icons.lock,
                            ),
                            suffixIcon:
                            IconButton(
                              onPressed:
                              _loading
                                  ? null
                                  : () {
                                setState(
                                      () {
                                    _obscurePassword =
                                    !_obscurePassword;
                                  },
                                );
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons
                                    .visibility_off
                                    : Icons
                                    .visibility,
                              ),
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(14),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Please enter password';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // =================================================
                        // LOGIN BUTTON
                        // =================================================

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child:
                          ElevatedButton.icon(
                            onPressed:
                            _loading
                                ? null
                                : _login,
                            icon: _loading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(
                              Icons.login,
                            ),
                            label: Text(
                              _loading
                                  ? 'Signing in...'
                                  : 'LOGIN',
                              style:
                              const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Authorized staff only',
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
      ),
    );
  }
}