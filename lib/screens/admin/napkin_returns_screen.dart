import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';

class NapkinReturnsScreen extends ConsumerStatefulWidget {
  const NapkinReturnsScreen({super.key});

  @override
  ConsumerState<NapkinReturnsScreen> createState() => _NapkinReturnsScreenState();
}

class _NapkinReturnsScreenState extends ConsumerState<NapkinReturnsScreen> {
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  int _balance = 0;
  int _totalOut = 0;
  int _totalIn = 0;
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  String _selectedFilter = 'This Month';

  static const _filters = ['Today', 'Last 7 Days', 'This Month', 'Last 30 Days'];

  DateTime _filterSince() {
    final now = DateTime.now();
    return switch (_selectedFilter) {
      'Today' => DateTime(now.year, now.month, now.day),
      'Last 7 Days' => now.subtract(const Duration(days: 7)),
      'This Month' => DateTime(now.year, now.month, 1),
      'Last 30 Days' => now.subtract(const Duration(days: 30)),
      _ => DateTime(now.year, now.month, 1),
    };
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = DatabaseService.instance;
    final totals = await db.getLedgerTotals();
    final entries = await db.getLedgerEntries(since: _filterSince());
    if (mounted) {
      setState(() {
        _totalOut = totals['total_out'] ?? 0;
        _totalIn = totals['total_in'] ?? 0;
        _balance = _totalOut - _totalIn;
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  Future<void> _logReturn() async {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    final admin = ref.read(adminProvider).currentAdmin;
    final db = DatabaseService.instance;
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();
    final entryId = uuid.v4();
    final note = _noteController.text.trim().isEmpty
        ? 'Bulk return from Laundrevo'
        : _noteController.text.trim();

    await db.insertLedgerEntry({
      'id': entryId,
      'item_name': 'Linen Napkins',
      'direction': 'in',
      'quantity': qty,
      'order_id': null,
      'department_id': null,
      'note': note,
      'recorded_by': admin?.name,
      'created_at': now,
    });

    // Queue for Supabase sync
    await db.addToSyncQueue('linen_ledger', entryId, 'insert', jsonEncode({
      'id': entryId,
      'item_name': 'Linen Napkins',
      'direction': 'in',
      'quantity': qty,
      'note': note,
      'recorded_by': admin?.name,
      'created_at': now,
    }));
    SyncService.instance.pushPendingNow();

    _qtyController.clear();
    _noteController.clear();
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$qty napkins received — logged to pool')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.navyLight],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Napkin Returns',
                              style: TextStyle(fontFamily: 'Inter', color: AppColors.white, fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.bold)),
                          Text('Pool-based linen tracking',
                              style: TextStyle(fontFamily: 'Inter', color: AppColors.gold, fontSize: AppTextStyles.captionSize)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBalanceCards(),
                            const SizedBox(height: AppSpacing.xl),
                            _buildReturnForm(),
                            const SizedBox(height: AppSpacing.xl),
                            _buildLedgerHistory(),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCards() {
    return Row(
      children: [
        Expanded(child: _statCard('Sent Out', _totalOut, AppColors.statusCollected, Icons.arrow_upward_rounded)),
        const SizedBox(width: AppSpacing.base),
        Expanded(child: _statCard('Received In', _totalIn, AppColors.success, Icons.arrow_downward_rounded)),
        const SizedBox(width: AppSpacing.base),
        Expanded(child: _statCard(
          'Balance',
          _balance,
          _balance > 0 ? AppColors.statusCollected : AppColors.success,
          _balance > 0 ? Icons.pending_outlined : Icons.check_circle_outline,
        )),
      ],
    );
  }

  Widget _statCard(String label, int value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text('$value',
                style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.headingSize, fontWeight: AppTextStyles.bold, color: color)),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, color: AppColors.grey600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.add_circle_outline, color: AppColors.success, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text('Log Napkin Return', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.bold, color: AppColors.navy)),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Quantity
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      hintText: '0',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.base),
                      border: OutlineInputBorder(borderRadius: AppRadius.mediumBR),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Note
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'e.g. Extra batch, delivery ref, driver name...',
                      helperText: 'Add context for this return — delivery reference, driver, etc.',
                      helperMaxLines: 2,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.base),
                      border: OutlineInputBorder(borderRadius: AppRadius.mediumBR),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Submit
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _logReturn,
                    icon: const Icon(Icons.check, color: AppColors.white),
                    label: Text('Log Return', style: TextStyle(fontFamily: 'Inter', fontWeight: AppTextStyles.bold, color: AppColors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBR),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: _filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) {
              setState(() => _selectedFilter = filter);
              _loadData();
            },
            selectedColor: AppColors.navy,
            backgroundColor: AppColors.grey100,
            labelStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: AppTextStyles.captionSize,
              fontWeight: isSelected ? AppTextStyles.bold : AppTextStyles.medium,
              color: isSelected ? AppColors.white : AppColors.grey700,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.largeBR),
            side: BorderSide.none,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLedgerHistory() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppColors.navy, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text('Ledger History', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.bold, color: AppColors.navy)),
                const Spacer(),
                Text('${_entries.length} entries', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, color: AppColors.grey500)),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            _buildFilterChips(),
            const Divider(height: AppSpacing.xl),
            if (_entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Text('No entries for $_selectedFilter', style: TextStyle(fontFamily: 'Inter', color: AppColors.grey500)),
                ),
              ),
            // Table header
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  SizedBox(width: 70, child: Text('Type', style: _headerStyle())),
                  SizedBox(width: 80, child: Text('Qty', style: _headerStyle(), textAlign: TextAlign.center)),
                  Expanded(child: Text('Note', style: _headerStyle())),
                  SizedBox(width: 90, child: Text('By', style: _headerStyle())),
                  SizedBox(width: 130, child: Text('Date', style: _headerStyle(), textAlign: TextAlign.end)),
                ],
              ),
            ),
            ...List.generate(_entries.length, (i) {
              final entry = _entries[i];
              final isOut = entry['direction'] == 'out';
              final date = DateTime.tryParse(entry['created_at'] as String? ?? '');
              final dateStr = date != null ? DateFormat('dd MMM, HH:mm').format(date) : '—';

              return Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.grey200, width: 0.5)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOut
                              ? AppColors.statusCollected.withValues(alpha: 0.12)
                              : AppColors.success.withValues(alpha: 0.12),
                          borderRadius: AppRadius.smallBR,
                        ),
                        child: Text(
                          isOut ? 'OUT' : 'IN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppTextStyles.captionSize,
                            fontWeight: AppTextStyles.bold,
                            color: isOut ? AppColors.statusCollected : AppColors.success,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${entry['quantity']}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.bold, color: AppColors.navy),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry['note'] as String? ?? '—',
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        entry['recorded_by'] as String? ?? '—',
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey600),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: Text(
                        dateStr,
                        textAlign: TextAlign.end,
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey500),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  TextStyle _headerStyle() => TextStyle(
        fontFamily: 'Inter',
        fontSize: AppTextStyles.captionSize,
        fontWeight: AppTextStyles.bold,
        color: AppColors.grey500,
        letterSpacing: 0.5,
      );
}
