# 呆呆面板 Flutter

呆呆面板 Flutter 是面向 Android 和 iOS 的移动端客户端，用于连接呆呆面板服务并在手机端管理任务、脚本、日志、环境变量、依赖、安全设置和开放 API。

## 最新版本

- App 版本：`v0.0.59`
- 仓库范围：仅保留 Flutter App、Android/iOS 平台工程和双端构建工作流
- 架构方向：`core/`、`features/`、`shared/` 分层迁移，保留 Miuix 风格与 Provider 状态管理

## 下载安装

| 平台 | 安装包 |
|------|--------|
| Android | [daidai-flutter-v0.0.59-android.apk](https://github.com/tall-1997/daidai-flutter/releases/download/v0.0.59/daidai-flutter-v0.0.59-android.apk) |
| iOS | [daidai-flutter-v0.0.59-ios.ipa](https://github.com/tall-1997/daidai-flutter/releases/download/v0.0.59/daidai-flutter-v0.0.59-ios.ipa) |

所有版本见 [GitHub Releases](https://github.com/tall-1997/daidai-flutter/releases)。

## 功能范围

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

## 当前限制

- iOS 安装包为 GitHub Actions 构建的无签名 IPA，需要使用 AltStore、Sideloadly 或企业/开发者签名方式安装。
- Android 安装包为 Release APK，首次安装可能需要允许浏览器或文件管理器安装未知来源应用。
- 本仓库仅包含 Flutter App，服务端、Web 管理端、Docker、Magisk、桌面打印工具和历史构建产物已从新历史中移除。
- 当前环境未内置 Flutter/Dart SDK，本地会话无法执行 `flutter test` 和 `flutter analyze`；云端 GitHub Actions 负责双端构建验证。
- App 依赖可访问的呆呆面板服务，默认地址为 `http://127.0.0.1:5700`，移动设备使用时需填写实际局域网或公网地址。
- 反代、NAS、Nginx Proxy Manager 等部署场景遇到 `403` 登录错误时，建议升级面板到 `v2.3.0` 及以上并检查 CORS/反代配置。

## 连接配置

启动 App 后在登录页填写面板地址。

- 默认地址：`http://127.0.0.1:5700`
- 常规接口：`/api`
- 流式接口：`/api/v1`

## 技术栈

- Flutter 3.x
- Dart 3.x
- Provider 状态管理
- `http` 与 `dio` 网络请求
- SharedPreferences 与 SecureStorage 本地存储
- Miuix 风格主题与组件
- GitHub Actions 自动构建 Android APK 和 iOS IPA

## 项目结构

```text
.
├── android/                    # Android 平台工程
├── ios/                        # iOS 平台工程
├── lib/
│   ├── main.dart               # 启动入口
│   ├── app.dart                # 应用装配和 Provider 注入
│   ├── core/                   # 主题、网络、存储、认证和路由基础层
│   ├── features/               # 登录、仪表盘、任务、日志等功能模块
│   ├── shared/                 # 通用模型、工具和组件
│   ├── screens/                # 页面
│   ├── services/               # API、认证、日志、通知和 Root 服务
│   ├── theme/                  # Miuix 主题
│   └── widgets/                # 通用组件
├── test/                       # Flutter 测试
├── pubspec.yaml                # Flutter 依赖和版本
└── .github/workflows/build.yml # Android/iOS 自动构建
```

## 本地构建

```bash
# 安装依赖
flutter pub get

# 运行静态检查
flutter analyze

# 运行测试
flutter test

# 构建 Android APK
flutter build apk --release

# 构建 iOS App，无签名
flutter build ios --release --no-codesign
```

## 云端构建

推送到 `main` 分支会触发 `Build Android & iOS` 工作流。

构建产物：

- `daidai-flutter-v0.0.59-android.apk`
- `daidai-flutter-v0.0.59-ios.ipa`

构建完成后，产物会作为 GitHub Actions artifacts 上传，并同步到 `v0.0.59` Release。

## v0.0.59 更新日志

### 架构迁移

- 新增 `core/`、`features/`、`shared/` 分层目录，为后续按模块迁移参考 App 架构提供稳定边界。
- 新增 Provider 版 `core/auth` 适配层、`core/router` 路由配置、Dio 网络基础层、安全存储和 UserAgent 初始化。
- 新增 feature 页面包装层，将登录、仪表盘、任务、日志、环境变量、依赖、脚本、通知、订阅、系统、安全和 OpenAPI 模块映射到现有已验证页面。
- 抽出 `app.dart`，让 `main.dart` 聚焦启动初始化，应用装配集中在 `DaidaiApp`。

## v0.0.58 更新日志

### 仓库治理

- 重置远端 `main` 为全新 root commit，清理历史中混入的服务端、Web、Docker、桌面工具、Magisk、历史 APK、无关脚本和压缩包。
- 精简仓库范围，仅保留 Flutter App、Android/iOS 平台工程、基础文档和双端构建工作流。
- 保留 `Build Android & iOS` 工作流，推送 `main` 后自动构建 APK 和 IPA，并创建或更新最新 Release。

### API 兼容

- 新增 `api_utils.dart`，集中处理面板地址规范化、API 路径拼接和登录错误文案。
- 常规面板接口统一走 `/api`，健康检查和流式日志等接口保留 `/api/v1`。
- 修正健康检查路径为 `/health`，日志清理路径为 `/logs/clean`，登录日志路径为 `/security/login-logs`。
- 登录遇到 `403` 时显示反代/NAS/Nginx Proxy Manager 兼容提示，指导用户升级面板和检查配置。

### App 体验

- 保留根目录 Flutter App 的 Miuix 风格、Provider 状态管理和侧边栏导航。
- 设置页新增“系统管理”聚合入口，统一跳转开放 API 和安全设置。
- 替换失效的默认 Counter 测试，新增 URL 规范化、登录错误提示和 API 路径拼接测试。

## 历史版本

- `v0.0.57`：修复脚本详情夜间模式文字颜色问题。
- `v0.0.56`：修复版本号显示、任务日志实时刷新、脚本编辑器夜间模式文字颜色。
- `v0.0.55`：优化深色模式边框和背景对比度。
- `v0.0.54`：仪表盘资源趋势添加磁盘数据显示。
- `v0.0.53`：恢复设置页面主题切换功能。

## 相关项目

- 呆呆面板后端：[linzixuanzz/daidai-panel](https://github.com/linzixuanzz/daidai-panel)
- Flutter 客户端：[tall-1997/daidai-flutter](https://github.com/tall-1997/daidai-flutter)

## 许可证

MIT License
