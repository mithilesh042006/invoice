import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../services/sync_service.dart';
import '../shell/app_shell.dart';
import '../dashboard/dashboard_providers.dart';

/// Provider for loading shop profile data.
final shopProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = InvoiceRepository();
  return repo.getShopProfile();
});

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _saving = false;
  bool _loaded = false;

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _populateFields(Map<String, dynamic> profile) {
    if (_loaded) return;
    _shopNameCtrl.text = profile['shop_name']?.toString() ?? '';
    _addressCtrl.text = profile['address']?.toString() ?? '';
    _phoneCtrl.text = profile['phone']?.toString() ?? '';
    _emailCtrl.text = profile['email']?.toString() ?? '';
    _loaded = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final repo = InvoiceRepository();
      await repo.updateShopProfile({
        'shop_name': _shopNameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
      });

      ref.invalidate(shopProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(shopProfileProvider);
    final mobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.settings, color: AppColors.primary, size: mobile ? 24 : 28),
            const SizedBox(width: 10),
            Text('Settings', style: mobile ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineMedium),
          ]),
          const SizedBox(height: 20),
          Expanded(
            child: profileAsync.when(
              data: (profile) {
                if (profile != null) _populateFields(profile);
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shop Info Section
                            _sectionHeader('Shop Information', Icons.store),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _shopNameCtrl,
                              label: 'Shop Name',
                              hint: 'Enter your shop name',
                              icon: Icons.storefront,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _addressCtrl,
                              label: 'Address',
                              hint: 'Shop address',
                              icon: Icons.location_on_outlined,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            if (mobile)
                              Column(children: [
                                _buildField(
                                  controller: _phoneCtrl,
                                  label: 'Phone',
                                  hint: 'Phone number',
                                  icon: Icons.phone_outlined,
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  hint: 'Email address',
                                  icon: Icons.email_outlined,
                                ),
                              ])
                            else
                              Row(children: [
                                Expanded(child: _buildField(
                                  controller: _phoneCtrl,
                                  label: 'Phone',
                                  hint: 'Phone number',
                                  icon: Icons.phone_outlined,
                                )),
                                const SizedBox(width: 16),
                                Expanded(child: _buildField(
                                  controller: _emailCtrl,
                                  label: 'Email',
                                  hint: 'Email address',
                                  icon: Icons.email_outlined,
                                )),
                              ]),


                            const SizedBox(height: 20),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.save),
                                label: Text(_saving ? 'Saving...' : 'Save Settings'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Info box
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Shop name, address, phone, and GSTIN will appear on printed and exported invoices.',
                                    style: TextStyle(color: AppColors.info.withValues(alpha: 0.8), fontSize: 13),
                                  ),
                                ),
                              ]),
                            ),

                            // ── Cloud Sync (mobile only) ──
                            if (mobile) ...[
                              const SizedBox(height: 32),
                              _sectionHeader('Cloud Sync', Icons.cloud_upload_outlined),
                              const SizedBox(height: 16),
                              _SyncCard(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: AppColors.accent, size: 20),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(width: 12),
      Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.5))),
    ]);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}

/// Cloud Sync card — shown on mobile Settings screen.
/// Mirrors the sync functionality from the desktop sidebar.
class _SyncCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final syncMsg = ref.watch(syncMessageProvider);
    final unsyncedAsync = ref.watch(unsyncedCountProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _syncIcon(syncStatus),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    syncStatus == SyncStatus.syncing
                        ? 'Syncing...'
                        : 'Sync to Cloud',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (syncStatus == SyncStatus.done)
                    Text(syncMsg, style: const TextStyle(color: AppColors.success, fontSize: 12))
                  else if (syncStatus == SyncStatus.error)
                    Text(syncMsg, style: const TextStyle(color: AppColors.error, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)
                  else
                    unsyncedAsync.when(
                      data: (count) => Text('$count items waiting to sync', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: syncStatus == SyncStatus.syncing ? null : () => _performSync(ref),
              icon: syncStatus == SyncStatus.syncing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload),
              label: Text(syncStatus == SyncStatus.syncing ? 'Syncing...' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent));
      case SyncStatus.done:
        return const Icon(Icons.cloud_done, size: 24, color: AppColors.success);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, size: 24, color: AppColors.error);
      default:
        return const Icon(Icons.cloud_upload_outlined, size: 24, color: AppColors.textSecondary);
    }
  }

  Future<void> _performSync(WidgetRef ref) async {
    ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;
    ref.read(syncMessageProvider.notifier).state = '';

    final result = await SyncService().syncAll();

    if (result.hasError) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      ref.read(syncMessageProvider.notifier).state = result.error!;
    } else {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.done;
      ref.read(syncMessageProvider.notifier).state = '${result.totalSynced} items synced';
      ref.invalidate(unsyncedCountProvider);
    }

    Future.delayed(const Duration(seconds: 5), () {
      if (ref.read(syncStatusProvider) != SyncStatus.syncing) {
        ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
      }
    });
  }
}
