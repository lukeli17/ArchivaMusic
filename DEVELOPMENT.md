# Archiva Music 开发说明

Archiva Music 是面向个人音乐收藏的自托管音乐库与流媒体服务器。后端暂时保留 `swingmusic` Python 包名，以减少早期改名对内部导入和数据兼容性的影响；用户界面和品牌名称统一使用 Archiva Music。

## 后端

在项目根目录运行：

```sh
uv sync --python 3.12
uv run python -m swingmusic --host 127.0.0.1 --port 1718 --debug \
  --config .dev-data --client client/dist
```

## 前端热重载

另开一个终端：

```sh
cd client
yarn install --frozen-lockfile
yarn dev --host 127.0.0.1
```

然后打开 <http://127.0.0.1:1719/>。开发前端会自动把 API 请求发送到后端的 1718 端口。

## 端口约定

- 源码开发：后端 `1718`，前端 Vite `1719`
- Docker 发布：只暴露一个端口 `1717`，由后端同时提供 API 和构建后的前端

## 构建前端

```sh
cd client
yarn build
```

## 一键管理开发环境

项目提供了统一管理脚本：

```sh
./scripts/archiva-dev.sh status
./scripts/archiva-dev.sh start
./scripts/archiva-dev.sh stop
./scripts/archiva-dev.sh restart
./scripts/archiva-dev.sh logs
```

不带参数运行脚本会进入交互式菜单，可以查看状态并控制前后端启动或停止。脚本使用 `.dev-data` 保存开发配置，使用 `.dev-runtime` 保存 PID 文件和日志，不会触碰正式配置或 NAS 音乐文件。

## 说明

- 开发阶段不需要 Docker；源码修改和调试更快。
- `.dev-data` 只用于本地测试，不要连接 NAS 的正式配置目录。
- Docker 镜像适合后续部署到 NAS，届时再为 Archiva Music 编写独立的镜像和 Compose 配置。
