import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_scaffold.dart';
import '../../providers/order_provider.dart';
import '../../providers/department_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../models/department.dart';
import '../../services/sync_service.dart';

/// Capitalizes the first letter of each word as the user types.
class _CapitalizeWordsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final text = newValue.text;
    final buffer = StringBuffer();
    bool capitalizeNext = true;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        buffer.write(' ');
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(text[i].toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(text[i]);
      }
    }
    return newValue.copyWith(text: buffer.toString(), selection: newValue.selection);
  }
}

class OrderDetailsScreen extends ConsumerStatefulWidget {
  const OrderDetailsScreen({super.key});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _docketController = TextEditingController();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _emailController = TextEditingController();
  final _roomController = TextEditingController();

  String? _selectedDepartmentId;
  String? _selectedLinenType; // 'hsk_linen' or 'fnb_linen'
  String? _selectedGuestType; // 'Hotel' or 'Loft'
  int _bagCount = 1;
  bool _notesExpanded = false;


  @override
  void dispose() {
    _docketController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    _emailController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  bool get _isGuestOrder => ref.read(orderProvider).orderType == 'guest_laundry';
  bool get _isLinenOrder {
    final type = ref.read(orderProvider).orderType;
    return type == 'linen' || type == 'hsk_linen' || type == 'fnb_linen';
  }


  String get _stepSubtitle {
    if (_isGuestOrder) return 'Step 2 of 3 — Guest Details';
    return 'Step 2 of 4 — Enter Details';
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;

    if (!_isGuestOrder && _selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    if (_isLinenOrder && _selectedLinenType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    final notifier = ref.read(orderProvider.notifier);
    final departments = ref.read(departmentsProvider).valueOrNull ?? Department.seedData;
    final dept = departments.where((d) => d.id == _selectedDepartmentId).firstOrNull;

    if (_isLinenOrder) {
      // Find the department name from our linen departments list
      final linenDept = _linenDepartments.where((d) => d['id'] == _selectedDepartmentId).firstOrNull;
      final deptName = linenDept?['name'] as String? ?? 'Housekeeping';
      notifier.updateDetails(
        docketNumber: _docketController.text.trim(),
        departmentId: _selectedDepartmentId,
        departmentName: deptName,
        staffName: _nameController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      // Set the specific linen type (hsk_linen or fnb_linen) without resetting draft
      notifier.updateOrderType(_selectedLinenType!);
    } else if (_isGuestOrder) {
      if (_selectedGuestType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Hotel or Loft')),
        );
        return;
      }
      final room = _roomController.text.trim();
      notifier.updateDetails(
        docketNumber: room,
        departmentId: _selectedGuestType == 'Hotel'
            ? 'c333cf77-1e29-40c4-9a0e-e1e5df09306f'   // GST
            : '0241132b-ab91-497e-a19a-5571238b5406',   // LFT
        departmentName: _selectedGuestType,
        guestName: _nameController.text.trim(),
        staffName: _nameController.text.trim(),
        roomNumber: room,
        bagCount: _bagCount,
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    } else {
      notifier.updateDetails(
        docketNumber: _docketController.text.trim(),
        departmentId: _selectedDepartmentId,
        departmentName: dept?.name,
        staffName: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    }

    if (_isGuestOrder) {
      context.push('/order/review');
    } else {
      context.push('/order/items');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final showSideDepts = !_isGuestOrder;

    return ScreenScaffold(
      title: 'Order Details',
      subtitle: _stepSubtitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh departments & items',
          onPressed: () {
            SyncService.instance.fullSync();
            ref.invalidate(departmentsProvider);
            ref.invalidate(staffDepartmentsProvider);
            ref.invalidate(linenDepartmentsProvider);
            ref.invalidate(catalogueItemsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Refreshing...'), duration: Duration(seconds: 1)),
            );
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? AppSpacing.xl : AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: form fields
                Expanded(
                  flex: showSideDepts ? 3 : 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 550),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isGuestOrder) ..._buildGuestFields(),
                          if (!_isGuestOrder) ..._buildStaffFields(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildNextButton(),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
                // Right side: department selector
                if (showSideDepts) ...[
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    flex: 2,
                    child: _isLinenOrder
                        ? _buildSideLinenDepartmentList()
                        : _buildSideDepartmentList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildStaffFields() {
    return [
      _buildSectionLabel('Docket Number'),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _docketController,
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        decoration: const InputDecoration(
          hintText: 'Enter 4-digit docket number',
          prefixIcon: Icon(Icons.tag),
          counterText: '',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Docket number is required';
          if (v.trim().length != 4) return 'Docket number must be exactly 4 digits';
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.lg),

      _buildSectionLabel('Staff Name'),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), _CapitalizeWordsFormatter()],
        decoration: const InputDecoration(
          hintText: 'Enter your full name',
          prefixIcon: Icon(Icons.person),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Name is required';
          if (v.trim().length < 2) return 'Please enter your full name';
          return null;
        },
      ),

      // Email — uniform orders only (for status update notifications)
      if (!_isLinenOrder) ...[
        const SizedBox(height: AppSpacing.lg),
        _buildSectionLabel('Email (for order updates)'),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            hintText: 'Enter your email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w{2,}$');
            if (!emailRegex.hasMatch(v.trim())) return 'Please enter a valid email';
            return null;
          },
        ),
      ],
      const SizedBox(height: AppSpacing.lg),

      // Notes — all staff order types
      _buildCollapsibleNotes(),
    ];
  }

  List<Widget> _buildGuestFields() {
    return [
      _buildSectionLabel('Type'),
      const SizedBox(height: AppSpacing.sm),
      _buildGuestTypeChips(),
      const SizedBox(height: AppSpacing.lg),

      _buildSectionLabel('Room Number'),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _roomController,
        keyboardType: TextInputType.number,
        maxLength: 5,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
        decoration: const InputDecoration(
          hintText: 'e.g. 204 or 12045',
          prefixIcon: Icon(Icons.door_front_door_outlined),
          counterText: '',
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Room number is required';
          if (v.trim().length < 3 || v.trim().length > 5) return 'Room number must be 3–5 digits';
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.lg),

      _buildSectionLabel('Guest Name & Bags'),
      const SizedBox(height: AppSpacing.sm),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Guest Name — left side
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), _CapitalizeWordsFormatter()],
              decoration: const InputDecoration(
                hintText: 'Enter guest name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Guest name is required';
                if (v.trim().length < 2) return 'Please enter the full name';
                return null;
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Number of Bags — right side, same height as text field
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey300),
              borderRadius: AppRadius.mediumBR,
              color: AppColors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _bagCount > 1 ? () => setState(() => _bagCount--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.navy,
                  iconSize: 28,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    '$_bagCount',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: AppTextStyles.bold, color: AppColors.navy),
                  ),
                ),
                Text(
                  _bagCount == 1 ? 'bag' : 'bags',
                  style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey600),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () => setState(() => _bagCount++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.navy,
                  iconSize: 28,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),

      _buildSectionLabel('Email (for order updates)'),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(
          hintText: 'Enter guest email address',
          prefixIcon: Icon(Icons.email_outlined),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w{2,}$');
          if (!emailRegex.hasMatch(v.trim())) return 'Please enter a valid email';
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.lg),

      _buildCollapsibleNotes(),
    ];
  }

  Widget _buildGuestTypeChips() {
    return Row(
      children: ['Hotel', 'Loft'].map((type) {
        final selected = _selectedGuestType == type;
        final icon = type == 'Hotel' ? Icons.hotel : Icons.apartment;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: type == 'Hotel' ? AppSpacing.sm : 0,
              left: type == 'Loft' ? AppSpacing.sm : 0,
            ),
            child: Material(
              color: selected ? AppColors.navy.withValues(alpha: 0.08) : AppColors.white,
              borderRadius: AppRadius.mediumBR,
              elevation: selected ? 2 : 1,
              shadowColor: AppColors.navy.withValues(alpha: 0.1),
              child: InkWell(
                onTap: () => setState(() => _selectedGuestType = type),
                borderRadius: AppRadius.mediumBR,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mediumBR,
                    border: Border.all(
                      color: selected ? AppColors.navy : AppColors.grey300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(icon, color: selected ? AppColors.navy : AppColors.grey600, size: 32),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        type,
                        style: TextStyle(fontFamily: 'Inter',
                          fontWeight: AppTextStyles.medium,
                          color: selected ? AppColors.navy : AppColors.grey700,
                          fontSize: AppTextStyles.bodySize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  static IconData _iconForDepartment(String code) {
    return switch (code.toUpperCase()) {
      'HSK' => Icons.bed_rounded,
      'FNB' => Icons.restaurant_rounded,
      'FOH' => Icons.desk_rounded,
      'KIT' => Icons.soup_kitchen_rounded,
      'MNT' => Icons.build_rounded,
      'SPA' => Icons.spa_rounded,
      'MGT' => Icons.business_center_rounded,
      'SEC' => Icons.security_rounded,
      'GST' => Icons.hotel_rounded,
      'LFT' => Icons.apartment_rounded,
      'KEF' => Icons.restaurant_rounded,
      'LNG' => Icons.weekend_rounded,
      'EVT' => Icons.celebration_rounded,
      'SMK' => Icons.campaign_rounded,
      'HRS' => Icons.people_rounded,
      'ACC' => Icons.account_balance_rounded,
      'RSV' => Icons.book_online_rounded,
      'GMT' => Icons.admin_panel_settings_rounded,
      _ => Icons.business_rounded,
    };
  }

  Widget _buildSideDepartmentList() {
    final departments = ref.watch(departmentsProvider).valueOrNull ?? Department.seedData;
    final filtered = departments.where((d) => d.canSubmitUniforms).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Department',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.navy,
            fontSize: AppTextStyles.bodySize,
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...filtered.map((dept) {
          final selected = _selectedDepartmentId == dept.id;
          final icon = _iconForDepartment(dept.code);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: selected ? AppColors.gold : AppColors.white,
              borderRadius: AppRadius.smallBR,
              elevation: selected ? 2 : 0,
              shadowColor: AppColors.gold.withValues(alpha: 0.3),
              child: InkWell(
                onTap: () => setState(() => _selectedDepartmentId = dept.id),
                borderRadius: AppRadius.smallBR,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.smallBR,
                    border: Border.all(
                      color: selected ? AppColors.gold : AppColors.grey300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: AppSizes.iconSizeMd,
                          color: selected ? AppColors.navy : AppColors.grey500),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          dept.name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppTextStyles.labelSize,
                            fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
                            color: selected ? AppColors.navy : AppColors.grey700,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Hardcoded linen departments: Housekeeping = hsk_linen, rest = fnb_linen
  static const _linenDepartments = [
    {'id': '25606c38-03ab-486c-9d97-151e039c68a9', 'name': 'Housekeeping', 'type': 'hsk_linen', 'icon': Icons.bed_rounded},
    {'id': '2482ccaa-c8d3-49c4-84c1-6dd45d4745e7', 'name': 'Lounge', 'type': 'fnb_linen', 'icon': Icons.weekend_rounded},
    {'id': '6ad328b2-6f21-42a2-9071-dc258fa63ca4', 'name': 'Events', 'type': 'fnb_linen', 'icon': Icons.celebration_rounded},
    {'id': '5056ce99-6d0c-443c-a459-59185cf81530', 'name': 'Kitchen E20 Front', 'type': 'fnb_linen', 'icon': Icons.restaurant_rounded},
  ];

  Widget _buildSideLinenDepartmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Department',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.navy,
            fontSize: AppTextStyles.bodySize,
            fontWeight: AppTextStyles.medium,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._linenDepartments.map((dept) {
          final id = dept['id'] as String;
          final name = dept['name'] as String;
          final icon = dept['icon'] as IconData;
          final selected = _selectedDepartmentId == id;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Material(
              color: selected ? AppColors.gold : AppColors.white,
              borderRadius: AppRadius.smallBR,
              elevation: selected ? 2 : 0,
              shadowColor: AppColors.gold.withValues(alpha: 0.3),
              child: InkWell(
                onTap: () => setState(() {
                  _selectedDepartmentId = id;
                  _selectedLinenType = dept['type'] as String;
                }),
                borderRadius: AppRadius.smallBR,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.smallBR,
                    border: Border.all(
                      color: selected ? AppColors.gold : AppColors.grey300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: AppSizes.iconSizeMd,
                          color: selected ? AppColors.navy : AppColors.grey500),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppTextStyles.labelSize,
                            fontWeight: selected ? AppTextStyles.bold : AppTextStyles.regular,
                            color: selected ? AppColors.navy : AppColors.grey700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNextButton() {
    final label = _isGuestOrder ? 'Review Order' : 'Next — Select Items';

    return SizedBox(
      height: AppSizes.buttonHeightLg,
      child: ElevatedButton.icon(
        onPressed: _onNext,
        icon: const Icon(Icons.arrow_forward_rounded, size: AppSizes.iconSizeLg),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          textStyle: TextStyle(fontFamily: 'Inter',
            fontSize: AppTextStyles.bodySize,
            fontWeight: AppTextStyles.bold,
          ),
          elevation: 3,
          shadowColor: AppColors.gold.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBR),
        ),
      ),
    );
  }


  Widget _buildCollapsibleNotes() {
    return Material(
      color: AppColors.white,
      borderRadius: AppRadius.mediumBR,
      child: InkWell(
        onTap: _notesExpanded ? null : () => setState(() => _notesExpanded = true),
        borderRadius: AppRadius.mediumBR,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _notesExpanded ? AppColors.navy : AppColors.grey300),
            borderRadius: AppRadius.mediumBR,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _notesExpanded = !_notesExpanded),
                borderRadius: _notesExpanded
                    ? BorderRadius.vertical(top: Radius.circular(AppRadius.md))
                    : AppRadius.mediumBR,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.notes, color: AppColors.grey600, size: AppSizes.iconSizeMd),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _notesExpanded ? 'Notes' : 'Add notes (optional)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppTextStyles.bodySize,
                            color: _notesExpanded ? AppColors.navy : AppColors.grey500,
                            fontWeight: _notesExpanded ? AppTextStyles.medium : AppTextStyles.regular,
                          ),
                        ),
                      ),
                      Icon(
                        _notesExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppColors.grey500,
                        size: AppSizes.iconSizeMd,
                      ),
                    ],
                  ),
                ),
              ),
              if (_notesExpanded) ...[
                Divider(height: 1, color: AppColors.grey200),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  child: TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'e.g. special instructions',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontFamily: 'Inter',
        color: AppColors.navy,
        fontSize: AppTextStyles.bodySize,
        fontWeight: AppTextStyles.medium,
      ),
    );
  }
}

