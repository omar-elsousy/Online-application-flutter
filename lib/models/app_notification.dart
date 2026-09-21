class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawRead = json['is_read'];
    return AppNotification(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? 'إشعار جديد',
      body: json['body']?.toString() ?? '',
      isRead: rawRead == true || rawRead?.toString() == '1',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
