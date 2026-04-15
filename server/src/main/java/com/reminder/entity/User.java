package com.reminder.entity;

import javax.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "users")
public class User {
    @Id
    @Column(length = 36)
    private String id;

    @Column(name = "display_label", nullable = false)
    private String displayLabel;

    @Column(unique = true)
    private String email;

    @Column(name = "password_hash")
    private String passwordHash;

    @Column(name = "created_at", nullable = false)
    private Long createdAt;
}
