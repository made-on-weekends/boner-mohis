import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/providers.dart';
import '../../data/calculations_helper.dart';
import '../theme/filament_theme.dart';
import '../widgets/account_card.dart';
import 'detail_screen.dart';
import 'add_account_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(repositoryProvider).syncAllAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? FilamentColors.textPrimaryDark : FilamentColors.textPrimary;


    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CustomPaint(
                painter: SparkLineLogoPainter(
                  strokeColor: textPrimary,
                  emberColor: FilamentColors.emberText(isDark),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('Boner Mohis',
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary)),
          ],
        ),
        actions: [
          accountsAsync.when(
            data: (accounts) => accounts.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: FilamentColors.emberOrange,
                    tooltip: 'Add account',
                    onPressed: () => _openAddAccount(context),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: FilamentColors.emberOrange,
          ),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err',
              style: GoogleFonts.dmSans(color: FilamentColors.danger)),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return _EmptyState(onAddTap: () => _openAddAccount(context));
          }

          final sorted = [...accounts]..sort((a, b) {
              final dA = CalculationsHelper.calculateDaysRemaining(
                  a.balance, a.yesterdayUsage);
              final dB = CalculationsHelper.calculateDaysRemaining(
                  b.balance, b.yesterdayUsage);
              if (dA == dB) return 0;
              if (dA == double.infinity) return 1;
              if (dB == double.infinity) return -1;
              return dA.compareTo(dB);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final account = sorted[index];
              return AccountCard(
                account: account,
                onTap: () {
                  ref
                      .read(selectedAccountIdProvider.notifier)
                      .state = account.id!;
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const DetailScreen(),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openAddAccount(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AddAccountScreen(),
      fullscreenDialog: true,
    ));
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTap;
  const _EmptyState({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted =
        isDark ? FilamentColors.textMutedDark : FilamentColors.textMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: FilamentColors.emberOrange.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.electric_meter_outlined,
                color: FilamentColors.emberOrange,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text('No accounts added yet',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                )),
            const SizedBox(height: 8),
            Text(
              'Add your first prepaid electricity meter account to start tracking your balance and forecasting usage.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, color: textMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add first account'),
            ),
          ],
        ),
      ),
    );
  }
}

class SparkLineLogoPainter extends CustomPainter {
  final Color strokeColor;
  final Color emberColor;

  const SparkLineLogoPainter({
    required this.strokeColor,
    required this.emberColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 100.0;
    final scaleY = size.height / 100.0;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final linePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final discPaint = Paint()
      ..color = emberColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(14.0 * scaleX, 56.0 * scaleY)
      ..lineTo(38.0 * scaleX, 46.0 * scaleY)
      ..lineTo(62.0 * scaleX, 52.0 * scaleY)
      ..lineTo(86.0 * scaleX, 32.0 * scaleY);

    canvas.drawPath(path, linePaint);
    canvas.drawCircle(
      Offset(86.0 * scaleX, 32.0 * scaleY),
      7.0 * scale,
      discPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SparkLineLogoPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.emberColor != emberColor;
  }
}
