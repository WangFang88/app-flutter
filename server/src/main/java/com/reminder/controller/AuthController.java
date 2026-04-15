package com.reminder.controller;

import com.reminder.dto.AuthResponse;
import com.reminder.entity.User;
import com.reminder.repository.UserRepository;
import com.reminder.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    @PostMapping("/anonymous")
    public ResponseEntity<?> anonymous(@RequestBody(required = false) Map<String, Object> body) {
        String id = UUID.randomUUID().toString();
        String label = body != null && body.containsKey("displayLabel")
            ? String.valueOf(body.get("displayLabel")).trim()
            : "用户" + id.substring(0, 6);

        User user = new User();
        user.setId(id);
        user.setDisplayLabel(label);
        user.setCreatedAt(System.currentTimeMillis());
        userRepository.save(user);

        String token = jwtUtil.generateToken(id);
        return ResponseEntity.ok(new AuthResponse(token, new AuthResponse.UserDto(id, label, "")));
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody Map<String, Object> body) {
        String email = String.valueOf(body.getOrDefault("email", "")).trim().toLowerCase();
        String password = String.valueOf(body.getOrDefault("password", ""));

        if (email.isEmpty() || password.length() < 6) {
            return ResponseEntity.badRequest().body(err("Invalid email or password"));
        }

        if (userRepository.existsByEmail(email)) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(err("Email already registered"));
        }

        String id = UUID.randomUUID().toString();
        String label = body.containsKey("displayLabel") && !String.valueOf(body.get("displayLabel")).trim().isEmpty()
            ? String.valueOf(body.get("displayLabel")).trim()
            : email.split("@")[0];

        User user = new User();
        user.setId(id);
        user.setDisplayLabel(label);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setCreatedAt(System.currentTimeMillis());
        userRepository.save(user);

        return ResponseEntity.ok(new AuthResponse(jwtUtil.generateToken(id), new AuthResponse.UserDto(id, label, email)));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, Object> body) {
        String email = String.valueOf(body.getOrDefault("email", "")).trim().toLowerCase();
        String password = String.valueOf(body.getOrDefault("password", ""));

        User user = userRepository.findByEmail(email).orElse(null);

        if (user == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(err("User not found"));
        }
        if (user.getPasswordHash() == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(err("Use anonymous or register"));
        }
        if (!passwordEncoder.matches(password, user.getPasswordHash())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(err("Invalid password"));
        }

        String token = jwtUtil.generateToken(user.getId());
        return ResponseEntity.ok(new AuthResponse(token, new AuthResponse.UserDto(
            user.getId(), user.getDisplayLabel(), user.getEmail() != null ? user.getEmail() : "")));
    }

    private static Map<String, Object> err(String message) {
        Map<String, Object> m = new HashMap<String, Object>();
        m.put("error", message);
        return m;
    }
}
