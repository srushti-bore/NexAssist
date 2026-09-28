import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:it_helpdesk_client/features/auth/auth_controller.dart';
import 'package:it_helpdesk_client/shared/api_client.dart';
import 'package:it_helpdesk_client/shared/constants/app_colors.dart';
import 'package:it_helpdesk_client/shared/constants/app_spacing.dart';
import 'package:it_helpdesk_client/shared/models/case_model.dart';
import 'package:it_helpdesk_client/shared/widgets/download_apps_dialog.dart';
import 'package:it_helpdesk_client/shared/widgets/gsap_motion.dart';
import 'package:it_helpdesk_client/shared/widgets/interactive_card.dart';
import 'package:it_helpdesk_client/shared/widgets/liquid_glass_panel.dart';
import 'package:it_helpdesk_client/shared/widgets/priority_badge.dart';
import 'package:it_helpdesk_client/shared/widgets/responsive_grid.dart';
import 'package:it_helpdesk_client/shared/widgets/status_badge.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<CaseModel> _cases = [];
  int _totalCases = 0;
  int _openCases = 0;
  int _resolvedCases = 0;
  int _atRiskCases = 0;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiClient.get('/cases', queryParams: {'page': 1, 'page_size': 20});
      final items = (res['items'] as List).map((i) => CaseModel.fromJson(i)).toList();

      if (mounted) {
        setState(() {
          _cases = items;
          _totalCases = res['total'] ?? items.length;
          _openCases = items.where((c) => c.status != 'resolved' && c.status != 'closed').length;
          _resolvedCases = items.where((c) => c.status == 'resolved' || c.status == 'closed').length;
          _atRiskCases = items.where((c) => c.slaBreached || c.priority == 'P1').length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<CaseModel> get _filteredCases {
    switch (_selectedTab) {
      case 'attention':
        return _cases.where((c) => c.status == 'awaiting_requester' || c.status == 'in_assessment' || c.slaBreached).toList();
      case 'open':
        return _cases.where((c) => c.status != 'resolved' && c.status != 'closed').toList();
      case 'resolved':
        return _cases.where((c) => c.status == 'resolved' || c.status == 'closed').toList();
      case 'all':
      default:
        return _cases;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isOperatorOrAdmin = user?.role == 'operator' || user?.role == 'team_lead' || user?.role == 'admin' || user?.role == 'manager';
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < AppBreakpoints.mobile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? _buildLoadingSkeleton()
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              color: AppColors.primary,
              backgroundColor: context.surfaceColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ResponsiveContentShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Greeting & Context
                      GSAPFadeSlide(
                        direction: SlideDirection.down,
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOperatorOrAdmin ? 'Operator Queue' : 'IT Service Desk',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    isOperatorOrAdmin
                                        ? 'Active fleet triage and ticket SLA orchestration'
                                        : 'Assistance, equipment, and automated operations',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 13,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.download_rounded, size: 16),
                                          label: const Text('Download Apps'),
                                          onPressed: () => DownloadAppsDialog.show(context),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: context.textPrimary,
                                            side: BorderSide(color: context.borderColor),
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 10),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.add_rounded, size: 16),
                                          label: const Text('New Ticket'),
                                          onPressed: () => context.go('/cases/create'),
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 10),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isOperatorOrAdmin ? 'Operator Queue' : 'IT Service Desk',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          isOperatorOrAdmin
                                              ? 'Active fleet triage and ticket SLA orchestration'
                                              : 'Assistance, equipment, and automated operations',
                                          style: GoogleFonts.publicSans(
                                            fontSize: 13,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.download_rounded, size: 16),
                                        label: const Text('Download Apps'),
                                        onPressed: () => DownloadAppsDialog.show(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: context.textPrimary,
                                          side: BorderSide(color: context.borderColor),
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        label: const Text('New Ticket'),
                                        onPressed: () => context.go('/cases/create'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Action Cards (Quick Creation shortcuts)
                      if (!isOperatorOrAdmin) ...[
                        GSAPFadeSlide(
                          delay: const Duration(milliseconds: 60),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 520;
                              return isWide
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: _buildActionCard(
                                            title: 'Report an issue',
                                            badge: 'Incident',
                                            description: 'Hardware, software, or outage disruptions',
                                            onTap: () => context.go('/cases/create'),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: _buildActionCard(
                                            title: 'Request a service',
                                            badge: 'Request',
                                            description: 'New equipment, software access, or accounts',
                                            onTap: () => context.go('/cases/create'),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildActionCard(
                                          title: 'Report an issue',
                                          badge: 'Incident',
                                          description: 'Hardware, software, or outage disruptions',
                                          onTap: () => context.go('/cases/create'),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        _buildActionCard(
                                          title: 'Request a service',
                                          badge: 'Request',
                                          description: 'New equipment, software access, or accounts',
                                          onTap: () => context.go('/cases/create'),
                                        ),
                                      ],
                                    );
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // 4 Metric Plain Stat Tiles (Space Grotesk, InteractiveCard hover lift)
                      GSAPFadeSlide(
                        delay: const Duration(milliseconds: 100),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final int columns = width >= 800 ? 4 : (width >= 440 ? 2 : 1);
                            return GridView.count(
                              crossAxisCount: columns,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                              childAspectRatio: columns == 4 ? 1.7 : (columns == 2 ? 1.8 : 2.8),
                              children: [
                                _buildMetricTile(
                                  label: isOperatorOrAdmin ? 'Assigned to me' : 'Your Cases',
                                  value: '$_totalCases',
                                  accentColor: AppColors.primary,
                                ),
                                _buildMetricTile(
                                  label: 'Active Backlog',
                                  value: '$_openCases',
                                  accentColor: AppColors.mutedBlue,
                                ),
                                _buildMetricTile(
                                  label: 'At Risk / SLA',
                                  value: '$_atRiskCases',
                                  hasDot: _atRiskCases > 0,
                                  dotColor: AppColors.coral,
                                  accentColor: AppColors.coral,
                                ),
                                _buildMetricTile(
                                  label: 'Resolved Fleet',
                                  value: '$_resolvedCases',
                                  accentColor: AppColors.slateTeal,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // AI Operator Briefing (Liquid Glassmorphism Controlled Panel)
                      GSAPFadeSlide(
                        delay: const Duration(milliseconds: 140),
                        child: LiquidGlassPanel(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                          backgroundColor: context.isDarkMode
                              ? AppColors.glassSurfaceDark
                              : AppColors.glassSurfaceLight,
                          borderColor: context.isDarkMode
                              ? AppColors.glassBorderDarkAccent
                              : AppColors.glassBorderLightAccent,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.primaryTint,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: const Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.primary),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'AI Copilot Briefing',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: context.isDarkMode
                                                ? AppColors.primary.withValues(alpha: 0.2)
                                                : AppColors.primaryTint,
                                            borderRadius: BorderRadius.circular(AppRadius.pill),
                                          ),
                                          child: Text(
                                            'Assistive',
                                            style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _atRiskCases > 0
                                          ? 'Prioritize high-urgency incidents first; $_atRiskCases queue items require confirmation or diagnostic attachments.'
                                          : 'All queues healthy. Automated triage copilot is indexing incoming requests and monitoring SLA thresholds.',
                                      style: GoogleFonts.publicSans(
                                        fontSize: 13,
                                        color: context.textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Queue Segment Tabs
                      GSAPFadeSlide(
                        delay: const Duration(milliseconds: 180),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildTabButton('all', 'All cases (${_cases.length})'),
                              const SizedBox(width: AppSpacing.sm),
                              _buildTabButton('open', 'Open ($_openCases)'),
                              const SizedBox(width: AppSpacing.sm),
                              _buildTabButton('attention', 'Needs attention'),
                              const SizedBox(width: AppSpacing.sm),
                              _buildTabButton('resolved', 'Resolved ($_resolvedCases)'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Case Ledger Container (Spacious, 1px hairlines)
                      GSAPFadeSlide(
                        delay: const Duration(milliseconds: 220),
                        child: _filteredCases.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(AppSpacing.xxxl),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: context.borderColor),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 42, color: context.textTertiary),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'No cases in this queue',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      'New tickets will appear here once submitted.',
                                      style: GoogleFonts.publicSans(color: context.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: context.cardColor,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  border: Border.all(color: context.borderColor),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredCases.length,
                                  separatorBuilder: (_, __) => Divider(color: context.borderColor, height: 1),
                                  itemBuilder: (context, index) {
                                    final c = _filteredCases[index];
                                    return InkWell(
                                      onTap: () => context.go('/cases/${c.id}'),
                                      hoverColor: context.hoverBg,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Top row: Ref Number, Requester/Site, Relative Time
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      c.referenceNumber,
                                                      style: GoogleFonts.spaceGrotesk(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                    const SizedBox(width: AppSpacing.sm),
                                                    Text(
                                                      c.requesterEmail,
                                                      style: GoogleFonts.publicSans(
                                                        fontSize: 12,
                                                        color: context.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  DateFormat('dd MMM').format(c.createdAt),
                                                  style: GoogleFonts.publicSans(
                                                    fontSize: 11,
                                                    color: context.textTertiary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: AppSpacing.xs),

                                            // Title
                                            Text(
                                              c.title,
                                              style: GoogleFonts.publicSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.sm),

                                            // Badges: Priority, Status, SLA
                                            Wrap(
                                              spacing: AppSpacing.sm,
                                              runSpacing: AppSpacing.xs,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                PriorityBadge(priority: c.priority),
                                                StatusBadge(status: c.status),
                                                if (c.slaBreached)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.dangerTint,
                                                      borderRadius: BorderRadius.circular(AppRadius.xs),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 5,
                                                          height: 5,
                                                          decoration: const BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: AppColors.dangerRose,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          'SLA breached',
                                                          style: GoogleFonts.publicSans(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                            color: AppColors.dangerRose,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    'SLA active',
                                                    style: GoogleFonts.publicSans(
                                                      fontSize: 11,
                                                      color: context.textTertiary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return const SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
      child: ResponsiveContentShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GSAPShimmerLoader(width: 220, height: 28),
            SizedBox(height: AppSpacing.sm),
            GSAPShimmerLoader(width: 320, height: 16),
            SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(child: GSAPShimmerLoader(height: 70)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: GSAPShimmerLoader(height: 70)),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: GSAPShimmerLoader(height: 85)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: GSAPShimmerLoader(height: 85)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: GSAPShimmerLoader(height: 85)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: GSAPShimmerLoader(height: 85)),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            GSAPShimmerLoader(height: 320),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String badge,
    required String description,
    required VoidCallback onTap,
  }) {
    return InteractiveCard(
      onTap: onTap,
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.containerBg,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  border: Border.all(color: context.borderColor),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.publicSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    bool hasDot = false,
    Color dotColor = AppColors.coral,
    Color accentColor = AppColors.primary,
  }) {
    return InteractiveCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.textSecondary,
                ),
              ),
              if (hasDot)
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                  ),
                ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabKey, String label) {
    final isActive = _selectedTab == tabKey;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tabKey),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? context.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: isActive ? context.borderColor : Colors.transparent),
        ),
        child: Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? context.textPrimary : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
