# Java Spring Boot 后端部署指南

## 环境要求

- JDK 17 或更高版本
- Maven 3.6+
- MySQL 5.7+ 或 8.0

## 本地部署步骤

### 1. 安装 JDK

下载并安装 JDK 17：https://adoptium.net/

验证安装：
```bash
java -version
```

### 2. 创建数据库

```bash
mysql -u root -p
```

执行：
```sql
CREATE DATABASE reminder_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'reminder'@'localhost' IDENTIFIED BY 'reminder';
GRANT ALL PRIVILEGES ON reminder_app.* TO 'reminder'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

导入表结构：
```bash
mysql -u reminder -preminder reminder_app < ../server/schema.sql
```

### 3. 配置环境变量（可选）

复制 `.env.example` 为 `.env` 并修改配置，或者直接使用默认配置。

Spring Boot 会自动读取系统环境变量。

### 4. 编译并运行

```bash
cd server-java
mvn clean package
java -jar target/reminder-api-1.0.0.jar
```

或者直接用 Maven 运行：
```bash
mvn spring-boot:run
```

看到 `Started ReminderApplication` 就说明启动成功。

### 5. 测试 API

```bash
curl http://localhost:3000/auth/anonymous -X POST -H "Content-Type: application/json" -d "{}"
```

## 生产部署

### 使用 systemd 服务

创建 `/etc/systemd/system/reminder-api.service`：

```ini
[Unit]
Description=Reminder API
After=mysql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/reminder-api
ExecStart=/usr/bin/java -jar /opt/reminder-api/reminder-api-1.0.0.jar
Restart=on-failure

Environment="MYSQL_HOST=127.0.0.1"
Environment="MYSQL_USER=reminder"
Environment="MYSQL_PASSWORD=your_password"
Environment="JWT_SECRET=your-long-random-secret"

[Install]
WantedBy=multi-user.target
```

启动服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable reminder-api
sudo systemctl start reminder-api
```

## API 兼容性

所有 API 接口与 Node.js 版本完全兼容，Android 客户端无需修改。

## 技术栈

- Spring Boot 3.2.4
- Spring Data JPA
- Spring Security + JWT
- MySQL Connector
- Lombok
