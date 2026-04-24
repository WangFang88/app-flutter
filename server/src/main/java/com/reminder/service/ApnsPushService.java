package com.reminder.service;

import com.eatthepath.pushy.apns.ApnsClient;
import com.eatthepath.pushy.apns.ApnsClientBuilder;
import com.eatthepath.pushy.apns.PushNotificationResponse;
import com.eatthepath.pushy.apns.auth.ApnsSigningKey;
import com.eatthepath.pushy.apns.util.ApnsPayloadBuilder;
import com.eatthepath.pushy.apns.util.SimpleApnsPushNotification;
import com.reminder.entity.DeviceToken;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.io.File;
import java.util.Map;

@Service
public class ApnsPushService {
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
        if (!enabled || teamId.isEmpty() || keyId.isEmpty() || privateKeyPath.isEmpty()) {
            return;
        }
        client = new ApnsClientBuilder()
            .setApnsServer(useSandbox ? ApnsClientBuilder.DEVELOPMENT_APNS_HOST : ApnsClientBuilder.PRODUCTION_APNS_HOST)
            .setSigningKey(ApnsSigningKey.loadFromPkcs8File(new File(privateKeyPath), teamId, keyId))
            .build();
    }

    public boolean isEnabled() {
        return enabled && client != null;
    }

    public boolean sendReminder(DeviceToken deviceToken, String title, String body, String sound, Map<String, Object> payloadData) {
        if (!isEnabled() || !"ios".equals(deviceToken.getPlatform())) {
            return false;
        }
        try {
            ApnsPayloadBuilder payloadBuilder = new ApnsPayloadBuilder();
            payloadBuilder.setAlertTitle(title);
            payloadBuilder.setAlertBody(body);
            payloadBuilder.setSoundFileName(sound);
            for (Map.Entry<String, Object> entry : payloadData.entrySet()) {
                payloadBuilder.addCustomProperty(entry.getKey(), entry.getValue());
            }
            String payload = payloadBuilder.buildWithDefaultMaximumLength();
            String token = com.eatthepath.pushy.apns.util.TokenUtil.sanitizeTokenString(deviceToken.getToken());
            SimpleApnsPushNotification notification = new SimpleApnsPushNotification(token, bundleId, payload);
            PushNotificationResponse<SimpleApnsPushNotification> response = client.sendNotification(notification).get();
            return response.isAccepted();
        } catch (Exception e) {
            return false;
        }
    }
}
