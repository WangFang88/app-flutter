package com.reminder.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class ReminderDto {
    private String id;
    private String title;
    private Long scheduledAt;
    private Boolean isPublic;
    private String authorId;
    private Long createdAt;
}
