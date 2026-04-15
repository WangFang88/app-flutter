package com.reminder.entity;

import javax.persistence.*;
import lombok.Data;
import java.io.Serializable;

@Data
@Entity
@Table(name = "supporters")
@IdClass(Supporter.SupporterId.class)
public class Supporter {
    @Id
    @Column(name = "reminder_id", length = 36)
    private String reminderId;

    @Id
    @Column(name = "user_id", length = 36)
    private String userId;

    @Column(name = "reminded_at", nullable = false)
    private Long remindedAt;

    @Data
    public static class SupporterId implements Serializable {
        private String reminderId;
        private String userId;
    }
}
