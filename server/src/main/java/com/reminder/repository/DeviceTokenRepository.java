package com.reminder.repository;

import com.reminder.entity.DeviceToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, String> {
    Optional<DeviceToken> findByToken(String token);
    List<DeviceToken> findByUserIdAndPlatformAndEnabledTrue(String userId, String platform);
}
