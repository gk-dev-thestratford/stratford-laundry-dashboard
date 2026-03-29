/// App-wide constants
class AppConstants {
  static const String appName = 'The Stratford Hotel';
  static const String appSubtitle = 'Laundry Management System';
  static const String hotelTagline = 'Autograph Collection';
  static const String laundryProvider = 'Laundrevo Limited';

  // Admin auto-lock timeout
  static const Duration adminTimeout = Duration(minutes: 5);

  // Order statuses
  static const String statusSubmitted = 'submitted';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusCollected = 'collected';
  static const String statusInProcessing = 'in_processing';
  static const String statusReceived = 'received';
  static const String statusCompleted = 'completed';
  static const String statusPickedUp = 'picked_up';
  static const String statusExpired = 'expired';

  // Completed order auto-collect (mark as picked_up after N days)
  static const int autoCollectDays = 21;

  // Completed order auto-expiry (archive after N days)
  static const int completedExpiryDays = 20;
  static const int completedExpiryWarningDays = 5;

  // Order types
  static const String orderTypeUniform = 'uniform';
  static const String orderTypeHskLinen = 'hsk_linen';
  static const String orderTypeFnbLinen = 'fnb_linen';
  static const String orderTypeGuestLaundry = 'guest_laundry';

  // Pool-tracked items (napkins use ledger-based tracking, not per-ticket)
  static const String napkinItemName = 'Linen Napkins';
  static const Set<String> poolTrackedItemNames = {'Napkin', 'Linen Napkins', 'napkin', 'linen napkins'};

  /// Whether an item name is pool-tracked (napkin)
  static bool isPoolTracked(String itemName) =>
      itemName.toLowerCase().contains('napkin');
}

/// Labels for display
class AppLabels {
  static const Map<String, String> orderTypeLabels = {
    AppConstants.orderTypeUniform: 'Staff Uniform',
    AppConstants.orderTypeHskLinen: 'Housekeeping Linen',
    AppConstants.orderTypeFnbLinen: 'F&B Linen',
    AppConstants.orderTypeGuestLaundry: 'Guest / Resident Laundry',
  };

  static const Map<String, String> statusLabels = {
    AppConstants.statusSubmitted: 'Submitted',
    AppConstants.statusApproved: 'Approved',
    AppConstants.statusRejected: 'Rejected',
    AppConstants.statusCollected: 'Collected',
    AppConstants.statusInProcessing: 'In Processing',
    AppConstants.statusReceived: 'Received',
    AppConstants.statusCompleted: 'Returned',
    AppConstants.statusPickedUp: 'Picked Up',
    AppConstants.statusExpired: 'Expired',
  };
}
