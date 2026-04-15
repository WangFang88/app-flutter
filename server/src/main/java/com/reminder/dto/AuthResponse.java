package com.reminder.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class AuthResponse {
    private String token;
    private UserDto user;

    @Data
    @AllArgsConstructor
    public static class UserDto {
        private String id;
        private String displayLabel;
        private String email;
    }
}
