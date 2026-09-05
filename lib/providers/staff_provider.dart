import 'package:flutter/material.dart';

import '../models/staff.dart';
import '../repositories/staff_repository.dart';

class StaffProvider extends ChangeNotifier {
  final StaffRepository _repository =
  StaffRepository();

  List<Staff> _staff = [];

  Staff? _loggedInStaff;

  bool _loading = false;

  // =========================================================
  // GETTERS
  // =========================================================

  List<Staff> get staff =>
      List.unmodifiable(_staff);

  Staff? get loggedInStaff =>
      _loggedInStaff;

  bool get loading => _loading;

  bool get isLoggedIn =>
      _loggedInStaff != null;

  bool get isAdmin =>
      _loggedInStaff?.role == 'Admin';

  bool get isStaff =>
      _loggedInStaff?.role == 'Staff';

  // =========================================================
  // LOAD STAFF
  // =========================================================

  Future<void> loadStaff() async {
    _loading = true;
    notifyListeners();

    try {
      _staff =
      await _repository.getAll();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // =========================================================
  // GET STAFF BY USERNAME
  // =========================================================

  Future<Staff?> getStaffByUsername(
      String username,
      ) async {
    final cleanUsername =
    username.trim();

    if (cleanUsername.isEmpty) {
      return null;
    }

    return await _repository
        .getByUsername(cleanUsername);
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<bool> login(
      String username,
      String password,
      ) async {
    final cleanUsername =
    username.trim();

    final cleanPassword =
    password.trim();

    if (cleanUsername.isEmpty ||
        cleanPassword.isEmpty) {
      return false;
    }

    final staff =
    await _repository.login(
      cleanUsername,
      cleanPassword,
    );

    if (staff == null) {
      return false;
    }

    _loggedInStaff = staff;

    notifyListeners();

    return true;
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  void logout() {
    _loggedInStaff = null;
    notifyListeners();
  }

  // =========================================================
  // ADD STAFF
  // =========================================================

  Future<void> addStaff(
      Staff staff,
      ) async {
    await _repository.insert(staff);
    await loadStaff();
  }

  // =========================================================
  // UPDATE STAFF
  // =========================================================

  Future<void> updateStaff(
      Staff staff,
      ) async {
    await _repository.update(staff);

    if (_loggedInStaff?.id == staff.id) {
      _loggedInStaff = staff;
    }

    await loadStaff();
  }

  // =========================================================
  // DELETE STAFF
  // =========================================================

  Future<void> deleteStaff(
      int id,
      ) async {
    await _repository.delete(id);

    if (_loggedInStaff?.id == id) {
      _loggedInStaff = null;
    }

    await loadStaff();
  }

  // =========================================================
  // ACTIVE / INACTIVE
  // =========================================================

  Future<void> setStaffActive(
      int id,
      bool active,
      ) async {
    await _repository.setActive(
      id,
      active,
    );

    if (_loggedInStaff?.id == id &&
        !active) {
      _loggedInStaff = null;
    }

    await loadStaff();
  }
}