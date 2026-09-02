# Archiva Music 开发说明

本项目由 Swing Music fork 而来，后端保留 `swingmusic` Python 包名，以减少早期改名对内部导入和数据兼容性的影响。用户界面和品牌名称已经改为 Archiva Music。

## 后端

在项目根目录运行：

```sh
uv sync --python 3.12
uv run python -m swingmusic --host 127.0.0.1 --port 1980 --debug \
  --config .dev-data --client client/dist
```

## 前端热重载

另开一个终端：

```sh
cd client
yarn install --frozen-lockfile
yarn dev --host 127.0.0.1
```

然后打开 <http://127.0.0.1:5173/>。开发前端会自动把 API 请求发送到后端的 1980 端口。

## 构建前端

```sh
cd client
yarn build
```

## 说明

- 开发阶段不需要 Docker；源码修改和调试更快。
- `.dev-data` 只用于本地测试，不要连接 NAS 的正式配置目录。
- Docker 镜像适合后续部署到 NAS，届时再为 Archiva Music 编写独立的镜像和 Compose 配置。
