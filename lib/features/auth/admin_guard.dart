import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/staff_provider.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(
      builder: (
          context,
          staffProvider,
          _,
          ) {
        if (staffProvider.isAdmin) {
          return child;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Access Denied',
            ),
            centerTitle: true,
          ),
          body: Center(
            child: Padding(
              padding:
              const EdgeInsets.all(24),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  const Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Only Admin can access this section.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color:
                      Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                    ),
                    label: const Text(
                      'Go Back',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}