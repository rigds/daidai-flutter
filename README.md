# 呆呆面板 Flutter

呆呆面板 Flutter 是面向 Android 和 iOS 的移动端客户端，用于连接呆呆面板服务并在手机端管理任务、脚本、日志、环境变量、依赖、安全设置和开放 API。

## 版本

- App 版本：`v0.0.60`
- 适配面板：`v2.3.0`

## 下载安装

| 平台 | 安装包 |
|------|--------|
| Android | [daidai-flutter-v0.0.60-android.apk](https://github.com/tall-1997/daidai-flutter/releases/download/v0.0.60/daidai-flutter-v0.0.60-android.apk) |
| iOS | [daidai-flutter-v0.0.60-ios.ipa](https://github.com/tall-1997/daidai-flutter/releases/download/v0.0.60/daidai-flutter-v0.0.60-ios.ipa) |

所有版本见 [GitHub Releases](https://github.com/tall-1997/daidai-flutter/releases)。

## 功能

- 仪表盘：查看系统概览、资源状态和最近执行记录
- 定时任务：任务列表、创建编辑、启停、执行、复制、置顶和批量操作
- 脚本管理：脚本浏览、编辑、上传、批量操作和运行辅助
- 执行日志：日志列表、详情、导出、清理和实时/流式日志入口
- 环境变量：变量增删改查、启停、排序和批量操作
- 依赖管理：Python/Node.js 依赖查看、安装、重装、取消和删除
- 订阅管理：订阅列表、同步、启停和日志入口
- 通知渠道：渠道配置、启停、测试和发送
- 安全设置：2FA、登录日志、会话管理、IP 白名单和审计信息
- 开放 API：客户端凭据管理和开放接口访问配置
- 应用锁：密码、图案锁和生物识别
- 服务器配置：多面板管理

## 技术栈

- Flutter 3.x / Dart 3.x
- Riverpod 状态管理
- `dio` 网络请求
- SharedPreferences 与 SecureStorage 本地存储
- Miuix 风格主题与组件
- GitHub Actions 自动构建 Android APK 和 iOS IPA

## 连接配置

启动 App 后在登录页填写面板地址。

- 默认地址：`http://127.0.0.1:5700`
- 常规接口：`/api`
- 流式接口：`/api/v1`

## 本地构建

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release --no-codesign
```

## 云端构建

推送到 `main` 分支会触发 `Build Android & iOS` 工作流，自动构建 APK 和 IPA 并发布到 Release。

## 引用

本项目基于以下开源项目：

- [linzixuanzz/Dumb-Panel-APP](https://github.com/linzixuanzz/Dumb-Panel-APP) - 呆呆面板 Flutter 客户端原始项目
  - 提供了核心功能模块和 UI 设计
  - 使用 Riverpod 状态管理
  - 使用 Apache 2.0 许可证

- [linzixuanzz/daidai-panel](https://github.com/linzixuanzz/daidai-panel) - 呆呆面板后端服务
  - 提供了 API 接口和数据模型
  - 使用 MIT 许可证

## 许可证

MIT License
