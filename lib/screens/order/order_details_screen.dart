import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_scaffold.dart';
import '../../providers/order_provider.dart';
import '../../models/department.dart';

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
  final _roomController = TextEditingController();

  String? _selectedDepartmentId;
  String? _selectedLinenType; // 'hsk_linen' or 'fnb_linen'
  String? _selectedFnbSubDept; // 'Lounge', 'Events', 'Kitchen'
  String? _selectedGuestType; // 'Hotel' or 'Loft'
  int _bagCount = 1;

  static const _fnbSubDepartments = ['Lounge', 'Events', 'Kitchen'];

  @override
  void dispose() {
    _docketController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  bool get _isGuestOrder => ref.read(orderProvider).orderType == 'guest_laundry';
  bool get _isLinenOrder => ref.read(orderProvider).orderType == 'linen';

  String get _stepSubtitle {
    if (_isGuestOrder) return 'Step 2 of 3 — Guest Details';
    return 'Step 2 of 4 — Enter Details';
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;

    if (_isLinenOrder && _selectedLinenType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a linen type')),
      );
      return;
    }

    if (_isLinenOrder && _selectedLinenType == 'fnb_linen' && _selectedFnbSubDept == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an F&B sub-department')),
      );
      return;
    }

    final notifier = ref.read(orderProvider.notifier);
    final dept = Department.seedData.where((d) => d.id == _selectedDepartmentId).firstOrNull;

    if (_isLinenOrder) {
      notifier.setOrderType(_selectedLinenType!);
      final deptName = _selectedLinenType == 'fnb_linen'
          ? 'F&B — $_selectedFnbSubDept'
          : 'Housekeeping';
      notifier.updateDetails(
        docketNumber: _docketController.text.trim(),
        departmentId: _selectedDepartmentId,
        departmentName: deptName,
        staffName: _nameController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
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
        departmentId: _selectedGuestType == 'Hotel' ? 'gst' : 'lft',
        departmentName: _selectedGuestType,
        guestName: _nameController.text.trim(),
        staffName: _nameController.text.trim(),
        roomNumber: room,
        bagCount: _bagCount,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    } else {
      notifier.updateDetails(
        docketNumber: _docketController.text.trim(),
        departmentId: _selectedDepartmentId,
        departmentName: dept?.name,
        staffName: _nameController.text.trim(),
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

    return ScreenScaffold(
      title: 'Order Details',
      subtitle: _stepSubtitle,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? 80 : AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
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

      if (_isLinenOrder) ...[
        _buildSectionLabel('Linen Type'),
        const SizedBox(height: AppSpacing.sm),
        _buildLinenTypeSelector(),
        if (_selectedLinenType == 'fnb_linen') ...[
          const SizedBox(height: AppSpacing.md),
          _buildSectionLabel('F&B Sub-Department'),
          const SizedBox(height: AppSpacing.sm),
          _buildFnbSubDeptChips(),
        ],
        const SizedBox(height: AppSpacing.lg),
      ],

      if (!_isLinenOrder) ...[
        _buildSectionLabel('Department'),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: _selectedDepartmentId,
          decoration: const InputDecoration(
            hintText: 'Select department',
            prefixIcon: Icon(Icons.business),
          ),
          items: _getDepartmentItems(),
          onChanged: (v) => setState(() => _selectedDepartmentId = v),
          validator: (v) => v == null ? 'Please select a department' : null,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],

      _buildSectionLabel('Staff Name'),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
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
      const SizedBox(height: AppSpacing.lg),

      _buildSectionLabel('Notes'),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Optional notes (e.g. special instructions)',
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 48),
            child: Icon(Icons.notes),
          ),
        ),
      ),
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

      _buildSectionLabel('Guest Name'),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
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
      const SizedBox(height: AppSpacing.lg),

      _buildSectionLabel('Number of Bags'),
      const SizedBox(height: AppSpacing.sm),
      _buildBagCounter(),
      const SizedBox(height: AppSpacing.lg),

      _buildSectionLabel('Notes'),
      const SizedBox(height: AppSpacing.sm),
      TextFormField(
        controller: _notesController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'e.g. needs repair, delicate items',
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: 48),
            child: Icon(Icons.notes),
          ),
        ),
      ),
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

  Widget _buildFnbSubDeptChips() {
    return Wrap(
      spacing: AppSpacing.md,
      children: _fnbSubDepartments.map((name) {
        final selected = _selectedFnbSubDept == name;
        return ChoiceChip(
          label: Text(name),
          selected: selected,
          onSelected: (_) => setState(() => _selectedFnbSubDept = name),
          selectedColor: AppColors.gold,
          backgroundColor: AppColors.white,
          side: BorderSide(color: selected ? AppColors.gold : AppColors.grey300),
          labelStyle: TextStyle(fontFamily: 'Inter',
            fontSize: AppTextStyles.bodySize,
            fontWeight: AppTextStyles.medium,
            color: selected ? AppColors.navy : AppColors.grey700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        );
      }).toList(),
    );
  }

  Widget _buildLinenTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _LinenTypeOption(
            label: 'Housekeeping',
            subtitle: 'Sheets, towels, duvets',
            icon: Icons.bed_rounded,
            selected: _selectedLinenType == 'hsk_linen',
            onTap: () => setState(() {
              _selectedLinenType = 'hsk_linen';
              _selectedDepartmentId = 'hsk';
            }),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _LinenTypeOption(
            label: 'F&B',
            subtitle: 'Tablecloths, napkins, runners',
            icon: Icons.restaurant_rounded,
            selected: _selectedLinenType == 'fnb_linen',
            onTap: () => setState(() {
              _selectedLinenType = 'fnb_linen';
              _selectedDepartmentId = 'fnb';
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBagCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey300),
        borderRadius: AppRadius.mediumBR,
        color: AppColors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _bagCount > 1 ? () => setState(() => _bagCount--) : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.navy,
            iconSize: 32,
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTouchTarget,
              minHeight: AppSizes.minTouchTarget,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            '$_bagCount',
            style: TextStyle(fontFamily: 'Inter',
              fontSize: 32,
              fontWeight: AppTextStyles.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _bagCount == 1 ? 'bag' : 'bags',
            style: TextStyle(fontFamily: 'Inter',
              fontSize: AppTextStyles.titleSize,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          IconButton(
            onPressed: () => setState(() => _bagCount++),
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.navy,
            iconSize: 32,
            constraints: const BoxConstraints(
              minWidth: AppSizes.minTouchTarget,
              minHeight: AppSizes.minTouchTarget,
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _getDepartmentItems() {
    if (_isLinenOrder) {
      return Department.seedData
          .where((d) => d.hasLinenItems)
          .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
          .toList();
    }
    return Department.staffDepartments
        .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
        .toList();
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

class _LinenTypeOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _LinenTypeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy.withValues(alpha: 0.08) : AppColors.white,
      borderRadius: AppRadius.mediumBR,
      elevation: selected ? 2 : 1,
      shadowColor: AppColors.navy.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumBR,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.base,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mediumBR,
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.grey300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.navy : AppColors.grey600, size: 34),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(fontFamily: 'Inter',
                  fontWeight: AppTextStyles.medium,
                  color: selected ? AppColors.navy : AppColors.grey700,
                  fontSize: AppTextStyles.bodySize,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontFamily: 'Inter',
                  color: AppColors.grey600,
                  fontSize: AppTextStyles.labelSize,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
