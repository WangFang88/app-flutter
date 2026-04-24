package com.reminder.service;

import com.reminder.entity.Acknowledgement;
import com.reminder.entity.Reminder;
import com.reminder.repository.AcknowledgementRepository;
import com.reminder.repository.ReminderRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class ReminderPushScheduler {
    private static final Logger log = LoggerFactory.getLogger(ReminderPushScheduler.class);

    private final ReminderRepository reminderRepository;
    private final AcknowledgementRepository acknowledgementRepository;
    private final ReminderNotificationService reminderNotificationService;

    @Scheduled(fixedDelay = 60000)
    public void sendDueReminderPushes() {
        long now = System.currentTimeMillis();
        List<Reminder> reminders = reminderRepository.findByScheduledAtLessThanEqual(now);
        log.info("ReminderPushScheduler scanned {} due reminders at {}", reminders.size(), now);
        for (Reminder reminder : reminders) {
            if (acknowledgementRepository.existsByReminderIdAndUserId(reminder.getId(), reminder.getAuthorId())) {
                reminder.setIosRepeatActive(false);
                reminder.setIosRepeatStoppedAt(now);
                continue;
            }
            if (reminder.getIosRepeatSentCount() != null && reminder.getIosRepeatSentCount() >= 30) {
                reminder.setIosRepeatActive(false);
                reminder.setIosRepeatStoppedAt(now);
                continue;
            }
            if (reminder.getIosRepeatLastSentAt() != null && now - reminder.getIosRepeatLastSentAt() < 120000L) {
                continue;
            }
            reminderNotificationService.sendReminderUpdate(reminder);
        }
    }
}
