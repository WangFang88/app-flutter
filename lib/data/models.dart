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

class RemindEvent {
  final String reminderId;
  final String userId;
  final int at;
  final String userLabel;
  final String reminderTitle;

  RemindEvent({
    required this.reminderId,
    required this.userId,
    required this.at,
    required this.userLabel,
    required this.reminderTitle,
  });

  factory RemindEvent.fromJson(Map<String, dynamic> j) => RemindEvent(
        reminderId: j['reminderId'] ?? '',
        userId: j['userId'] ?? '',
        at: (j['at'] as num?)?.toInt() ?? 0,
        userLabel: j['userLabel'] ?? '匿名用户',
        reminderTitle: j['reminderTitle'] ?? '',
      );
}

class PublicStats {
  final List<int> hourlyByItem;
  final List<int> hourlyByRemind;

  PublicStats({required this.hourlyByItem, required this.hourlyByRemind});

  factory PublicStats.fromJson(Map<String, dynamic> j) {
    final scheduledAts = (j['scheduledAts'] as List<dynamic>?) ?? [];
    final supporterCounts = (j['supporterCounts'] as List<dynamic>?) ?? [];

    final hourlyByItem = List.filled(24, 0);
    final hourlyByRemind = List.filled(24, 0);

    for (var i = 0; i < scheduledAts.length; i++) {
      final hour = DateTime.fromMillisecondsSinceEpoch((scheduledAts[i] as num).toInt()).hour;
      hourlyByItem[hour]++;
      if (i < supporterCounts.length) {
        hourlyByRemind[hour] += (supporterCounts[i] as num).toInt();
      }
    }

    return PublicStats(hourlyByItem: hourlyByItem, hourlyByRemind: hourlyByRemind);
  }
}
