import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../services/sync_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/dashboard_providers.dart';
import '../products/product_list_screen.dart';
import '../invoices/invoice_list_screen.dart';
import '../invoices/create_invoice_screen.dart';
import '../settings/settings_screen.dart';

/// The selected sidebar tab index.
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// Sync state: idle / syncing / done / error.
enum SyncStatus { idle, syncing, done, error }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);
final syncMessageProvider = StateProvider<String>((ref) => '');

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final mobile = Responsive.isMobile(context);

    final screens = [
      const DashboardScreen(),
      const ProductListScreen(),
      CreateInvoiceScreen(
        onInvoiceCreated: () {
          ref.read(selectedTabProvider.notifier).state = 3;
        },
      ),
      const InvoiceListScreen(),
      const SettingsScreen(),
    ];

    if (mobile) {
      return _MobileShell(
        selectedTab: selectedTab,
        screens: screens,
        onTabSelected: (i) => ref.read(selectedTabProvider.notifier).state = i,
      );
    }

    return _DesktopShell(
      selectedTab: selectedTab,
      screens: screens,
      onTabSelected: (i) => ref.read(selectedTabProvider.notifier).state = i,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
//  MOBILE SHELL — Bottom Navigation Bar
// ════════════════════════════════════════════════════════════════════════
class _MobileShell extends StatelessWidget {
  final int selectedTab;
  final List<Widget> screens;
  final ValueChanged<int> onTabSelected;

  const _MobileShell({
    required this.selectedTab,
    required this.screens,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: selectedTab, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: onTabSelected,
          backgroundColor: AppColors.sidebarBg,
          indicatorColor: AppColors.primary.withValues(alpha: 0.2),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.inventory_2, color: AppColors.primary),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.add_circle, color: AppColors.accent),
              label: 'New',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
              label: 'Invoices',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.settings, color: AppColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
//  DESKTOP SHELL — Sidebar
// ════════════════════════════════════════════════════════════════════════
class _DesktopShell extends StatelessWidget {
  final int selectedTab;
  final List<Widget> screens;
  final ValueChanged<int> onTabSelected;

  const _DesktopShell({
    required this.selectedTab,
    required this.screens,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: selectedTab,
            onSelected: onTabSelected,
          ),
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),
          Expanded(
            child: IndexedStack(index: selectedTab, children: screens),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
//  SIDEBAR (desktop only)
// ════════════════════════════════════════════════════════════════════════
class _Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _Sidebar({required this.selectedIndex, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final syncMsg = ref.watch(syncMessageProvider);
    final unsyncedAsync = ref.watch(unsyncedCountProvider);

    return Container(
      width: 220,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          // ── App Title ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Smart Shop', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),

          // ── Nav Items ──
          _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', index: 0, selected: selectedIndex == 0, onTap: () => onSelected(0)),
          _NavItem(icon: Icons.inventory_2_outlined, label: 'Products', index: 1, selected: selectedIndex == 1, onTap: () => onSelected(1)),
          _NavItem(icon: Icons.add_shopping_cart, label: 'New Invoice', index: 2, selected: selectedIndex == 2, onTap: () => onSelected(2)),
          _NavItem(icon: Icons.receipt_long_outlined, label: 'Invoices', index: 3, selected: selectedIndex == 3, onTap: () => onSelected(3)),
          _NavItem(icon: Icons.settings_outlined, label: 'Settings', index: 4, selected: selectedIndex == 4, onTap: () => onSelected(4)),

          const Spacer(),

          // ── Sync Button ──
          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: syncStatus == SyncStatus.syncing ? null : () => _performSync(ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    _syncIcon(syncStatus),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          syncStatus == SyncStatus.syncing ? 'Syncing...' : 'Cloud Sync',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        if (syncStatus == SyncStatus.done)
                          Text(syncMsg, style: const TextStyle(color: AppColors.success, fontSize: 10))
                        else if (syncStatus == SyncStatus.error)
                          Text(syncMsg, style: const TextStyle(color: AppColors.error, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)
                        else
                          unsyncedAsync.when(
                            data: (count) => Text('$count unsynced', style: const TextStyle(color: AppColors.textHint, fontSize: 10)),
                            loading: () => const SizedBox.shrink(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                      ],
                    )),
                  ]),
                ),
              ),
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('v1.1.0', style: TextStyle(color: AppColors.textHint.withValues(alpha: 0.5), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _syncIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent));
      case SyncStatus.done:
        return const Icon(Icons.cloud_done, size: 20, color: AppColors.success);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off, size: 20, color: AppColors.error);
      default:
        return const Icon(Icons.cloud_upload_outlined, size: 20, color: AppColors.textSecondary);
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.index, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? AppColors.sidebarSelected.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppColors.sidebarSelected.withValues(alpha: 0.08),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(label, style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              )),
              if (selected) ...[
                const Spacer(),
                Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
