package com.reminder.entity;

import javax.persistence.*;
import lombok.Data;
import java.io.Serializable;

@Data
@Entity
@Table(name = "acknowledgements")
@IdClass(Acknowledgement.AcknowledgementId.class)
public class Acknowledgement {
    @Id
    @Column(name = "reminder_id", length = 36)
    private String reminderId;

    @Id
    @Column(name = "user_id", length = 36)
    private String userId;

    @Column(name = "acknowledged_at", nullable = false)
    private Long acknowledgedAt;

    @Data
    public static class AcknowledgementId implements Serializable {
        private String reminderId;
        private String userId;
    }
}
