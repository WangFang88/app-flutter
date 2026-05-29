package com.reminder.controller;

import com.reminder.entity.Reminder;
import com.reminder.entity.Supporter;
import com.reminder.entity.User;
import com.reminder.repository.ReminderRepository;
import com.reminder.repository.SupporterRepository;
import com.reminder.repository.UserRepository;
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
    private final UserRepository userRepository;

    @GetMapping("/my")
    public ResponseEntity<?> getMyStats(Authentication auth) {
        String authorId = (String) auth.getPrincipal();
        List<Reminder> myReminders = reminderRepository.findByAuthorId(authorId);

        int publishedWithReminds = 0;
        int totalRemindClicks = 0;
        List<Map<String, Object>> whoReminded = new ArrayList<>();
        List<Long> scheduledAts = new ArrayList<>();

        for (Reminder reminder : myReminders) {
            List<Supporter> supporters = supporterRepository.findByReminderId(reminder.getId());
            if (supporters.isEmpty()) continue;

            publishedWithReminds++;
            totalRemindClicks += supporters.size();

            scheduledAts.add(reminder.getScheduledAt());

            for (Supporter supporter : supporters) {

                Map<String, Object> event = new HashMap<>();
                event.put("reminderId", reminder.getId());
                event.put("userId", supporter.getUserId());
                event.put("at", supporter.getRemindedAt());
                event.put("reminderTitle", reminder.getTitle());
                whoReminded.add(event);
            }
        }

        whoReminded.sort((a, b) -> Long.compare((Long) b.get("at"), (Long) a.get("at")));

        Set<String> userIds = new HashSet<>();
        for (Map<String, Object> event : whoReminded) {
            userIds.add((String) event.get("userId"));
        }
        Map<String, String> userLabelMap = new HashMap<>();
        for (User user : userRepository.findAllById(userIds)) {
            userLabelMap.put(user.getId(), user.getDisplayLabel());
        }
        for (Map<String, Object> event : whoReminded) {
            event.put("userLabel", userLabelMap.getOrDefault(event.get("userId"), "匿名用户"));
        }

        Map<String, Object> result = new HashMap<>();
        result.put("publishedWithReminds", publishedWithReminds);
        result.put("totalRemindClicks", totalRemindClicks);
        result.put("whoReminded", whoReminded);
        result.put("scheduledAts", scheduledAts);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/public")
    public ResponseEntity<?> getPublicStats() {
        List<Reminder> publicReminders = reminderRepository.findByIsPublicTrueOrderByScheduledAtAsc();

        List<Long> scheduledAts = new ArrayList<>();
        List<Integer> supporterCounts = new ArrayList<>();

        for (Reminder reminder : publicReminders) {
            scheduledAts.add(reminder.getScheduledAt());
            supporterCounts.add((int) supporterRepository.countByReminderId(reminder.getId()));
        }

        Map<String, Object> result = new HashMap<>();
        result.put("scheduledAts", scheduledAts);
        result.put("supporterCounts", supporterCounts);
        return ResponseEntity.ok(result);
    }
}
