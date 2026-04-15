package com.reminder.controller;

import com.reminder.entity.User;
import com.reminder.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @PatchMapping("/me")
    public ResponseEntity<?> updateProfile(Authentication auth, @RequestBody Map<String, Object> body) {
        String userId = (String) auth.getPrincipal();
        String label = body.containsKey("displayLabel") ? String.valueOf(body.get("displayLabel")).trim() : "";

        if (label.isEmpty()) {
            Map<String, Object> err = new HashMap<String, Object>();
            err.put("error", "displayLabel required");
            return ResponseEntity.badRequest().body(err);
        }

        User user = userRepository.findById(userId).orElseThrow(new java.util.function.Supplier<RuntimeException>() {
            public RuntimeException get() { return new RuntimeException("User not found"); }
        });
        user.setDisplayLabel(label);
        userRepository.save(user);

        Map<String, Object> ok = new HashMap<String, Object>();
        ok.put("ok", true);
        return ResponseEntity.ok(ok);
    }
}
