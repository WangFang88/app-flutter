package com.reminder.service;

import com.eatthepath.pushy.apns.ApnsClient;
import com.eatthepath.pushy.apns.ApnsClientBuilder;
import com.eatthepath.pushy.apns.PushNotificationResponse;
import com.eatthepath.pushy.apns.auth.ApnsSigningKey;
import com.eatthepath.pushy.apns.util.SimpleApnsPushNotification;
import com.reminder.entity.DeviceToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.io.File;
import java.util.Map;

@Service
public class ApnsPushService {
    private static final Logger log = LoggerFactory.getLogger(ApnsPushService.class);

    @Value("${apns.enabled:false}")
    private boolean enabled;

    @Value("${apns.team-id:}")
    private String teamId;

    @Value("${apns.key-id:}")
    private String keyId;

    @Value("${apns.bundle-id:}")
    private String bundleId;

    @Value("${apns.private-key-path:}")
    private String privateKeyPath;

    @Value("${apns.use-sandbox:true}")
    private boolean useSandbox;

    private ApnsClient client;

    @PostConstruct
    public void init() throws Exception {
        if (!enabled) {
            log.info("APNs is disabled via configuration");
            return;
        }
        if (teamId.isEmpty() || keyId.isEmpty() || privateKeyPath.isEmpty()) {
            log.warn("APNs is enabled but configuration is incomplete. teamIdPresent={}, keyIdPresent={}, privateKeyPathPresent={}",
                !teamId.isEmpty(), !keyId.isEmpty(), !privateKeyPath.isEmpty());
            return;
        }
        client = new ApnsClientBuilder()
            .setApnsServer(useSandbox ? ApnsClientBuilder.DEVELOPMENT_APNS_HOST : ApnsClientBuilder.PRODUCTION_APNS_HOST)
            .setSigningKey(ApnsSigningKey.loadFromPkcs8File(new File(privateKeyPath), teamId, keyId))
            .build();
        log.info("APNs client initialized. sandbox={}, bundleId={}, keyPath={}", useSandbox, bundleId, privateKeyPath);
    }

    public boolean isEnabled() {
        return enabled && client != null;
    }

    public boolean sendReminder(DeviceToken deviceToken, String title, String body, String sound, Map<String, Object> payloadData) {
        if (!isEnabled() || !"ios".equals(deviceToken.getPlatform())) {
            return false;
        }
        try {
            // 手动构建 JSON，将 category 放入 aps 字典（Pushy 0.15.4 无 setCategory）
            StringBuilder sb = new StringBuilder();
            sb.append("{\"aps\":{\"alert\":{\"title\":\"").append(escapeJson(title))
              .append("\",\"body\":\"").append(escapeJson(body))
              .append("\"},\"sound\":\"").append(escapeJson(sound))
              .append("\",\"category\":\"reminder_ack\"}");
            for (Map.Entry<String, Object> entry : payloadData.entrySet()) {
                sb.append(",\"").append(escapeJson(entry.getKey())).append("\":");
                Object v = entry.getValue();
                if (v instanceof String) {
                    sb.append("\"").append(escapeJson((String) v)).append("\"");
                } else {
                    sb.append(v);
                }
            }
            sb.append("}");
            String payload = sb.toString();
            String token = com.eatthepath.pushy.apns.util.TokenUtil.sanitizeTokenString(deviceToken.getToken());
            SimpleApnsPushNotification notification = new SimpleApnsPushNotification(token, bundleId, payload);
            PushNotificationResponse<SimpleApnsPushNotification> response = client.sendNotification(notification).get();
            if (!response.isAccepted()) {
                log.warn("APNs rejected token for user {}. reason={}, invalidationTimestamp={}",
                    deviceToken.getUserId(), response.getRejectionReason(), response.getTokenInvalidationTimestamp());
            }
            return response.isAccepted();
        } catch (Exception e) {
            log.warn("APNs send failed for user {}: {}", deviceToken.getUserId(), e.toString());
            return false;
        }
    }

    private static String escapeJson(String s) {
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
}
