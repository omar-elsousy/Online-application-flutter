import 'dart:async';
import 'package:flutter/material.dart';
import '../../controllers/app_scope.dart';
import '../../models/api_item.dart';
import '../../widgets/app_error_banner.dart';
import '../category_products_screen.dart';
import '../company_categories_screen.dart';
import '../latest_offers_screen.dart';
import '../product_details_screen.dart';
import '../points_screen.dart';
import '../../widgets/product_card.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    
    final filteredCompanies = state.companies
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final filteredLatestOffers = state.latestOffers
        .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return RefreshIndicator(
      onRefresh: state.loadHome,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              hintText: 'Search for products or companies',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 18),
          if (state.error != null) ...[
            AppErrorBanner(message: state.error!),
            const SizedBox(height: 14),
          ],
          
          // كارت My Points
          if (query.isEmpty) ...[
            _MyPointsCard(
              points: state.userPoints,
              nextResetDate: state.pointsSummary?.nextResetDate,
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const PointsScreen()),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // إخفاء الـ Carousel عند البحث لترك مساحة لنتائج البحث
          if (query.isEmpty) ...[
            _SectionHeader(
              title: 'Sections',
              action: '${state.sections.isNotEmpty ? state.sections.length : 3} found',
            ),
            const SizedBox(height: 10),
            _SectionsCarousel(sections: state.sections),
            const SizedBox(height: 22),
          ],
          
          if (filteredLatestOffers.isNotEmpty) ...[
            _SectionHeader(
              title: 'Latest Offers', 
              action: 'View All',
              onActionTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LatestOffersScreen()),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: filteredLatestOffers.length,
                itemBuilder: (context, index) {
                  final product = filteredLatestOffers[index];
                  return Container(
                    width: 220, 
                    margin: const EdgeInsets.only(right: 12),
                    child: ProductCard(
                      product: product,
                      quantity: state.getProductQuantity(product.id),
                      onUpdateQuantity: (delta) => state.updateCartQuantity(product, delta),
                      isFavourite: state.isFavourite(product.id),
                      onFavourite: () async {
                        if (state.isFavourite(product.id)) {
                          await state.removeFromFavourites(product);
                        } else {
                          await state.addToFavourites(product);
                        }
                      },
                      onAdd: () => state.addToCart(product),
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(product: product),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
          ],

          if (filteredCompanies.isNotEmpty) ...[
            _SectionHeader(title: 'Companies', action: '${filteredCompanies.length} found'),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: filteredCompanies.length,
              itemBuilder: (_, index) {
                final company = filteredCompanies[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CompanyCategoriesScreen(company: company)),
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: company.imageUrl == null || company.imageUrl!.isEmpty
                                ? const Icon(Icons.business_outlined, size: 28, color: Colors.grey)
                                : Image.network(
                                    company.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 28, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              company.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          
          if (filteredCompanies.isEmpty && filteredLatestOffers.isEmpty)
            const _EmptyState(message: 'No results found matching your search.'),
        ],
      ),
    );
  }
}

class _SectionsCarousel extends StatefulWidget {
  const _SectionsCarousel({required this.sections});

  final List<ApiItem> sections;

  @override
  State<_SectionsCarousel> createState() => _SectionsCarouselState();
}

class _SectionsCarouselState extends State<_SectionsCarousel> {
  final PageController _controller = PageController(viewportFraction: 1);
  Timer? _timer;
  int _current = 0;

  static final List<ApiItem> _defaultPlaceholders = [
    ApiItem(
      id: 'placeholder_1',
      title: 'عروض حصرية',
      subtitle: 'اكتشف أفضل الخصومات والعروض الترويجية اليوم',
      raw: {'is_placeholder': true, 'action_type': 'none'},
    ),
    ApiItem(
      id: 'placeholder_2',
      title: 'أحدث المنتجات',
      subtitle: 'تصفح تشكيلة واسعة من أحدث البضائع المتاحة',
      raw: {'is_placeholder': true, 'action_type': 'none'},
    ),
    ApiItem(
      id: 'placeholder_3',
      title: 'مجموعة منصور',
      subtitle: 'جودة وثقة وسرعة في التوصيل لجميع الطلبات',
      raw: {'is_placeholder': true, 'action_type': 'none'},
    ),
  ];

  List<ApiItem> get _items => widget.sections.isNotEmpty ? widget.sections : _defaultPlaceholders;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant _SectionsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      _current = 0;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (_items.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_current + 1) % _items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _handleSectionAction(BuildContext context, String type, String id, String actionName) {
    if (type == 'product') {
      final placeholderProduct = ApiItem(id: id, title: actionName);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: placeholderProduct)),
      );
    } else if (type == 'category') {
      final placeholderCategory = ApiItem(id: id, title: actionName);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CategoryProductsScreen(category: placeholderCategory)),
      );
    }
  }

  Widget _buildPlaceholderCard(BuildContext context, ApiItem section, int index) {
    final List<List<Color>> gradients = [
      [const Color(0xFF2F6F73), const Color(0xFF1B494D)],
      [const Color(0xFFE9A23B), const Color(0xFFB8761E)],
      [const Color(0xFF386B8C), const Color(0xFF1E4358)],
    ];
    final List<IconData> icons = [
      Icons.local_offer_rounded,
      Icons.auto_awesome_rounded,
      Icons.verified_rounded,
    ];

    final gradient = gradients[index % gradients.length];
    final icon = icons[index % icons.length];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Mansour',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  section.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (section.subtitle != null && section.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    section.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (value) => setState(() => _current = value),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final section = items[index];
              
              final String? actionType = section.raw['action_type']?.toString();
              final String? actionId = section.raw['action_id']?.toString();
              final String actionName = section.raw['action_name']?.toString() ?? section.title;
              final bool isClickable = actionType != null && actionType != 'none' && actionId != null;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: !isClickable 
                    ? null 
                    : () => _handleSectionAction(context, actionType, actionId, actionName),
                  borderRadius: BorderRadius.circular(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: (section.imageUrl == null || section.imageUrl!.isEmpty)
                        ? _buildPlaceholderCard(context, section, index)
                        : Image.network(
                            section.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => _buildPlaceholderCard(context, section, index),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (index) => GestureDetector(
              onTap: () => _controller.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _current == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _current == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action, this.onActionTap});
  final String title;
  final String action;
  final VoidCallback? onActionTap;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        InkWell(
          onTap: onActionTap,
          child: Text(action, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}

class _MyPointsCard extends StatelessWidget {
  const _MyPointsCard({
    required this.points,
    this.nextResetDate,
    required this.onTap,
  });

  final int points;
  final String? nextResetDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                Colors.amber.shade800,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Points (نقاطي)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nextResetDate != null && nextResetDate!.isNotEmpty
                          ? 'استبدل نقاطك قبل التصفير: $nextResetDate'
                          : 'اضغط لعرض المكافآت وسياسة التصفير',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$points نقطة',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

