import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/staff_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey =
  GlobalKey<FormState>();

  final _usernameController =
  TextEditingController();

  final _passwordController =
  TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final provider =
    context.read<StaffProvider>();

    final success =
    await provider.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (!success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid username or password',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final staff =
        provider.loggedInStaff;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          'Welcome ${staff?.name ?? ''}',
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Login successful.
    //
    // Dashboard navigation hum next step mein
    // connect karenge.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 430,
            ),
            child: Card(
              elevation: 6,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(24),
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      // LOGO
                      CircleAvatar(
                        radius: 42,
                        backgroundColor:
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        child: Icon(
                          Icons.storefront,
                          size: 45,
                          color:
                          Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      const Text(
                        'Lucknowi Fashion',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      const Text(
                        'POS Login',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                          Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      // USERNAME
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
                          'Enter username',
                          prefixIcon:
                          Icon(
                            Icons.person,
                          ),
                          border:
                          OutlineInputBorder(),
                        ),
                        validator:
                            (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return
                              'Please enter username';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // PASSWORD
                      TextFormField(
                        controller:
                        _passwordController,
                        obscureText:
                        _obscurePassword,
                        textInputAction:
                        TextInputAction.done,
                        onFieldSubmitted:
                            (_) {
                          if (!_loading) {
                            _login();
                          }
                        },
                        decoration:
                        InputDecoration(
                          labelText:
                          'Password',
                          hintText:
                          'Enter password',
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
                                  ? Icons
                                  .visibility
                                  : Icons
                                  .visibility_off,
                            ),
                          ),
                          border:
                          const OutlineInputBorder(),
                        ),
                        validator:
                            (value) {
                          if (value == null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return
                              'Please enter password';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // LOGIN BUTTON
                      SizedBox(
                        width:
                        double.infinity,
                        height: 50,
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
                              strokeWidth:
                              2,
                            ),
                          )
                              : const Icon(
                            Icons.login,
                          ),
                          label: Text(
                            _loading
                                ? 'Logging in...'
                                : 'LOGIN',
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // DEFAULT LOGIN INFO
                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                        BoxDecoration(
                          border: Border.all(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            12,
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Default Admin',
                              style:
                              TextStyle(
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Username: admin',
                            ),
                            Text(
                              'Password: admin123',
                            ),
                          ],
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