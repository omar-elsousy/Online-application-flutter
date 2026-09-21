import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../models/point_models.dart';
import '../widgets/app_error_banner.dart';

class PointsScreen extends StatefulWidget {
  const PointsScreen({super.key});

  @override
  State<PointsScreen> createState() => _PointsScreenState();
}

class _PointsScreenState extends State<PointsScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    final state = AppScope.of(context);
    try {
      await Future.wait([
        state.loadPointsSummary(),
        state.loadPointsGifts(),
        state.loadPointsHistory(),
      ]);
    } catch (e) {
      debugPrint('Error refreshing points screen: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final summary = state.pointsSummary;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نقاطي والمكافآت (My Points)'),
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refresh,
            ),
          ],
        ),
        body: Column(
          children: [
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: AppErrorBanner(message: state.error!),
              ),

            // كارت الرصيد وسياسة التصفير في الأعلى
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.85),
                      Colors.amber.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'رصيد النقاط الحالي',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${state.userPoints} نقطة',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stars_rounded,
                            color: Colors.amberAccent,
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // تنبيه موعد التصفير
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              summary != null && summary.nextResetDate.isNotEmpty
                                  ? 'تنتهي النقاط كل ${summary.resetMonths} أشهر (التصفير القادم: ${summary.nextResetDate})'
                                  : 'تصفير دوري للنقاط كل 6 أشهر',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // تبويبات التنقل
            TabBar(
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.card_giftcard),
                  text: 'الهدايا المتاحة',
                ),
                Tab(
                  icon: Icon(Icons.receipt_long_outlined),
                  text: 'سجل النقاط',
                ),
                Tab(
                  icon: Icon(Icons.info_outline),
                  text: 'شروط الكسب',
                ),
              ],
            ),

            // محتوى التبويبات
            Expanded(
              child: TabBarView(
                children: [
                  _GiftsTab(
                    gifts: state.pointsGifts,
                    userPoints: state.userPoints,
                    isLoading: _isRefreshing || state.isLoading,
                    onRefresh: _refresh,
                    onRedeem: (gift) => _showRedeemDialog(context, gift),
                  ),
                  _HistoryTab(
                    history: state.pointsHistory,
                    isLoading: _isRefreshing || state.isLoading,
                    onRefresh: _refresh,
                  ),
                  _RulesTab(
                    summary: summary,
                    onRefresh: _refresh,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, PointsGift gift) {
    final state = AppScope.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('تأكيد الاستبدال'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل ترغب في استبدال ${gift.pointsRequired} نقطة للحصول على:'),
            const SizedBox(height: 8),
            Text(
              gift.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              'سيتم خصم النقاط فورياً وإرسال الطلب للإدارة لتجهيز هديتك.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 40),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final msg = await state.redeemGift(gift.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(msg ?? 'تم إرسال طلب استبدال الهدية بنجاح! 🎉'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('تأكيد الاستبدال'),
          ),
        ],
      ),
    );
  }
}

// 1. تبويب الهدايا والمكافآت
class _GiftsTab extends StatelessWidget {
  const _GiftsTab({
    required this.gifts,
    required this.userPoints,
    required this.isLoading,
    required this.onRefresh,
    required this.onRedeem,
  });

  final List<PointsGift> gifts;
  final int userPoints;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(PointsGift gift) onRedeem;

  @override
  Widget build(BuildContext context) {
    if (gifts.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 50),
            Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد هدايا متاحة حالياً.',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(140, 42),
                          ),
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('تحديث الهدايا'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          final canRedeem = userPoints >= gift.pointsRequired;
          final progress = gift.pointsRequired > 0
              ? (userPoints / gift.pointsRequired).clamp(0.0, 1.0)
              : 0.0;
          final remaining = (gift.pointsRequired - userPoints).clamp(0, gift.pointsRequired);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: gift.imageUrl != null && gift.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  gift.imageUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Error loading gift image (${gift.imageUrl}): $error');
                                    return const Icon(Icons.card_giftcard, size: 36, color: Colors.amber);
                                  },
                                ),
                              )
                            : const Icon(Icons.card_giftcard, size: 36, color: Colors.amber),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gift.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (gift.description != null && gift.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                gift.description!,
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Text(
                                '${gift.pointsRequired} نقطة',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        canRedeem ? Colors.green : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          canRedeem
                              ? '✅ نقاطك كافية للاستبدال!'
                              : 'متبقي $remaining نقطة للاستبدال',
                          style: TextStyle(
                            color: canRedeem ? Colors.green : Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: canRedeem && !isLoading ? () => onRedeem(gift) : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(110, 36),
                          backgroundColor: canRedeem ? Colors.green : Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('استبدال الآن'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 2. تبويب سجل النقاط
class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.history,
    required this.isLoading,
    required this.onRefresh,
  });

  final List<PointsHistoryItem> history;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 50),
            Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد حركات نقاط سابقة حتى الآن.',
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(140, 42),
                          ),
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh),
                          label: const Text('تحديث السجل'),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = history[index];
          final isPositive = item.points > 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            leading: CircleAvatar(
              backgroundColor: isPositive ? Colors.green.shade50 : Colors.red.shade50,
              child: Icon(
                isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              item.description ?? (isPositive ? 'نقاط مكتسبة' : 'نقاط مستبدلة'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              item.createdAt.split('T').first,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            trailing: Text(
              isPositive ? '+${item.points}' : '${item.points}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }
}

// 3. تبويب شروط وسياسة الكسب
class _RulesTab extends StatelessWidget {
  const _RulesTab({
    required this.summary,
    required this.onRefresh,
  });

  final PointsSummary? summary;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final rules = summary?.rules ?? [];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // كارت السياسة
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            color: Colors.blue.shade50,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.policy_outlined, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'سياسة تصفير النقاط',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary?.policyText.isNotEmpty == true
                        ? summary!.policyText
                        : 'يتم تصفير النقاط دورياً كل 6 أشهر من بدء الدورة. ننصحك باستبدال نقاطك بالهدايا قبل تاريخ التصفير.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13, height: 1.4),
                  ),
                  if (summary?.nextResetDate.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      'تاريخ التصفير القادم: ${summary!.nextResetDate}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          const Text(
            'كيف تجمع النقاط؟',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          if (rules.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'سيتم نشر قواعد النقاط المتاحة لجميع الأقسام قريباً.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...rules.map((rule) {
              final isQty = rule.ruleType == 'quantity';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isQty ? Colors.orange.shade50 : Colors.teal.shade50,
                    child: Icon(
                      isQty ? Icons.inventory_2_outlined : Icons.monetization_on_outlined,
                      color: isQty ? Colors.orange : Colors.teal,
                    ),
                  ),
                  title: Text(
                    rule.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    rule.text,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${rule.points} نقطة',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
