import 'staff.dart';

class StaffPermissions {
  // =========================================================
  // BILLING
  // =========================================================

  static bool canBilling(Staff? staff) {
    return staff != null && staff.isActive;
  }

  // =========================================================
  // PRODUCTS
  // =========================================================

  static bool canViewProducts(Staff? staff) {
    return staff != null && staff.isActive;
  }

  // =========================================================
  // PURCHASE
  // ADMIN ONLY
  // =========================================================

  static bool canPurchase(Staff? staff) {
    return staff != null &&
        staff.isActive &&
        staff.role == 'Admin';
  }

  // =========================================================
  // REPORTS
  // ADMIN ONLY
  // =========================================================

  static bool canReports(Staff? staff) {
    return staff != null &&
        staff.isActive &&
        staff.role == 'Admin';
  }

  // =========================================================
  // MASTER DATA
  // ADMIN ONLY
  // =========================================================

  static bool canMasterData(Staff? staff) {
    return staff != null &&
        staff.isActive &&
        staff.role == 'Admin';
  }

  // =========================================================
  // STAFF MANAGEMENT
  // ADMIN ONLY
  // =========================================================

  static bool canManageStaff(Staff? staff) {
    return staff != null &&
        staff.isActive &&
        staff.role == 'Admin';
  }

  // =========================================================
  // PRINTER
  // =========================================================

  static bool canPrinter(Staff? staff) {
    return staff != null && staff.isActive;
  }

  // =========================================================
  // SETTINGS
  // =========================================================

  static bool canSettings(Staff? staff) {
    return staff != null && staff.isActive;
  }

  // =========================================================
  // SHOP SETTINGS
  // ADMIN ONLY
  // =========================================================

  static bool canShopSettings(Staff? staff) {
    return staff != null &&
        staff.isActive &&
        staff.role == 'Admin';
  }

  // =========================================================
  // BILL SETTINGS
  // ADMIN ONLY
  // =========================================================

  static bool canBillSettings(Staff? staff) {
    return staff != null &&
        staff.isActive &&
        staff.role == 'Admin';
  }

  // =========================================================
  // DATABASE SETTINGS
  // ADMIN ONLY
  // =========================================================

  static bool canDatabaseSettings(Staff? staff) {
    return staff != null &&
        staff.isActive &&
        staff.role == 'Admin';
  }
}