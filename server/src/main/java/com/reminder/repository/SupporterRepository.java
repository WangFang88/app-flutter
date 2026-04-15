package com.reminder.repository;

import com.reminder.entity.Supporter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;

public interface SupporterRepository extends JpaRepository<Supporter, Supporter.SupporterId> {
    long countByReminderId(String reminderId);
    boolean existsByReminderIdAndUserId(String reminderId, String userId);
    List<Supporter> findByUserId(String userId);
    List<Supporter> findByReminderId(String reminderId);
}
