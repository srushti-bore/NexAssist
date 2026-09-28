import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:it_helpdesk_client/features/auth/auth_controller.dart';
import 'package:it_helpdesk_client/shared/constants/app_colors.dart';
import 'package:it_helpdesk_client/shared/constants/app_spacing.dart';
import 'package:it_helpdesk_client/shared/theme_controller.dart';
import 'package:it_helpdesk_client/shared/widgets/download_apps_dialog.dart';
import 'package:it_helpdesk_client/shared/widgets/notification_panel.dart';
import 'package:provider/provider.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  bool _isNotificationPanelOpen = false;

  void _onNavigate(BuildContext context, int index) {
    if (_isNotificationPanelOpen) {
      setState(() => _isNotificationPanelOpen = false);
    }
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/cases');
        break;
      case 2:
        context.go('/knowledge');
        break;
      case 3:
        context.go('/reports');
        break;
    }
  }

  void _toggleNotificationPanel() {
    setState(() => _isNotificationPanelOpen = !_isNotificationPanelOpen);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.mobile;
    final isTablet = width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
    final auth = context.watch<AuthController>();
    final theme = context.watch<ThemeController>();
    final user = auth.currentUser;
    final isDark = theme.isDarkMode;

    // Base Scaffold colors from Design.md: #FAFAFA Light / #0F172A Dark
    final scaffoldBg = isDark ? AppColors.bgDark : AppColors.background;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    // --- MOBILE SHELL ---
    if (isMobile) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: surfaceColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: AppSpacing.md,
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.support_agent_rounded, size: 18, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'NexAssist',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          actions: [
            // Download Native Apps Button (.exe & .apk)
            IconButton(
              icon: Icon(
                Icons.download_rounded,
                size: 20,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              tooltip: 'Download Apps (.exe / .apk)',
              onPressed: () => DownloadAppsDialog.show(context),
            ),
            // Theme Mode Toggle Button
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                color: isDark ? AppColors.warning : AppColors.primary,
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => theme.toggleTheme(),
            ),
            // Notification Bell with unread badge
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 21,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              tooltip: 'Notifications',
              onPressed: _toggleNotificationPanel,
            ),
            IconButton(
              icon: Icon(
                Icons.logout_rounded,
                size: 19,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              tooltip: 'Sign out',
              onPressed: () => auth.logout(),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(color: borderColor, height: 1),
          ),
        ),
        body: Stack(
          children: [
            widget.child,
            if (_isNotificationPanelOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _isNotificationPanelOpen = false),
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: NotificationPanel(
                  onClose: () => setState(() => _isNotificationPanelOpen = false),
                  onSelectCase: (id) {
                    setState(() => _isNotificationPanelOpen = false);
                    context.go('/cases');
                  },
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: widget.currentIndex,
              onTap: (index) => _onNavigate(context, index),
              backgroundColor: surfaceColor,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              selectedLabelStyle: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.publicSans(fontSize: 11, fontWeight: FontWeight.w400),
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 20),
                  activeIcon: Icon(Icons.home_rounded, size: 20),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inbox_outlined, size: 20),
                  activeIcon: Icon(Icons.inbox_rounded, size: 20),
                  label: 'Cases',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book_outlined, size: 20),
                  activeIcon: Icon(Icons.menu_book_rounded, size: 20),
                  label: 'Knowledge',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.insights_outlined, size: 20),
                  activeIcon: Icon(Icons.insights_rounded, size: 20),
                  label: 'Insights',
                ),
              ],
            ),
          ),
        ),
      );
    }

    // --- TABLET SHELL (Adaptive Navigation Rail) ---
    if (isTablet) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 76,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    border: Border(right: BorderSide(color: borderColor, width: 1)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _RailItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: widget.currentIndex == 0,
                        onTap: () => _onNavigate(context, 0),
                      ),
                      _RailItem(
                        icon: Icons.inbox_outlined,
                        activeIcon: Icons.inbox_rounded,
                        label: 'Cases',
                        isSelected: widget.currentIndex == 1,
                        onTap: () => _onNavigate(context, 1),
                      ),
                      _RailItem(
                        icon: Icons.menu_book_outlined,
                        activeIcon: Icons.menu_book_rounded,
                        label: 'Knowledge',
                        isSelected: widget.currentIndex == 2,
                        onTap: () => _onNavigate(context, 2),
                      ),
                      _RailItem(
                        icon: Icons.insights_outlined,
                        activeIcon: Icons.insights_rounded,
                        label: 'Insights',
                        isSelected: widget.currentIndex == 3,
                        onTap: () => _onNavigate(context, 3),
                      ),
                      const Spacer(),
                      // Download Apps Button (.exe & .apk)
                      IconButton(
                        icon: Icon(
                          Icons.download_rounded,
                          size: 20,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                        tooltip: 'Download Apps (.exe / .apk)',
                        onPressed: () => DownloadAppsDialog.show(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Theme toggle
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          size: 20,
                          color: isDark ? AppColors.warning : AppColors.primary,
                        ),
                        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        onPressed: () => theme.toggleTheme(),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 21,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        tooltip: 'Notifications',
                        onPressed: _toggleNotificationPanel,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      IconButton(
                        icon: Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                        tooltip: 'Sign out',
                        onPressed: () => auth.logout(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
            if (_isNotificationPanelOpen) ...[
              GestureDetector(
                onTap: () => setState(() => _isNotificationPanelOpen = false),
                child: Container(color: Colors.black.withValues(alpha: 0.3)),
              ),
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: NotificationPanel(
                  onClose: () => setState(() => _isNotificationPanelOpen = false),
                  onSelectCase: (id) {
                    setState(() => _isNotificationPanelOpen = false);
                    context.go('/cases');
                  },
                ),
              ),
            ],
          ],
        ),
      );
    }

    // --- DESKTOP & WEB SHELL (Clean Spacious Sidebar + Top Header Bar) ---
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          Row(
            children: [
              // Clean Solid Sidebar
              Container(
                width: 250,
                decoration: BoxDecoration(
                  color: surfaceColor,
                  border: Border(right: BorderSide(color: borderColor, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Header
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NexAssist',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'AI IT Operations',
                                style: GoogleFonts.publicSans(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(color: borderColor, height: 1),

                    // Navigation Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
                        children: [
                          _SidebarItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            title: 'Home / Queue',
                            isSelected: widget.currentIndex == 0,
                            onTap: () => _onNavigate(context, 0),
                          ),
                          _SidebarItem(
                            icon: Icons.inbox_outlined,
                            activeIcon: Icons.inbox_rounded,
                            title: 'Case Ledger',
                            isSelected: widget.currentIndex == 1,
                            onTap: () => _onNavigate(context, 1),
                          ),
                          _SidebarItem(
                            icon: Icons.menu_book_outlined,
                            activeIcon: Icons.menu_book_rounded,
                            title: 'Knowledge Base',
                            isSelected: widget.currentIndex == 2,
                            onTap: () => _onNavigate(context, 2),
                          ),
                          _SidebarItem(
                            icon: Icons.insights_outlined,
                            activeIcon: Icons.insights_rounded,
                            title: 'Operational Insights',
                            isSelected: widget.currentIndex == 3,
                            onTap: () => _onNavigate(context, 3),
                          ),
                        ],
                      ),
                    ),

                    // User Profile & Sign Out Footer
                    Divider(color: borderColor, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (user?.fullName ?? user?.email ?? 'U')[0].toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? user?.email ?? 'User',
                                    style: GoogleFonts.publicSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user?.role ?? '',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 10,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.logout_rounded,
                                size: 17,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                              tooltip: 'Sign out',
                              onPressed: () => auth.logout(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area with Top Header Bar
              Expanded(
                child: Column(
                  children: [
                    // Top Global Bar
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getHeaderTitle(widget.currentIndex),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          // SLA Monitor / Risk Status Indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.slateTealTint,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: AppColors.slateTeal.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.slateTeal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'SLA Sweep Active',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slateTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Download Native Apps Button (.exe & .apk)
                          InkWell(
                            onTap: () => DownloadAppsDialog.show(context),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardDark : AppColors.surfaceSecondary,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.download_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Download Apps',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Theme Toggle Button (Light / Dark mode switcher)
                          InkWell(
                            onTap: () => theme.toggleTheme(),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                    size: 16,
                                    color: isDark ? AppColors.warning : AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isDark ? 'Light' : 'Dark',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // Notification Trigger
                          InkWell(
                            onTap: _toggleNotificationPanel,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.notifications_none_rounded,
                                    size: 19,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                                  ),
                                  Positioned(
                                    top: -1,
                                    right: -1,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Main Screen Body
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),

          // Slide-In Notification Panel Overlay
          if (_isNotificationPanelOpen) ...[
            GestureDetector(
              onTap: () => setState(() => _isNotificationPanelOpen = false),
              child: Container(color: Colors.black.withValues(alpha: 0.3)),
            ),
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: NotificationPanel(
                onClose: () => setState(() => _isNotificationPanelOpen = false),
                onSelectCase: (id) {
                  setState(() => _isNotificationPanelOpen = false);
                  context.go('/cases');
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getHeaderTitle(int index) {
    switch (index) {
      case 0:
        return 'Triage & Case Queue';
      case 1:
        return 'Enterprise Case Ledger';
      case 2:
        return 'Knowledge Base & SOPs';
      case 3:
        return 'Operational Analytics';
      default:
        return 'NexAssist';
    }
  }
}

class _RailItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryTint : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryTint : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.25)) : null,
      ),
      child: ListTile(
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? AppColors.primary : context.textSecondary,
          size: 19,
        ),
        title: Text(
          title,
          style: GoogleFonts.publicSans(
            color: isSelected ? AppColors.primary : context.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        onTap: onTap,
      ),
    );
  }
}
