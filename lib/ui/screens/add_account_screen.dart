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

  bool _isSaving = false;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _accountNoCtrl.dispose();
    _meterNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final newAccount = Account(
      nickname: _nicknameCtrl.text.trim(),
      distributor: 'desco',
      accountNo: _accountNoCtrl.text.trim(),
      meterNo: _meterNoCtrl.text.trim(),
      balance: 0.0,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      currentSlab: 0,
      slabUsage: 0.0,
      yesterdayUsage: 0.0,
      monthlyKwh: 0.0,
    );

    final repo = ref.read(repositoryProvider);
    final newId = await repo.insertAccount(newAccount);
    ref.read(selectedAccountIdProvider.notifier).state = newId;

    repo.syncAccount(newId);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add DESCO Account',
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
            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'e.g. My apartment, shop',
                prefixIcon: Icon(Icons.label_outline, size: 18),
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
                hintText: '8-digit account ID',
                prefixIcon: Icon(Icons.numbers, size: 18),
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
                hintText: '8-digit meter serial',
                prefixIcon: Icon(Icons.electric_meter_outlined, size: 18),
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
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FilamentColors.emberOrange.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: FilamentColors.emberOrange.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: FilamentColors.emberOrange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Balance and consumption data will be fetched live from DESCO API after saving.',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: FilamentColors.emberOrange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
