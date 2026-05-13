# Flutter 应用图标生成指南

## 方法一：Android Studio 图标生成器（推荐）

### 步骤 1：打开图标生成器
1. 在 Android Studio 左侧项目面板，展开 `android/app/src/main/`
2. 右键点击 `res` 文件夹
3. 选择 `New` → `Image Asset`

### 步骤 2：配置图标
**Icon Type:**
- 选择 `Launcher Icons (Adaptive and Legacy)`

**Foreground Layer（前景层）:**
- Asset Type: 选择 `Clip Art`
- 点击图标按钮（默认显示 Android 机器人）
- 在搜索框输入 "notifications" 或 "alarm"
- 选择铃铛图标 🔔
- 调整 Resize 滑块到 **60-70%**（让图标大小合适）

**Background Layer（背景层）:**
- Asset Type: 选择 `Color`
- Color: 输入 `#6366F1`（紫色，与应用主题一致）

### 步骤 3：预览并生成
1. 查看右侧预览效果（圆形、方形、圆角方形）
2. 确认效果满意后，点击 `Next`
3. 点击 `Finish`

### 步骤 4：应用新图标
1. 卸载设备上的旧版本应用（或清除数据）
2. 重新运行应用
3. 新图标即可生效

---

## 方法二：使用 flutter_launcher_icons（需要图片）

### 前提条件
准备一个 1024x1024 的 PNG 图标图片

### 步骤
1. 将图标图片放到 `assets/icon.png`
2. 在 Terminal 运行：
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

---

## 方法三：在线工具生成

### 推荐工具
- https://icon.kitchen/ - 专业的应用图标生成器
- https://www.appicon.co/ - 支持多平台图标生成

### 使用步骤
1. 访问 icon.kitchen
2. 选择图标样式（铃铛、闹钟等）
3. 设置背景色为 `#6366F1`
4. 下载生成的图标包
5. 解压到 `android/app/src/main/res/` 覆盖对应文件夹

---

## 注意事项
- Android 图标会自动生成多种尺寸（mipmap-hdpi, mipmap-xhdpi 等）
- iOS 图标需要在 Mac 上使用 Xcode 生成
- 建议使用简洁的图标设计，避免过于复杂的细节
- 图标颜色应与应用主题保持一致

## 当前配置
- 主题色：`#6366F1`（紫色）
- 推荐图标：铃铛 🔔、闹钟 ⏰、通知 📢
