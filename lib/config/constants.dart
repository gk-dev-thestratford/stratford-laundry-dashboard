/// App-wide constants
class AppConstants {
  static const String appName = 'The Stratford Hotel';
  static const String appSubtitle = 'Laundry Management System';
  static const String hotelTagline = 'Autograph Collection';
  static const String laundryProvider = 'Laundrevo Limited';

  // Admin auto-lock timeout
  static const Duration adminTimeout = Duration(minutes: 5);

  // Order statuses — five-stage model (renamed 2026-06-12):
  // submitted -> approved -> sent -> received -> collected (+ rejected, expired)
  static const String statusSubmitted = 'submitted';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  /// Laundry company collected the items for washing (was 'collected'/'in_processing')
  static const String statusSent = 'sent';
  /// Items back from the laundry company, in the laundry room (was 'received'/'completed')
  static const String statusReceived = 'received';
  /// The owner (staff member) picked up their items (was 'picked_up')
  static const String statusCollected = 'collected';
  static const String statusExpired = 'expired';

  // Received order auto-collect (mark as collected after N days)
  static const int autoCollectDays = 21;

  // Received order auto-expiry (archive after N days)
  static const int receivedExpiryDays = 20;
  static const int receivedExpiryWarningDays = 5;

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
    AppConstants.statusSent: 'Sent',
    AppConstants.statusReceived: 'Received',
    AppConstants.statusCollected: 'Collected',
    AppConstants.statusExpired: 'Expired',
    // Legacy display fallbacks — stale local status-log rows written before
    // the 2026-06-12 rename still render with the new vocabulary.
    'in_processing': 'Sent',
    'completed': 'Received',
    'picked_up': 'Collected',
  };
}
