import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/account.dart';
import '../../providers/providers.dart';
import '../theme/filament_theme.dart';

class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _meterNoCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController(text: '0.00');
  final _monthlyKwhCtrl = TextEditingController(text: '0.0');

  String _selectedDistributor = 'default';
  bool _isSaving = false;

  final List<_DistributorOption> _distributors = const [
    _DistributorOption('desco', 'DESCO (Dhaka Electric)', Icons.electric_bolt),
    _DistributorOption('dpdc', 'DPDC (Dhaka Power)', Icons.electric_bolt_outlined),
    _DistributorOption('default', 'Standard Progressive', Icons.bolt),
  ];

  bool get _isDescoSelected => _selectedDistributor == 'desco';

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _accountNoCtrl.dispose();
    _meterNoCtrl.dispose();
    _balanceCtrl.dispose();
    _monthlyKwhCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final distributor = _selectedDistributor;
    final isDesco = distributor == 'desco';
    final initialBalance =
        double.tryParse(_balanceCtrl.text) ?? 0.0;
    final monthlyKwh =
        double.tryParse(_monthlyKwhCtrl.text) ?? 0.0;

    final newAccount = Account(
      nickname: _nicknameCtrl.text.trim(),
      distributor: distributor,
      accountNo: _accountNoCtrl.text.trim(),
      meterNo: _meterNoCtrl.text.trim(),
      balance: isDesco ? 0.0 : initialBalance,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      currentSlab: 0,
      slabUsage: 0.0,
      yesterdayUsage: 0.0,
      monthlyKwh: isDesco ? 0.0 : monthlyKwh,
    );

    final repo = ref.read(repositoryProvider);
    final newId = await repo.insertAccount(newAccount);
    ref.read(selectedAccountIdProvider.notifier).state = newId;

    if (isDesco) {
      repo.syncAccount(newId);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Account',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 18, fontWeight: FontWeight.w500)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Provider',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...(_distributors.map((opt) => _DistributorTile(
                  option: opt,
                  selected: _selectedDistributor == opt.key,
                  onTap: () =>
                      setState(() => _selectedDistributor = opt.key),
                ))),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'e.g. Home Meter',
                prefixIcon:
                    Icon(Icons.label_outline, size: 18),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v?.trim().isEmpty ?? true)
                  ? 'Nickname is required'
                  : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _accountNoCtrl,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                hintText: 'e.g. 1234567890',
                prefixIcon:
                    Icon(Icons.numbers, size: 18),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                  return 'Must contain digits only';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _meterNoCtrl,
              decoration: const InputDecoration(
                labelText: 'Meter Number',
                hintText: 'e.g. 98765432',
                prefixIcon:
                    Icon(Icons.electric_meter_outlined, size: 18),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
                  return 'Must contain digits only';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            if (!_isDescoSelected) ...[
              TextFormField(
                controller: _balanceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Starting Balance (৳)',
                  prefixText: '৳ ',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined,
                      size: 18),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _monthlyKwhCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monthly kWh so far',
                  suffixText: 'kWh',
                  prefixIcon:
                      Icon(Icons.bolt, size: 18),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],

            if (_isDescoSelected) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FilamentColors.emberOrange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          FilamentColors.emberOrange.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: FilamentColors.emberOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Balance and usage data will be fetched live from DESCO API after saving.',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: FilamentColors.emberOrange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Account'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _DistributorOption {
  final String key;
  final String label;
  final IconData icon;
  const _DistributorOption(this.key, this.label, this.icon);
}

class _DistributorTile extends StatelessWidget {
  final _DistributorOption option;
  final bool selected;
  final VoidCallback onTap;

  const _DistributorTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = selected
        ? FilamentColors.emberOrange
        : (isDark ? FilamentColors.darkBorder : FilamentColors.borderLight);
    final bg = selected
        ? FilamentColors.emberOrange.withValues(alpha: 0.06)
        : (isDark ? FilamentColors.darkCard : Colors.white);
    final textColor = selected
        ? FilamentColors.emberOrange
        : (isDark
            ? FilamentColors.textPrimaryDark
            : FilamentColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: borderColor, width: selected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Icon(option.icon,
                size: 18,
                color: selected
                    ? FilamentColors.emberOrange
                    : FilamentColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(option.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  )),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: FilamentColors.emberOrange, size: 18),
          ],
        ),
      ),
    );
  }
}
