class Reminder {
  final String id;
  final String title;
  final int scheduledAtMillis;
  final bool isPublic;
  final String authorId;
  final int createdAtMillis;

  Reminder({
    required this.id,
    required this.title,
    required this.scheduledAtMillis,
    required this.isPublic,
    required this.authorId,
    required this.createdAtMillis,
  });

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        scheduledAtMillis: j['scheduledAt'] ?? 0,
        isPublic: j['isPublic'] ?? false,
        authorId: j['authorId'] ?? '',
        createdAtMillis: j['createdAt'] ?? 0,
      );
}
