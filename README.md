# 云剪贴板

跨设备分享文本、图片和文件：创建剪贴板，取得两位短码链接，在另一台设备打开即可读取。可手动清空；创建 24 小时后自动过期。

> 房间码只有 1296 种，可被枚举。这里的短码不是访问密码，不适合传输密码、令牌或其他敏感资料。

## 功能与结构

- 文本可复制；图片、文件可拖入、选择或粘贴上传，单个文件上限 100 MB。
- 后端 `server.py` 仅使用 Python 标准库；前端由 `index.html`、`style.css`、`app.js` 和 `favicon.svg` 组成。
- 数据保存在 `/data/<code>/`（Docker）或项目内 `data/<code>/`（直接运行）；过期清理线程每小时扫描一次。
- 分享链接根据浏览器当前访问地址生成，不需要在源码里写入部署域名。

```text
cloud-copy/
├── server.py
├── index.html
├── style.css
├── app.js
├── favicon.svg
├── Dockerfile
├── compose.yaml
├── nginx-paste.conf     # 原项目的 nginx/systemd 部署示例，非 Docker 必需
└── clipboard.service
```

## Docker Compose 部署

以下是**部署说明**，不会因阅读或克隆仓库自动启动服务。使用完整仓库作为构建目录，不要只用缺少前端静态文件的独立压缩包。

需要 Docker 与 Compose v2。示例将项目放在 `/docker/cloud-copy`；也可以放在其他目录，以下命令须在仓库根目录执行。

```bash
# 创建持久化目录，并授予容器内 UID/GID 10001 写权限
mkdir -p data
sudo chown 10001:10001 data
# 检查配置，再构建并启动
docker compose config
docker compose up -d --build
# 验证
docker compose ps
docker network inspect web_proxy
docker compose logs --tail 80
```

默认不发布宿主机端口，容器通过已有的外部 Docker 网络 `web_proxy` 对 Nginx Proxy Manager（NPM）提供内部端口 `27150`。启动前确保该网络存在，且 NPM 也在此网络中。`expose` 仅标明内部端口，不等于开放公网端口。`./data` 是持久化目录，重建容器不会自动清空；备份时请备份此目录。`.env`、`data/` 和 `certs/` 不纳入 Git。

**通过 HTTPS 对外访问：**在 NPM 中填写转发主机名 `cloud-copy`、转发端口 `27150`；DNS 和证书在实际部署环境中配置，不写进仓库。验证时可从同一 `web_proxy` 网络中的容器访问 `http://cloud-copy:27150/hello`。不要为了方便直接把应用端口暴露到公网。

## 不使用 Docker

可直接运行 `python3 server.py`，默认监听 `127.0.0.1:27150`，数据写入项目下的 `data/`。仓库保留了原项目的 `clipboard.service` 与 `nginx-paste.conf` 作为参考；其中的用户名、路径、示例域名和证书路径必须按实际环境调整，不能直接套用到 Docker 部署。

## 使用方式

1. 打开部署后的页面，输入文本或添加文件，点击「创建剪贴板」。
2. 复制生成的链接，在另一台设备上打开。
3. 用完点击「清空」，或等待自动过期。

## API

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| GET | `/hello` | 健康检查，返回 `{"hello":"world"}` |
| POST | `/api/new` | 分配码，返回 `{"code":"a7"}` |
| GET | `/api/<code>` | 查看文本和文件列表 |
| PUT | `/api/<code>/text` | 写入文本 |
| PUT | `/api/<code>/files/<name>` | 上传文件（≤100 MB） |
| GET | `/api/<code>/files/<name>` | 下载文件 |
| DELETE | `/api/<code>` | 清空并释放码 |
| DELETE | `/api/<code>/files/<name>` | 删除单个文件 |

## 注意

- 删除单个文件、更新文本等操作均基于短码，任何知道或猜到短码的人都可能访问或修改对应内容。
- 自动过期与每小时清理不是精确到秒的定时删除保证。
