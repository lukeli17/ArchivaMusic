<div align="center" style="display: flex; justify-content: center; align-items: center;">
  <img class="lo" src='https://raw.githubusercontent.com/lukeli17/ArchivaMusic/master/.github/images/logo-fill.light.svg' style="height: 4rem">
</div>
<div align="center" style="font-size: 2rem"><b>Archiva Music</b></div>

<div align="center">
  <img src="https://img.shields.io/github/v/release/lukeli17/ArchivaMusic" alt="Latest GitHub Release" />
</div>
 
**<div align="center" style="padding-top: 1.25rem">[本地开发](DEVELOPMENT.md) • [提交问题](https://github.com/lukeli17/ArchivaMusic/issues) • [贡献指南](.github/contributing.md)</div>**

##

[![Archiva Music 艺术家页面截图](https://raw.githubusercontent.com/lukeli17/ArchivaMusic/master/.github/images/artist.webp)](https://raw.githubusercontent.com/lukeli17/ArchivaMusic/master/.github/images/artist.webp)

##

Archiva Music 是面向个人音乐收藏的自托管音乐库与流媒体服务器，支持从本地文件读取和整理音乐元数据，并将不同音质、来源和版本的音频统一收纳、浏览和播放。

## 功能

- **每日混音**：根据你的聆听记录生成个性化推荐
- **元数据整理**：建立整洁、统一的音乐资料库
- **专辑版本管理**：识别并关联豪华版、重制版等专辑版本
- **相关艺人与专辑**：发现相关音乐内容
- **文件夹视图**：按文件夹浏览音乐库
- **网页播放器**：通过浏览器访问音乐库
- **静音检测**：结合淡入淡出与静音检测，实现更连贯的播放体验
- **收藏集**：按个人偏好整理艺人和专辑
- **播放统计**：查看音乐播放数据
- **Last.fm 同步**：同步聆听记录
- **多用户支持**：支持多个用户使用同一服务
- **跨平台运行**：支持 Linux、Windows，以及后续扩展的平台和架构

## 安装与开发

Archiva Music 目前仍处于开发阶段。源码开发、调试和统一启动方式请参阅[开发说明](DEVELOPMENT.md)。

目前暂未发布 Archiva Music 的正式二进制版本或公开 Docker 镜像。

### Docker 发布计划

正式 Docker 镜像发布后，计划统一使用 `1717` 端口，由后端同时提供 API 和构建后的网页界面，因此部署时只需要暴露一个端口：

```yaml
ports:
  - "1717:1717"
```

源码开发时使用后端 `1718`、前端 `1719` 两个端口；发布到 Docker 后只使用 `1717`。当前 Docker 配置仍在整理中，暂时不要把其它项目的镜像当作 Archiva Music 镜像使用。

## 命令行选项

启动程序时可以通过命令行选项调整运行参数或执行维护任务。使用 `-h` 查看全部选项。

> [!TIP]
> 本地开发、启动和调试方法请参阅[开发说明](DEVELOPMENT.md)。

## 贡献与开发

Archiva Music 欢迎功能建议、问题反馈和代码贡献。提交代码前请阅读[贡献指南](.github/contributing.md)。

项目当前由 [@lukeli17](https://github.com/lukeli17) 负责维护。

## 项目来源与许可证

Archiva Music 是基于开源音乐库项目进行二次开发和持续改造的项目。项目继续采用 [AGPLv3 许可证](LICENSE)，完整条款请查看仓库根目录的 `LICENSE` 文件。
