package com.reminder.repository;

import com.reminder.entity.Acknowledgement;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AcknowledgementRepository extends JpaRepository<Acknowledgement, Acknowledgement.AcknowledgementId> {
    boolean existsByReminderIdAndUserId(String reminderId, String userId);
}
