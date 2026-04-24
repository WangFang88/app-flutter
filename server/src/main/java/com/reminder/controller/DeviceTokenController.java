package com.reminder.controller;

import com.reminder.entity.DeviceToken;
import com.reminder.repository.DeviceTokenRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

@RestController
@RequestMapping("/devices/tokens")
@RequiredArgsConstructor
public class DeviceTokenController {
    private static final Logger log = LoggerFactory.getLogger(DeviceTokenController.class);

    private final DeviceTokenRepository deviceTokenRepository;

    @PostMapping
    public ResponseEntity<?> registerToken(Authentication auth, @RequestBody Map<String, Object> body) {
        String userId = (String) auth.getPrincipal();
        String token = String.valueOf(body.getOrDefault("token", "")).trim();
        String platform = String.valueOf(body.getOrDefault("platform", "")).trim();
        String environment = String.valueOf(body.getOrDefault("environment", "production")).trim();
        if (token.isEmpty() || platform.isEmpty()) {
            return ResponseEntity.badRequest().body(err("token and platform required"));
        }
        Optional<DeviceToken> existing = deviceTokenRepository.findByToken(token);
        DeviceToken deviceToken = existing.orElseGet(DeviceToken::new);
        if (deviceToken.getId() == null) {
            deviceToken.setId(UUID.randomUUID().toString());
            deviceToken.setCreatedAt(System.currentTimeMillis());
        }
        deviceToken.setUserId(userId);
        deviceToken.setPlatform(platform);
        deviceToken.setToken(token);
        deviceToken.setEnvironment(environment);
        deviceToken.setEnabled(true);
        deviceToken.setLastSeenAt(System.currentTimeMillis());
        deviceTokenRepository.save(deviceToken);
        log.info("Registered device token for user {} on platform {} with environment {}", userId, platform, environment);
        return ResponseEntity.ok(single("ok", true));
    }

    @DeleteMapping("/{token}")
    public ResponseEntity<?> disableToken(Authentication auth, @PathVariable String token) {
        String userId = (String) auth.getPrincipal();
        DeviceToken deviceToken = deviceTokenRepository.findByToken(token).orElse(null);
        if (deviceToken == null || !userId.equals(deviceToken.getUserId())) {
            return ResponseEntity.ok(single("ok", true));
        }
        deviceToken.setEnabled(false);
        deviceToken.setLastSeenAt(System.currentTimeMillis());
        deviceTokenRepository.save(deviceToken);
        return ResponseEntity.ok(single("ok", true));
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
