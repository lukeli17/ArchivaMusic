# Archiva Music 贡献指南

感谢你对 Archiva Music 的兴趣！本项目使用 Python、[Flask](https://flask.palletsprojects.com/en/2.3.x/)、SQLite、[uv](https://docs.astral.sh/uv) 和 [Vue](https://vuejs.org/)。

如果你准备贡献代码，请先阅读以下指南：

- [行为准则](./CODE_OF_CONDUCT.md)
- [Pull Request 指南](#pull-request-指南)

## Pull Request 指南

- 请从相关基础分支（例如 `master`）创建主题分支，并将修改合并回对应分支。

- 如果新增功能：

  - 请说明增加该功能的必要性。建议先创建功能建议 Issue，获得认可后再开始开发。

- 如果修复问题：

  - 请在 PR 中详细描述问题的表现、原因和修复方式。

## 开发环境配置

本项目分为服务端和 Web 客户端两个部分，客户端位于 [ArchivaMusic-client](https://github.com/lukeli17/ArchivaMusic-client)。

参与服务端开发前，需要安装 [uv 包管理器](https://docs.astral.sh/uv)。

Fork 本仓库，克隆代码并安装依赖：

```sh
git clone https://github.com/lukeli17/ArchivaMusic.git

# or with ssh

git clone git@github.com:lukeli17/ArchivaMusic.git

cd ArchivaMusic
uv sync
```

然后在 `7018` 端口启动服务端：

```sh
uv run python -m swingmusic --port 7018
```

之后创建新分支并进行修改：

```sh
git checkout <branch_name>
```

完成测试后提交修改，并创建 Pull Request。

## 参与客户端开发

你需要先安装 [yarn](https://yarnpkg.com)，可参考[yarn 安装指南](https://yarnpkg.com/getting-started/install)。

Fork 仓库，克隆代码并安装依赖：

```sh
git clone https://github.com/lukeli17/ArchivaMusic-client.git

# or with ssh

git clone git@github.com:lukeli17/ArchivaMusic-client.git

cd ArchivaMusic-client
yarn install
```

现在可以启动客户端开发模式：

```sh
yarn dev
```

客户端地址为 <http://localhost:7019>。

> [!TIP]
> 客户端会连接运行在 `7018` 端口的开发服务端，以便与正式发布端口区分。

## 获取帮助

如果需要帮助，请在 [Archiva Music Issues](https://github.com/lukeli17/ArchivaMusic/issues) 中提交问题。

## 行为准则说明

行为准则要求所有参与者尊重他人，并以礼貌、友善的方式交流，不因身份差异区别对待任何人。如果你遇到行为准则中描述的不当行为，请提交 Issue，我们会根据行为准则进行处理。

期待你的参与！
