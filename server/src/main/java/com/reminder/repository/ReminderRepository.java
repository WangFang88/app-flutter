package com.reminder.repository;

import com.reminder.entity.Reminder;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ReminderRepository extends JpaRepository<Reminder, String> {
    List<Reminder> findByIsPublicTrueOrderByScheduledAtAsc();
    List<Reminder> findByAuthorIdOrderByScheduledAtDesc(String authorId);
    List<Reminder> findByAuthorId(String authorId);
}
