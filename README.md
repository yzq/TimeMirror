# 时镜（TimeMirror）

一款受柳比歇夫“时间统计法”启发的原生 iPhone 应用。它关注真实记录、周期复盘和计划校准，而不是连续打卡或延长工作时间。

## 当前版本

首个 MVP 包含：

- 三步首次设置和长期方向初始化；
- 开始、暂停、恢复和结束活动计时；
- 进行中活动的本地恢复；
- SwiftData 本地持久化；
- 手工补记、按日查看和删除记录；
- 周度分类统计、估时准确率与常见开始时段；
- 长期方向编辑和基于历史容量的下周建议；
- 深色模式、动态字体和基础 VoiceOver 标签。

## 运行要求

- macOS；
- Xcode 15 或更高版本；
- iOS 17 或更高版本。

用 Xcode 打开 `TimeMirror.xcodeproj`，选择一个 iPhone 模拟器后运行。首次启动会进入三步设置流程。

## 工程结构

```text
TimeMirror/
├── TimeMirror.xcodeproj       Xcode 工程
├── TimeMirror/                SwiftUI 界面、SwiftData 与计时状态
├── Sources/TimeMirrorCore/    不依赖界面的领域模型和统计逻辑
├── Tests/TimeMirrorCoreTests/ 领域逻辑测试
├── Package.swift              核心逻辑的 Swift Package 测试入口
└── project.yml                可选的 XcodeGen 再生成配置
```

## 数据与隐私

所有记录默认只保存在设备本地。当前版本不包含账户、广告、分析 SDK、屏幕使用情况读取或远程服务。

## 远程 macOS 编译与测试

仓库根目录的 `.github/workflows/ios-ci.yml` 提供 GitHub Actions 工作流。代码推送到 GitHub 后，它会在 `macos-15` runner 上：

1. 运行 `TimeMirrorCore` 的跨平台单元测试；
2. 自动选择可用的 iPhone Simulator；
3. 使用共享 `TimeMirror` Scheme 执行 `build-for-testing`；
4. 在 iOS Simulator 中执行 `TimeMirrorTests`；
5. 无论成功或失败，都保存编译日志和 `.xcresult` 诊断包 14 天。

工作流仅在 `TimeMirror/**` 或自身配置发生变化时触发，也可以在 GitHub Actions 页面手动运行。模拟器构建关闭代码签名，不需要配置开发者证书。

## 后续里程碑

1. 补充 App Icon、启动画面和完整视觉规范；
2. 增加预算编辑、CSV/JSON 导出及 iCloud 同步；
3. 添加 WidgetKit、ActivityKit 和 App Intents；
4. 在真实设备上完成通知、后台恢复、无障碍及性能测试。
