VibeCoding，而且穷，用的gemini3.7f，下面是普信ai胡诌的，不要信。

# Kemono Mobile Viewer (Kemono 手机浏览快捷客户端)

一个基于 Flutter 构建的现代化、舒适、非破坏性的 Kemono 手机浏览客户端与快捷方式。

---

## 🌟 核心特性

### 1. 🛡️ 非破坏性与安全访问 (Non-Destructive & Safe)
- **遵循官方只读 API**：完全采用 Kemono 官方公开的 REST API（`/api/v1/posts`、`/api/v1/creators` 等）进行轻量化按需分页加载。
- **杜绝破坏性抓取**：不进行高并发爬虫、全站批量下载或暴力爬取，最大限度减轻服务器负担与避免触发 IP 封锁。
- **本地缓存加速**：创作者索引一次拉取本地缓存，大幅减少不必要的重复请求与流量消耗。

### 2. 🌐 灵活的自定义域名与镜像支持
- **默认域名**：`https://kemono.cr`
- **一键切换预设镜像**：内置 `kemono.cr`、`kemono.su`、`coomer.su`、`kemono.party` 等。
- **支持自定义反代/镜像**：可在“设置”页面随时输入任意自建反代、加速镜像或中转代理。
- **连通性测速工具**：内置一键测试功能，即时检测当前域名的 API 可达性及状态（200 OK / Cloudflare 防护识别）。

### 3. 🎨 舒适顺滑的移动端交互 UI
- **Material 3 现代美学**：精心调配的深色模式 (Dark)、纯黑省电模式 (AMOLED Black)、浅色模式 (Light)。
- **各平台品牌标识**：针对 Fanbox、Patreon、Fantia、Boosty、Gumroad、Discord、爱发电、CandFans 等平台提供专属微标与色彩标识。
- **舒适卡片流**：图文卡片自适应，支持智能缩略图模式（节省流量并杜绝卡顿）。

### 4. 🔍 便捷搜索与创作者检索
- **双模搜索**：支持一键切换“搜帖子关键词”与“搜创作者名称/ID”。
- **0 延迟创作者索引**：创作者库支持本地极速实时过滤与拼音/英文检索，支持按热度/关注数、字母名称、最近更新排序。
- **搜索历史管理**：自动记录常用搜索标签，支持一键重搜与历史清空。

### 5. 🖼️ 高清看图与画廊体验
- **手势缩放与全屏画廊**：双指捏合缩放 (Pinch-to-zoom)、拖拽平移、左右平滑切图。
- **多媒体与附件下载**：支持一键复制原图直链、在浏览器中下载 ZIP / 视频等大附件。

### 6. ⭐ 本地离线收藏与足迹
- **无需账号登录**：作者关注与帖子收藏 100% 保存在手机本地，隐私安全。
- **最近浏览足迹**：自动记录近期查看作品，方便随时找回。

### 7. 🌐 内置网页与 Cloudflare 验证回退
- 遇 Cloudflare 人机验证挑战或需要查看网页原生效果时，可一键调起内置 WebView 完成验证并无缝切回原生舒适体验。

---

## 📁 项目目录结构

```
D:\Projects\kemono_viewer\
├── lib/
│   ├── main.dart                  # 应用启动入口
│   ├── models/                    # 数据模型 (Creator, PostItem, AppSettings)
│   ├── services/                  # 网络请求 (ApiService) 与 本地存储 (StorageService)
│   ├── providers/                 # 全局状态管理 (AppProvider, BookmarkProvider)
│   ├── screens/                   # 界面 (Feed, Creators, Search, Bookmarks, Settings, PostDetail, ImageViewer, WebView)
│   ├── widgets/                   # 复用组件 (PostCard, CreatorCard, ServiceBadge, EmptyState, LoadingIndicator)
│   └── theme/                     # 主题配色与样式 (AppTheme, AppColors)
├── temp/                          # 临时文件与缓存目录 (用户指定独立目录)
├── pubspec.yaml                   # 依赖配置
├── android/                       # Android 工程与权限配置
└── web/                           # Web / PWA 支持文件
```

---

## 🚀 如何运行与打包

### 前置条件（当你在电脑上安装 Flutter SDK 后）：
1. **获取依赖**：
   ```bash
   cd D:\Projects\kemono_viewer
   flutter pub get
   ```

2. **在手机或模拟器上运行**：
   ```bash
   flutter run
   ```

3. **打包 Android APK**：
   ```bash
   flutter build apk --release
   ```
   生成的 APK 文件位于 `build/app/outputs/flutter-apk/app-release.apk`。
