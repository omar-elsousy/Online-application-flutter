import '../core/network/api_config.dart';

class PointRule {
  final String categoryName;
  final String ruleType;
  final double threshold;
  final int points;
  final String text;

  PointRule({
    required this.categoryName,
    required this.ruleType,
    required this.threshold,
    required this.points,
    required this.text,
  });

  factory PointRule.fromJson(Map<String, dynamic> json) {
    return PointRule(
      categoryName: json['category_name']?.toString() ?? 'All Categories',
      ruleType: json['rule_type']?.toString() ?? 'quantity',
      threshold: double.tryParse(json['threshold']?.toString() ?? '1') ?? 1.0,
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
    );
  }
}

class PointsSummary {
  final int points;
  final int resetMonths;
  final String nextResetDate;
  final String policyText;
  final List<PointRule> rules;

  PointsSummary({
    required this.points,
    required this.resetMonths,
    required this.nextResetDate,
    required this.policyText,
    required this.rules,
  });

  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    final rulesList = (json['rules'] as List<dynamic>?)
            ?.map((r) => PointRule.fromJson(Map<String, dynamic>.from(r)))
            .toList() ??
        [];

    return PointsSummary(
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      resetMonths: int.tryParse(json['reset_months']?.toString() ?? '6') ?? 6,
      nextResetDate: json['next_reset_date']?.toString() ?? '',
      policyText: json['policy_text']?.toString() ?? '',
      rules: rulesList,
    );
  }
}

class PointsGift {
  final int id;
  final String title;
  final String? description;
  final int pointsRequired;
  final String? imageUrl;
  final bool canRedeem;

  PointsGift({
    required this.id,
    required this.title,
    this.description,
    required this.pointsRequired,
    this.imageUrl,
    required this.canRedeem,
  });

  factory PointsGift.fromJson(Map<String, dynamic> json) {
    var image = json['image']?.toString().trim();
    if (image != null && (image.isEmpty || image == 'null')) {
      image = null;
    }

    if (image != null) {
      if (image.startsWith('//')) {
        image = 'http:$image';
      }
      if (image.contains('localhost') || image.contains('127.0.0.1')) {
        image = image.replaceFirst(
          RegExp(r'https?://(localhost|127\.0\.0\.1)(:\d+)?'),
          ApiConfig.baseImageUrl,
        );
      } else if (!image.startsWith('http')) {
        final base = ApiConfig.baseImageUrl;
        final separator = image.startsWith('/') ? '' : '/';
        image = '$base$separator$image';
      }
    }

    return PointsGift(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      pointsRequired: int.tryParse(json['points_required']?.toString() ?? '0') ?? 0,
      imageUrl: image,
      canRedeem: json['can_redeem'] == true,
    );
  }
}

class PointsHistoryItem {
  final int id;
  final int points;
  final String type;
  final String? description;
  final String createdAt;

  PointsHistoryItem({
    required this.id,
    required this.points,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory PointsHistoryItem.fromJson(Map<String, dynamic> json) {
    return PointsHistoryItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
