package com.reminder.controller;

import com.reminder.dto.ReminderDto;
import com.reminder.entity.Acknowledgement;
import com.reminder.entity.Reminder;
import com.reminder.entity.Supporter;
import com.reminder.repository.AcknowledgementRepository;
import com.reminder.repository.ReminderRepository;
import com.reminder.repository.SupporterRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/reminders")
@RequiredArgsConstructor
public class ReminderController {

    private final ReminderRepository reminderRepository;
    private final SupporterRepository supporterRepository;
    private final AcknowledgementRepository acknowledgementRepository;

    @GetMapping("/public")
    public ResponseEntity<?> getPublicReminders() {
        return ResponseEntity.ok(reminderRepository.findByIsPublicTrueOrderByScheduledAtAsc()
            .stream().map(this::toDto).collect(Collectors.toList()));
    }

    @GetMapping("/mine")
    public ResponseEntity<?> getMyReminders(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(reminderRepository.findByAuthorIdOrderByScheduledAtDesc(userId)
            .stream().map(this::toDto).collect(Collectors.toList()));
    }

    @PostMapping
    public ResponseEntity<?> createReminder(Authentication auth, @RequestBody Map<String, Object> body) {
        String userId = (String) auth.getPrincipal();
        String title = String.valueOf(body.getOrDefault("title", "")).trim();
        Object scheduledAtObj = body.get("scheduledAt");

        if (title.isEmpty() || scheduledAtObj == null) {
            return ResponseEntity.badRequest().body(err("title and scheduledAt required"));
        }
        if (!(scheduledAtObj instanceof Number)) {
            return ResponseEntity.badRequest().body(err("scheduledAt must be a number"));
        }

        Reminder reminder = new Reminder();
        reminder.setId(UUID.randomUUID().toString());
        reminder.setTitle(title);
        reminder.setScheduledAt(((Number) scheduledAtObj).longValue());
        reminder.setIsPublic(Boolean.TRUE.equals(body.get("isPublic")));
        reminder.setAuthorId(userId);
        reminder.setCreatedAt(System.currentTimeMillis());
        reminderRepository.save(reminder);

        return ResponseEntity.ok(single("id", reminder.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getReminder(Authentication auth, @PathVariable String id) {
        String userId = (String) auth.getPrincipal();
        Reminder reminder = reminderRepository.findById(id).orElse(null);
        if (reminder == null || (!reminder.getIsPublic() && !reminder.getAuthorId().equals(userId))) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(err("Not found"));
        }
        return ResponseEntity.ok(toDto(reminder));
    }

    @GetMapping("/{id}/supporters/count")
    public ResponseEntity<?> getSupportersCount(@PathVariable String id) {
        return ResponseEntity.ok(single("count", supporterRepository.countByReminderId(id)));
    }

    @GetMapping("/{id}/supporters/{userId}/has")
    public ResponseEntity<?> hasSupporter(Authentication auth, @PathVariable String id, @PathVariable String userId) {
        if (!userId.equals((String) auth.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(err("Forbidden"));
        }
        return ResponseEntity.ok(single("has", supporterRepository.existsByReminderIdAndUserId(id, userId)));
    }

    @GetMapping("/{id}/acknowledgements/{userId}/has")
    public ResponseEntity<?> hasAcknowledgement(Authentication auth, @PathVariable String id, @PathVariable String userId) {
        if (!userId.equals((String) auth.getPrincipal())) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(err("Forbidden"));
        }
        return ResponseEntity.ok(single("has", acknowledgementRepository.existsByReminderIdAndUserId(id, userId)));
    }

    @PostMapping("/{id}/remind")
    @Transactional
    public ResponseEntity<?> remindReminder(Authentication auth, @PathVariable String id) {
        String userId = (String) auth.getPrincipal();
        Reminder reminder = reminderRepository.findById(id).orElse(null);
        if (reminder == null) return ResponseEntity.status(HttpStatus.NOT_FOUND).body(err("Not found"));
        if (!reminder.getIsPublic()) return ResponseEntity.badRequest().body(err("Reminder is not public"));
        if (reminder.getAuthorId().equals(userId)) return ResponseEntity.badRequest().body(err("Cannot remind your own"));

        boolean alreadyExists = supporterRepository.existsByReminderIdAndUserId(id, userId);
        if (!alreadyExists) {
            Supporter supporter = new Supporter();
            supporter.setReminderId(id);
            supporter.setUserId(userId);
            supporter.setRemindedAt(System.currentTimeMillis());
            supporterRepository.save(supporter);
        }
        return ResponseEntity.ok(single("created", !alreadyExists));
    }

    @PostMapping("/{id}/acknowledge")
    public ResponseEntity<?> acknowledgeReminder(Authentication auth, @PathVariable String id) {
        String userId = (String) auth.getPrincipal();
        Acknowledgement ack = new Acknowledgement();
        ack.setReminderId(id);
        ack.setUserId(userId);
        ack.setAcknowledgedAt(System.currentTimeMillis());
        acknowledgementRepository.save(ack);
        return ResponseEntity.ok(single("ok", true));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<?> updateReminder(Authentication auth, @PathVariable String id, @RequestBody Map<String, Object> body) {
        String userId = (String) auth.getPrincipal();
        Reminder reminder = reminderRepository.findById(id).orElse(null);
        if (reminder == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(err("Not found"));
        }
        if (!reminder.getAuthorId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(err("Not your reminder"));
        }

        if (body.containsKey("title")) {
            String title = String.valueOf(body.get("title")).trim();
            if (!title.isEmpty()) {
                reminder.setTitle(title);
            }
        }
        if (body.containsKey("scheduledAt") && body.get("scheduledAt") instanceof Number) {
            reminder.setScheduledAt(((Number) body.get("scheduledAt")).longValue());
        }
        if (body.containsKey("isPublic")) {
            reminder.setIsPublic(Boolean.TRUE.equals(body.get("isPublic")));
        }

        reminderRepository.save(reminder);
        return ResponseEntity.ok(toDto(reminder));
    }

    @DeleteMapping("/mine/all")
    @Transactional
    public ResponseEntity<?> deleteAllMyReminders(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        reminderRepository.deleteByAuthorId(userId);
        return ResponseEntity.ok(single("ok", true));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteReminder(Authentication auth, @PathVariable String id) {
        String userId = (String) auth.getPrincipal();
        Reminder reminder = reminderRepository.findById(id).orElse(null);
        if (reminder == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(err("Not found"));
        }
        if (!reminder.getAuthorId().equals(userId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(err("Not your reminder"));
        }

        reminderRepository.deleteById(id);
        return ResponseEntity.ok(single("ok", true));
    }

    @GetMapping("/authored/list")
    public ResponseEntity<?> getAuthoredReminders(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(reminderRepository.findByAuthorId(userId)
            .stream().map(this::toDto).collect(Collectors.toList()));
    }

    @GetMapping("/supported/ids")
    public ResponseEntity<?> getSupportedIds(Authentication auth) {
        String userId = (String) auth.getPrincipal();
        return ResponseEntity.ok(supporterRepository.findByUserId(userId)
            .stream().map(Supporter::getReminderId).collect(Collectors.toList()));
    }

    private ReminderDto toDto(Reminder r) {
        return new ReminderDto(r.getId(), r.getTitle(), r.getScheduledAt(), r.getIsPublic(), r.getAuthorId(), r.getCreatedAt());
    }

    private static Map<String, Object> err(String message) {
        Map<String, Object> m = new HashMap<String, Object>();
        m.put("error", message);
        return m;
    }

    private static Map<String, Object> single(String key, Object value) {
        Map<String, Object> m = new HashMap<String, Object>();
        m.put(key, value);
        return m;
    }
}
