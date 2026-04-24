package com.reminder.entity;

import lombok.Data;

import javax.persistence.*;

@Data
@Entity
@Table(name = "device_tokens")
public class DeviceToken {
    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "user_id", nullable = false, length = 36)
    private String userId;

    @Column(nullable = false, length = 16)
    private String platform;

    @Column(nullable = false, length = 255, unique = true)
    private String token;

    @Column(length = 32)
    private String environment;

    @Column(nullable = false)
    private Boolean enabled;

    @Column(name = "created_at", nullable = false)
    private Long createdAt;

    @Column(name = "last_seen_at", nullable = false)
    private Long lastSeenAt;
}
