ALTER TABLE reminders
  ADD COLUMN ios_initial_pushed_at BIGINT NULL,
  ADD COLUMN ios_repeat_active BIT NOT NULL DEFAULT 0,
  ADD COLUMN ios_repeat_last_sent_at BIGINT NULL,
  ADD COLUMN ios_repeat_sent_count INT NOT NULL DEFAULT 0,
  ADD COLUMN ios_repeat_stopped_at BIGINT NULL;

CREATE TABLE device_tokens (
  id VARCHAR(36) NOT NULL PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  platform VARCHAR(16) NOT NULL,
  token VARCHAR(255) NOT NULL,
  environment VARCHAR(32) NULL,
  enabled BIT NOT NULL DEFAULT 1,
  created_at BIGINT NOT NULL,
  last_seen_at BIGINT NOT NULL,
  CONSTRAINT uk_device_tokens_token UNIQUE (token)
);

CREATE INDEX idx_device_tokens_user_platform_enabled
  ON device_tokens (user_id, platform, enabled);
