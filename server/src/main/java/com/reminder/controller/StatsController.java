package com.reminder.controller;

import com.reminder.entity.Reminder;
import com.reminder.entity.Supporter;
import com.reminder.repository.ReminderRepository;
import com.reminder.repository.SupporterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.*;

@RestController
@RequestMapping("/stats")
@RequiredArgsConstructor
public class StatsController {

    private final ReminderRepository reminderRepository;
    private final SupporterRepository supporterRepository;

    @GetMapping("/my")
    public ResponseEntity<?> getMyStats(Authentication auth) {
        String authorId = (String) auth.getPrincipal();
        List<Reminder> myReminders = reminderRepository.findByAuthorId(authorId);

        int publishedWithReminds = 0;
        int totalRemindClicks = 0;
        List<Map<String, Object>> whoReminded = new ArrayList<>();
        int[] remindEventByHour = new int[24];
        int[] scheduledReminderByHour = new int[24];

        for (Reminder reminder : myReminders) {
            List<Supporter> supporters = supporterRepository.findByReminderId(reminder.getId());
            if (supporters.isEmpty()) continue;

            publishedWithReminds++;
            totalRemindClicks += supporters.size();

            Calendar cal = Calendar.getInstance();
            cal.setTimeInMillis(reminder.getScheduledAt());
            scheduledReminderByHour[cal.get(Calendar.HOUR_OF_DAY)]++;

            for (Supporter supporter : supporters) {
                cal.setTimeInMillis(supporter.getRemindedAt());
                remindEventByHour[cal.get(Calendar.HOUR_OF_DAY)]++;

                Map<String, Object> event = new HashMap<>();
                event.put("reminderId", reminder.getId());
                event.put("userId", supporter.getUserId());
                event.put("at", supporter.getRemindedAt());
                whoReminded.add(event);
            }
        }

        whoReminded.sort((a, b) -> Long.compare((Long) b.get("at"), (Long) a.get("at")));

        Map<String, Object> result = new HashMap<>();
        result.put("publishedWithReminds", publishedWithReminds);
        result.put("totalRemindClicks", totalRemindClicks);
        result.put("whoReminded", whoReminded);
        result.put("remindEventByHour", remindEventByHour);
        result.put("scheduledReminderByHour", scheduledReminderByHour);

        return ResponseEntity.ok(result);
    }
}
