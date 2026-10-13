import 'package:flutter/material.dart';
import '../models/sales_model.dart';
import '../services/auth_service.dart';
import '../services/sale_order_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_curve_chart.dart';
import '../widgets/daily_snapshot_modal.dart';
import '../widgets/outlet_selector_dialog.dart';

class SalesView extends StatefulWidget {
  final OutletInfo selectedOutlet;
  final List<OutletInfo> outlets;
  final ValueChanged<OutletInfo> onOutletChanged;

  const SalesView({
    super.key,
    required this.selectedOutlet,
    required this.outlets,
    required this.onOutletChanged,
  });

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView>
    with SingleTickerProviderStateMixin {
  late String selectedDate;
  String posSyncedText = '6 Mins ago';
  String ordersSyncedText = '6 Mins ago';
  bool isRefreshing = false;
  late AnimationController _syncAnimController;
  String _selectedChartType = 'Column';

  IconData _getChartTypeIcon(String type) {
    switch (type) {
      case 'Line':
        return Icons.show_chart_rounded;
      case 'Area':
        return Icons.area_chart_rounded;
      case 'Column':
      default:
        return Icons.bar_chart_rounded;
    }
  }

  PopupMenuItem<String> _buildChartMenuItem(
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedChartType == value;
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? const Color(0xFF0F56D9) : const Color(0xFF475467),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F56D9) : const Color(0xFF344054),
              ),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: Color(0xFF0F56D9),
            ),
        ],
      ),
    );
  }

  static String _formatCurrency(double amount) {
    final intVal = amount.round();
    final str = intVal.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '₹ $formatted';
  }

  static String _formatDateShort(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  static String _formatDateLong(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final daySuffix = _getDaySuffix(dt.day);
    return '${dt.day}$daySuffix ${months[dt.month - 1]}, ${dt.year}';
  }

  static String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  static String _formatMonthFull(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  void initState() {
    super.initState();
    selectedDate = _formatDateShort(DateTime.now());
    _syncAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    SaleOrderService().setActiveOutlet(widget.selectedOutlet);
    SaleOrderService().fetchOrders();
  }

  @override
  void didUpdateWidget(covariant SalesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedOutlet != oldWidget.selectedOutlet) {
      SaleOrderService().setActiveOutlet(widget.selectedOutlet);
    }
  }

  @override
  void dispose() {
    _syncAnimController.dispose();
    super.dispose();
  }

  void _triggerRefresh() async {
    if (isRefreshing) return;
    setState(() => isRefreshing = true);
    _syncAnimController.repeat();

    SaleOrderService().markSyncedNow();
    await SaleOrderService().fetchOrders(forceRefresh: true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      _syncAnimController.stop();
      _syncAnimController.reset();
      setState(() {
        isRefreshing = false;
        posSyncedText = 'Just now';
        ordersSyncedText = 'Just now';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synced live sales data for ${widget.selectedOutlet.name}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.textPrimary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDatePicker() {
    final saleService = SaleOrderService();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final todayStr = _formatDateShort(now);
    final yesterdayStr = _formatDateShort(yesterday);
    final monthStr = '${_formatMonthFull(now.month)} ${now.year}';

    final options = [
      {
        'preset': DateFilterPreset.today,
        'title': 'Today ($todayStr)',
      },
      {
        'preset': DateFilterPreset.yesterday,
        'title': 'Yesterday ($yesterdayStr)',
      },
      {
        'preset': DateFilterPreset.last7Days,
        'title': 'Last 7 Days',
      },
      {
        'preset': DateFilterPreset.thisMonth,
        'title': 'This Month ($monthStr)',
      },
      {
        'preset': DateFilterPreset.custom,
        'title': 'Custom Date Range',
      },
      {
        'preset': DateFilterPreset.all,
        'title': 'All Time',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Date Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final preset = opt['preset'] as DateFilterPreset;
                  final title = opt['title'] as String;
                  final isSelected = saleService.dateFilterPreset == preset;

                  String? subtitle;
                  if (preset == DateFilterPreset.custom &&
                      saleService.dateFilterPreset == DateFilterPreset.custom &&
                      saleService.filterStartDate != null &&
                      saleService.filterEndDate != null) {
                    subtitle =
                        '${_formatDateShort(saleService.filterStartDate!)} - ${_formatDateShort(saleService.filterEndDate!)}';
                  }

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: subtitle != null
                        ? Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primaryBlue)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      if (preset == DateFilterPreset.custom) {
                        final currentStart = saleService.filterStartDate ?? now;
                        final currentEnd = saleService.filterEndDate ?? now;
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          initialDateRange: DateTimeRange(
                            start: currentStart,
                            end: currentEnd,
                          ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primaryBlue,
                                  onPrimary: Colors.white,
                                  onSurface: AppColors.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          saleService.setDateFilterPreset(
                            DateFilterPreset.custom,
                            customRange: picked,
                          );
                          if (mounted) {
                            setState(() {
                              selectedDate = saleService.dateFilterLabel;
                            });
                          }
                        }
                      } else {
                        saleService.setDateFilterPreset(preset);
                        if (mounted) {
                          setState(() {
                            selectedDate = saleService.dateFilterLabel;
                          });
                        }
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Scrollable Content
            Expanded(
              child: ListenableBuilder(
                listenable: SaleOrderService(),
                builder: (context, _) {
                  final saleService = SaleOrderService();
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Daily Snapshot Card
                        _buildDailySnapshotCard(context),

                        const SizedBox(height: 22),

                        // 2. Sales Overview Section Header
                        _buildSalesOverviewHeader(saleService),

                        const SizedBox(height: 14),

                        // 3. Total Sales Card
                        _buildTotalSalesCard(saleService),

                        const SizedBox(height: 14),

                        // 4. Dine In Card
                        _buildDineInCard(context, saleService),

                        const SizedBox(height: 14),

                        // 5. Pick Up Card
                        _buildPickUpCard(context, saleService),

                        const SizedBox(height: 14),

                        // 6. Delivery Card
                        _buildDeliveryCard(context, saleService),

                        const SizedBox(height: 14),

                        // 7. Online Orders Card
                        _buildOnlineOrdersCard(saleService),

                        const SizedBox(height: 14),

                        // 8. Payment Details Card
                        _buildPaymentDetailsCard(saleService),

                        const SizedBox(height: 14),

                        // 9. Total Orders Card
                        _buildTotalOrdersCard(saleService),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top App Bar matching screenshot 3
  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          // Left exit / switch button matching "->|" in screenshot 3
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                _showSignOutOrSwitchDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 1),
                    Container(
                      width: 2.2,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Center outlet selector box
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  OutletSelectorModal.show(
                    context,
                    outlets: widget.outlets,
                    selectedOutlet: widget.selectedOutlet,
                    onSelected: widget.onOutletChanged,
                  );
                },
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1.0,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.selectedOutlet.shortName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Right Button: Refresh / Sync Data
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _triggerRefresh,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  size: 19,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutOrSwitchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlueLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Terminal Session',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description
              Text(
                'Currently active at ${widget.selectedOutlet.name}. Do you want to switch store branch or log out of terminal?',
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),

              // Action 1: Switch Branch (Primary Action)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    OutletSelectorModal.show(
                      context,
                      outlets: widget.outlets,
                      selectedOutlet: widget.selectedOutlet,
                      onSelected: widget.onOutletChanged,
                    );
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text(
                    'Switch Branch',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Action 2: Stay in Session (Secondary Action)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Stay in Session',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Action 3: Sign Out (Destructive Option)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    AuthService().logout();
                  },
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  label: const Text(
                    'Sign Out of Terminal',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Daily Snapshot Card matching screenshot 3
  Widget _buildDailySnapshotCard(BuildContext context) {
    final todayLong = _formatDateLong(DateTime.now());
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Curved Line Graph Area
          const DailySnapshotCurveWidget(height: 52),

          // Bottom Details & Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Snapshot',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todayLong,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    DailySnapshotModal.show(
                      context,
                      dateText: todayLong,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.actionButtonBorder,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Ready To View',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Sales Overview Section Header matching screenshot
  Widget _buildSalesOverviewHeader(SaleOrderService saleService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Text(
            'Sales Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            // Date pill button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _showDatePicker,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        saleService.dateFilterLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Refresh button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _triggerRefresh,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1.0,
                    ),
                  ),
                  child: RotationTransition(
                    turns: _syncAnimController,
                    child: const Icon(
                      Icons.sync_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Total Sales Card matching screenshot
  Widget _buildTotalSalesCard(SaleOrderService saleService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + TOTAL SALES label
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.purpleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  color: AppColors.purpleIcon,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TOTAL SALES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Total Sales Revenue
          Text(
            _formatCurrency(
                saleService.getTotalSalesForOutlet(widget.selectedOutlet)),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // POS synced 2 Mins ago & Orders synced 1 Hour ago
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
              children: [
                const TextSpan(text: 'POS synced '),
                TextSpan(
                  text: posSyncedText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const TextSpan(text: ' & Orders synced '),
                TextSpan(
                  text: ordersSyncedText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Dine In Card matching screenshot
  Widget _buildDineInCard(BuildContext context, SaleOrderService saleService) {
    final dineSales =
        saleService.getDineInSalesForOutlet(widget.selectedOutlet);
    final dineCount =
        saleService.getDineInCountForOutlet(widget.selectedOutlet);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + DINE IN
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.cyanBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.cyanIcon,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'DINE IN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Dine In Revenue
          Text(
            _formatCurrency(dineSales),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Bottom stats: dynamic Orders, Turn Around Time
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '$dineCount ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'Orders'),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '0 Min ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'Turn Around Time'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Pick Up Card matching screenshot
  Widget _buildPickUpCard(BuildContext context, SaleOrderService saleService) {
    final pickSales =
        saleService.getPickUpSalesForOutlet(widget.selectedOutlet);
    final pickCount =
        saleService.getPickUpCountForOutlet(widget.selectedOutlet);
    final aov =
        saleService.getPickUpAverageOrderValueForOutlet(widget.selectedOutlet);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + PICK UP
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.greenIcon,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'PICK UP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Pick Up Revenue
          Text(
            _formatCurrency(pickSales),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Bottom stats: dynamic Orders, Average Order Value
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '$pickCount ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'Orders'),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '${_formatCurrency(aov)} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'Average Order Value'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Delivery Card matching screenshot 1
  Widget _buildDeliveryCard(
      BuildContext context, SaleOrderService saleService) {
    final delivSales =
        saleService.getDeliverySalesForOutlet(widget.selectedOutlet);
    final delivCount =
        saleService.getDeliveryCountForOutlet(widget.selectedOutlet);
    final aov =
        saleService.getDeliveryAverageOrderValueForOutlet(widget.selectedOutlet);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + DELIVERY
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.two_wheeler_rounded,
                  color: Color(0xFFFB6514),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'DELIVERY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dynamic Delivery Revenue
          Text(
            _formatCurrency(delivSales),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Bottom stats: dynamic Order, Average Order Value
          Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '$delivCount ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(text: delivCount == 1 ? 'Order' : 'Orders'),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '${_formatCurrency(aov)} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'Average Order Value'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 7. Online Orders Card matching screenshot 1
  Widget _buildOnlineOrdersCard(SaleOrderService saleService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Online orders',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '₹ 0',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '0 orders',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Inner Bordered Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF0F2F5),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Prepaid and COD
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E60F2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Prepaid',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '₹ 0',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '0 orders',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'COD',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '₹ 0',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '0 orders',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sub-card: Other
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE8ECEF),
                      width: 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2F4F7),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.more_horiz_rounded,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Other',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  '₹ 0',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: const [
                                Text(
                                  '0 brands ',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E60F2),
                                  ),
                                ),
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 14,
                                  color: Color(0xFF1E60F2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Bottom Row: PREPAID / COD / ORDERS
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFE8ECEF),
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: const [
                                Expanded(
                                  child: Text(
                                    'PREPAID',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'COD',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'ORDERS',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Expanded(
                                  child: Text(
                                    '₹ 0',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '₹ 0',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '0',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 8. Payment Details Card matching screenshot 2
  Widget _buildPaymentDetailsCard(SaleOrderService saleService) {
    final notPaidAmount =
        saleService.getNotPaidSalesForOutlet(widget.selectedOutlet);
    final cashAmount =
        saleService.getCashSalesForOutlet(widget.selectedOutlet);
    final cardAmount =
        saleService.getCardSalesForOutlet(widget.selectedOutlet);
    final onlinePaidAmount =
        saleService.getOnlinePaidSalesForOutlet(widget.selectedOutlet);
    final onlineCodAmount =
        saleService.getOnlineCodSalesForOutlet(widget.selectedOutlet);
    final otherAmount =
        saleService.getOtherSalesForOutlet(widget.selectedOutlet);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + PAYMENT DETAILS
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.purpleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.purpleIcon,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'PAYMENT DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment rows
          _buildPaymentRow(
            dotColor: const Color(0xFF12B76A),
            label: 'Not Paid',
            amount: _formatCurrency(notPaidAmount),
          ),
          const SizedBox(height: 14),
          _buildPaymentRow(
            dotColor: const Color(0xFF1E60F2),
            label: 'Cash',
            amount: _formatCurrency(cashAmount),
          ),
          const SizedBox(height: 14),
          _buildPaymentRow(
            dotColor: const Color(0xFFF79009),
            label: 'Card',
            amount: _formatCurrency(cardAmount),
          ),
          const SizedBox(height: 14),
          _buildPaymentRow(
            dotColor: const Color(0xFF00BAF2),
            label: 'Online Paid',
            amount: _formatCurrency(onlinePaidAmount),
          ),
          const SizedBox(height: 14),
          _buildPaymentRow(
            dotColor: const Color(0xFF38BDF8),
            label: 'Online COD',
            amount: _formatCurrency(onlineCodAmount),
          ),
          const SizedBox(height: 14),
          _buildPaymentRow(
            dotColor: const Color(0xFFF59E0B),
            label: 'Other',
            amount: _formatCurrency(otherAmount),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow({
    required Color dotColor,
    required String label,
    required String amount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF344054),
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // 9. Total Orders Card matching screenshot 2
  Widget _buildTotalOrdersCard(SaleOrderService saleService) {
    final totalCount =
        saleService.getTotalOrdersCountForOutlet(widget.selectedOutlet);
    final successfulCount =
        saleService.getSuccessfulCountForOutlet(widget.selectedOutlet);
    final complimentaryCount =
        saleService.getComplimentaryCountForOutlet(widget.selectedOutlet);
    final cancelledCount =
        saleService.getCancelledCountForOutlet(widget.selectedOutlet);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cardBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + TOTAL ORDERS
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.purpleBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: AppColors.purpleIcon,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TOTAL ORDERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big Count + Column Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$totalCount',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              PopupMenuButton<String>(
                initialValue: _selectedChartType,
                tooltip: 'Select Chart Type',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 4,
                color: Colors.white,
                onSelected: (val) {
                  setState(() => _selectedChartType = val);
                },
                itemBuilder: (context) => [
                  _buildChartMenuItem('Column', 'Column', Icons.bar_chart_rounded),
                  _buildChartMenuItem('Line', 'Line', Icons.show_chart_rounded),
                  _buildChartMenuItem('Area', 'Area', Icons.area_chart_rounded),
                ],
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD0D5DD),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getChartTypeIcon(_selectedChartType),
                        size: 16,
                        color: const Color(0xFF475467),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedChartType,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF344054),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF475467),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sub-stats: 6 Successful   0 Complimentary   0 Cancelled
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '$successfulCount ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'Successful'),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '$complimentaryCount ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'Complimentary'),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: '$cancelledCount ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: 'Cancelled'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Orders Column Bar Chart matching screenshot 2
          _buildOrdersBarChart(saleService),
        ],
      ),
    );
  }

  // Column chart matching screenshot 2
  Widget _buildOrdersBarChart(SaleOrderService saleService) {
    final orders = saleService.getOrdersForOutlet(widget.selectedOutlet);

    // 6 time buckets: 4 am, 8 am, 12 pm, 4 pm, 8 pm, 12 am
    final bucketSales = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    for (final o in orders) {
      final dt = o.parsedDateTime ?? o.parsedDate;
      int bucket = 3; // default evening 4pm
      if (dt != null && (dt.hour != 0 || dt.minute != 0)) {
        final h = dt.hour;
        if (h >= 4 && h < 8) {
          bucket = 0;
        } else if (h >= 8 && h < 12) {
          bucket = 1;
        } else if (h >= 12 && h < 16) {
          bucket = 2;
        } else if (h >= 16 && h < 20) {
          bucket = 3;
        } else if (h >= 20) {
          bucket = 4;
        } else {
          bucket = 5;
        }
      } else {
        // When invoice date doesn't contain time of day:
        if (o.isDineIn) {
          bucket = 2; // Lunch rush (12 pm)
        } else if (o.isDelivery) {
          bucket = 4; // Dinner delivery (8 pm)
        } else {
          bucket = 3; // Afternoon & evening counter takeaway (4 pm)
        }
      }
      bucketSales[bucket] += o.amountTotal;
    }

    final maxVal = bucketSales.fold(0.0, (m, v) => v > m ? v : m);
    final double yCeiling;
    if (maxVal <= 0) {
      yCeiling = 3000;
    } else if (maxVal <= 1000) {
      yCeiling = 1000;
    } else if (maxVal <= 2000) {
      yCeiling = 2000;
    } else {
      yCeiling = ((maxVal / 1000).ceil() * 1000).toDouble();
    }

    final yLabels = [
      '${(yCeiling / 1000).round()}k',
      '${((yCeiling * 2 / 3) / 1000).round()}k',
      '${((yCeiling / 3) / 1000).round()}k',
      '0k',
    ];

    const slotLabels = ['4 am', '8 am', '12 pm', '4 pm', '8 pm', '12 am'];

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-Axis labels
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...yLabels.map((lbl) => Text(
                    lbl,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF98A2B3),
                    ),
                  )),
              const SizedBox(height: 16),
            ],
          ),
          const SizedBox(width: 8),

          // Chart body (Grid lines + Bars + X-Axis)
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // Horizontal grid lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (_) => Container(
                            height: 1,
                            color: const Color(0xFFF2F4F7),
                          ),
                        ),
                      ),
                      // Chart visualization (Column / Line / Area)
                      if (_selectedChartType == 'Column')
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(6, (idx) {
                            final amt = bucketSales[idx];
                            final barHeight = maxVal > 0
                                ? ((amt / yCeiling) * 115).clamp(0.0, 115.0)
                                : 0.0;
                            return Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Tooltip(
                                  message: amt > 0
                                      ? '${slotLabels[idx]}: ₹ ${amt.round()}'
                                      : '${slotLabels[idx]}: ₹ 0',
                                  child: Container(
                                    width: 26,
                                    height: barHeight,
                                    decoration: BoxDecoration(
                                      color: amt > 0
                                          ? const Color(0xFF1E60F2)
                                          : Colors.transparent,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        )
                      else
                        _buildLineOrAreaChart(
                          bucketSales,
                          maxVal,
                          yCeiling,
                          slotLabels,
                          isArea: _selectedChartType == 'Area',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // X-Axis labels
                Row(
                  children: List.generate(
                    6,
                    (idx) => Expanded(
                      child: Text(
                        slotLabels[idx],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineOrAreaChart(
    List<double> bucketSales,
    double maxVal,
    double yCeiling,
    List<String> slotLabels, {
    required bool isArea,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: [
            CustomPaint(
              size: Size(w, h),
              painter: _LineAreaChartPainter(
                data: bucketSales,
                yCeiling: yCeiling,
                isArea: isArea,
              ),
            ),
            Row(
              children: List.generate(6, (idx) {
                final amt = bucketSales[idx];
                return Expanded(
                  child: Tooltip(
                    message: amt > 0
                        ? '${slotLabels[idx]}: ₹ ${amt.round()}'
                        : '${slotLabels[idx]}: ₹ 0',
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _LineAreaChartPainter extends CustomPainter {
  final List<double> data;
  final double yCeiling;
  final bool isArea;

  const _LineAreaChartPainter({
    required this.data,
    required this.yCeiling,
    required this.isArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || yCeiling <= 0) return;

    final n = data.length;
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = (size.width / n) * (i + 0.5);
      final ratio = (data[i] / yCeiling).clamp(0.0, 1.0);
      final y = size.height - (ratio * (size.height - 12)) - 6;
      points.add(Offset(x, y));
    }

    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    if (isArea) {
      final fillPath = Path.from(path);
      fillPath.lineTo(points.last.dx, size.height);
      fillPath.lineTo(points.first.dx, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x551E60F2),
            Color(0x051E60F2),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    final strokePaint = Paint()
      ..color = const Color(0xFF1E60F2)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    final dotFillPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFF1E60F2)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.0, dotFillPaint);
      canvas.drawCircle(pt, 4.0, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineAreaChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.yCeiling != yCeiling ||
        oldDelegate.isArea != isArea;
  }
}
