package com.reminder.entity;

import javax.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "reminders")
public class Reminder {
    @Id
    @Column(length = 36)
    private String id;

    @Column(nullable = false, length = 500)
    private String title;

    @Column(name = "scheduled_at", nullable = false)
    private Long scheduledAt;

    @Column(name = "is_public", nullable = false)
    private Boolean isPublic;

    @Column(name = "author_id", nullable = false, length = 36)
    private String authorId;

    @Column(name = "created_at", nullable = false)
    private Long createdAt;

    @Column(name = "ios_initial_pushed_at")
    private Long iosInitialPushedAt;

    @Column(name = "ios_repeat_active", nullable = false)
    private Boolean iosRepeatActive = false;

    @Column(name = "ios_repeat_last_sent_at")
    private Long iosRepeatLastSentAt;

    @Column(name = "ios_repeat_sent_count", nullable = false)
    private Integer iosRepeatSentCount = 0;

    @Column(name = "ios_repeat_stopped_at")
    private Long iosRepeatStoppedAt;
}
