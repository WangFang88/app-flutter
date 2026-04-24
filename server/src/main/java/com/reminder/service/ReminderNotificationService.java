package com.reminder.service;

import com.reminder.entity.DeviceToken;
import com.reminder.entity.Reminder;
import com.reminder.repository.DeviceTokenRepository;
import com.reminder.repository.SupporterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ReminderNotificationService {
    private final DeviceTokenRepository deviceTokenRepository;
    private final SupporterRepository supporterRepository;
    private final ApnsPushService apnsPushService;

    public void sendReminderUpdate(Reminder reminder) {
        List<DeviceToken> tokens = deviceTokenRepository.findByUserIdAndPlatformAndEnabledTrue(reminder.getAuthorId(), "ios");
        if (tokens.isEmpty()) {
            return;
        }
        if (Boolean.FALSE.equals(reminder.getIosRepeatActive()) && reminder.getIosInitialPushedAt() != null) {
            return;
        }
        int supporterCount = supporterRepository.countByReminderId(reminder.getId());
        String timeStr = formatTime(reminder.getScheduledAt());
        String body;
        String sound;
        if (supporterCount >= 5) {
            body = timeStr + " 提醒时间到！" + supporterCount + " 人和你一起！";
            sound = "reminder_high.caf";
        } else if (supporterCount >= 1) {
            body = timeStr + " 提醒时间到！" + supporterCount + " 人和你一起";
            sound = "reminder_medium.caf";
        } else {
            body = timeStr + " 提醒时间到！";
            sound = "reminder_low.caf";
        }
        Map<String, Object> payload = new HashMap<String, Object>();
        payload.put("reminderId", reminder.getId());
        payload.put("type", "reminder_due");
        payload.put("supporterCount", supporterCount);
        payload.put("scheduledAt", reminder.getScheduledAt());
        boolean sent = false;
        for (DeviceToken token : tokens) {
            sent = apnsPushService.sendReminder(token, reminder.getTitle(), body, sound, payload) || sent;
        }
        if (sent) {
            long now = System.currentTimeMillis();
            if (reminder.getIosInitialPushedAt() == null) {
                reminder.setIosInitialPushedAt(now);
            }
            reminder.setIosRepeatActive(true);
            reminder.setIosRepeatLastSentAt(now);
            reminder.setIosRepeatSentCount((reminder.getIosRepeatSentCount() == null ? 0 : reminder.getIosRepeatSentCount()) + 1);
            if (reminder.getIosRepeatSentCount() != null && reminder.getIosRepeatSentCount() >= 30) {
                reminder.setIosRepeatActive(false);
                reminder.setIosRepeatStoppedAt(now);
            }
        }
    }

    private String formatTime(Long scheduledAt) {
        java.util.Calendar calendar = java.util.Calendar.getInstance();
        calendar.setTimeInMillis(scheduledAt);
        return String.format("%02d:%02d", calendar.get(java.util.Calendar.HOUR_OF_DAY), calendar.get(java.util.Calendar.MINUTE));
    }
}
