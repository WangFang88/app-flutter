-- 清空所有数据
-- 注意：这会删除所有用户、提醒、支持者、确认记录和设备令牌

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE acknowledgements;
TRUNCATE TABLE supporters;
TRUNCATE TABLE reminders;
TRUNCATE TABLE device_tokens;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;
