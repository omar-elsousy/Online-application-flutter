import 'dart:async';
import 'package:flutter/material.dart';
import '../../controllers/app_scope.dart';
import '../../models/api_item.dart';
import '../../widgets/app_error_banner.dart';
import '../category_products_screen.dart';
import '../company_categories_screen.dart';
import '../latest_offers_screen.dart';
import '../product_details_screen.dart';
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
          
          // إخفاء الـ Carousel عند البحث لترك مساحة لنتائج البحث
          if (query.isEmpty) ...[
            _SectionHeader(title: 'Sections', action: '${state.sections.length} found'),
            const SizedBox(height: 10),
            if (state.sections.isEmpty)
              const _EmptyState(message: 'No sections returned yet.')
            else
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
    if (widget.sections.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_current + 1) % widget.sections.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (value) => setState(() => _current = value),
            itemCount: widget.sections.length,
            itemBuilder: (_, index) {
              final section = widget.sections[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: section.imageUrl == null
                    ? Container(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Center(child: Icon(Icons.image_outlined, size: 36)),
                      )
                    : Image.network(
                        section.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: const Center(child: Icon(Icons.broken_image_outlined, size: 36)),
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
            widget.sections.length,
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
