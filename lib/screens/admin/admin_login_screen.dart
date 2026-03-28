import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/admin_user.dart';
import '../../providers/admin_provider.dart';
import '../../services/sync_service.dart';
import '../../widgets/sync_indicator.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

// Distinct avatar colours for each admin user
const _adminColors = [
  Color(0xFF384845), // Dark Teal
  Color(0xFFC9A84C), // Gold
  Color(0xFF2E7D32), // Green
  Color(0xFFC62828), // Red
  Color(0xFF6A1B9A), // Purple
  Color(0xFF00838F), // Teal
  Color(0xFFE65100), // Deep Orange
  Color(0xFF283593), // Indigo
  Color(0xFF4E342E), // Brown
  Color(0xFF00695C), // Dark Teal
];

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  List<AdminUser> _admins = [];
  String? _selectedAdminId;
  String? _selectedAdminName;
  bool _selectedCanDelete = false;
  bool _selectedCanReject = false;
  Color _selectedAdminColor = _adminColors[0];
  String _pin = '';
  bool _isLoading = true;
  String? _error;

  Color _colorForIndex(int index) => _adminColors[index % _adminColors.length];

  late final _syncSub = SyncService.instance.onReferenceDataSynced.listen((_) {
    _loadAdmins();
  });

  @override
  void initState() {
    super.initState();
    _loadAdmins();
    // Pull fresh data from Supabase while user enters PIN
    SyncService.instance.fullSync();
  }

  @override
  void dispose() {
    _syncSub.cancel();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    final admins = await ref.read(adminProvider.notifier).getAdminUsers();
    if (mounted) {
      setState(() {
        _admins = admins;
        _isLoading = false;
      });
    }
  }

  void _onPinDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == 4) {
      _attemptLogin();
    }
  }

  void _onPinBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _attemptLogin() async {
    if (_selectedAdminId == null) return;
    final success = await ref.read(adminProvider.notifier).login(
      _selectedAdminId!,
      _selectedAdminName!,
      _pin,
      canDeleteOrders: _selectedCanDelete,
      canRejectOrders: _selectedCanReject,
    );
    if (success) {
      if (mounted) context.go('/admin/dashboard');
    } else {
      setState(() {
        _error = 'Incorrect PIN. Please try again.';
        _pin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        toolbarHeight: 68,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 26),
          onPressed: () => context.go('/'),
        ),
        title: Column(
          children: [
            Text('Admin Login',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.white, fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.medium)),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('Select your name and enter PIN',
                  style: TextStyle(fontFamily: 'Inter', color: AppColors.gold, fontSize: AppTextStyles.captionSize)),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [SyncIndicatorCompact()],
        elevation: 2,
        shadowColor: AppColors.navyDark.withValues(alpha: 0.3),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    children: [
                      // Admin selection
                      if (_selectedAdminId == null) _buildAdminSelector(isLandscape),
                      // PIN entry
                      if (_selectedAdminId != null) _buildPinEntry(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAdminSelector(bool isLandscape) {
    return Column(
      children: [
        Icon(Icons.admin_panel_settings_rounded, size: 56, color: AppColors.navy),
        const SizedBox(height: AppSpacing.base),
        Text(
          'Select Your Name',
          style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.headingSize, fontWeight: AppTextStyles.bold, color: AppColors.navy),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.base,
          runSpacing: AppSpacing.base,
          alignment: WrapAlignment.center,
          children: _admins.asMap().entries.map((entry) {
            final index = entry.key;
            final admin = entry.value;
            final color = _colorForIndex(index);
            return _AdminButton(
              name: admin.name,
              color: color,
              onTap: () => setState(() {
                _selectedAdminId = admin.id;
                _selectedAdminName = admin.name;
                _selectedCanDelete = admin.canDeleteOrders;
                _selectedCanReject = admin.canRejectOrders;
                _selectedAdminColor = color;
                _pin = '';
                _error = null;
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPinEntry() {
    return Column(
      children: [
        // Selected admin with change option
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _selectedAdminColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _selectedAdminColor.withValues(alpha: 0.3), width: 2),
              ),
              child: Center(
                child: Text(
                  _selectedAdminName![0].toUpperCase(),
                  style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.headingSize, fontWeight: AppTextStyles.bold, color: _selectedAdminColor),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Text(
              _selectedAdminName!,
              style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.headingSize, fontWeight: AppTextStyles.medium, color: AppColors.navy),
            ),
            const SizedBox(width: AppSpacing.md),
            TextButton(
              onPressed: () => setState(() {
                _selectedAdminId = null;
                _selectedAdminName = null;
                _pin = '';
                _error = null;
              }),
              child: Text('Change', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.gold)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Enter PIN',
          style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.medium, color: AppColors.grey700),
        ),
        const SizedBox(height: AppSpacing.lg),
        // PIN dots — bigger for tablet
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) => Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _pin.length ? AppColors.navy : Colors.transparent,
              border: Border.all(color: AppColors.navy, width: 2.5),
            ),
          )),
        ),
        const SizedBox(height: AppSpacing.base),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(_error!, style: TextStyle(fontFamily: 'Inter', color: AppColors.error, fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium)),
          ),
        const SizedBox(height: AppSpacing.lg),
        // Number pad
        _buildNumberPad(),
      ],
    );
  }

  Widget _buildNumberPad() {
    return SizedBox(
      width: 320,
      child: Column(
        children: [
          for (final row in [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9'], ['', '0', '⌫']])
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  if (key.isEmpty) return const SizedBox(width: 92);
                  if (key == '⌫') {
                    return _PadButton(
                      onTap: _onPinBackspace,
                      child: Icon(Icons.backspace_outlined, size: AppSizes.iconSizeLg, color: AppColors.grey700),
                    );
                  }
                  return _PadButton(
                    child: Text(key, style: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: AppTextStyles.medium, color: AppColors.navy)),
                    onTap: () => _onPinDigit(key),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminButton extends StatelessWidget {
  final String name;
  final Color color;
  final VoidCallback onTap;

  const _AdminButton({required this.name, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: AppRadius.mediumBR,
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumBR,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.base),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mediumBR,
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
                ),
                child: Center(
                  child: Text(
                    name[0].toUpperCase(),
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.bold, color: color),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium, color: AppColors.grey800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _PadButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Material(
        color: AppColors.white,
        borderRadius: AppRadius.mediumBR,
        elevation: 2,
        shadowColor: AppColors.navy.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mediumBR,
          child: Container(
            width: 82,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: AppRadius.mediumBR,
              border: Border.all(color: AppColors.grey200),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
