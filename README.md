# PocketBase Railway Template

口袋 base Railway 模板仓库，用于在 Railway 上快速部署 PocketBase 实例。

## 快速开始

### 1. 部署到 Railway

1. 登录 [Railway](https://railway.app)
2. 点击 "New Project" -> "Deploy from GitHub repo"
3. 选择本仓库
4. Railway 会自动创建服务并配置 PostgreSQL 数据库

### 2. 配置环境变量

在 Railway 控制面板中设置以下环境变量：

| 变量名 | 说明 | 必填 |
|--------|------|------|
| `PB_ENCRYPTION_KEY` | PocketBase 加密密钥，用于保护数据 | 是 |
| `DATABASE_URL` | PostgreSQL 连接字符串（自动从 Addon 获取） | 否 |

> 首次部署后，建议设置一个管理员账户。

### 3. 导入数据集合

部署完成后，可以通过以下方式导入集合结构：

```bash
# 使用 pb_upsert.js 导入 schema
node tools/pb_upsert.js --url <pocketbase-url> --admin-email <email> --admin-password <password> --file pb_schema.json
```

## 集合结构

本模板包含以下三个集合：

### guas（用户卦例存档）
- `name`: 卦例名称
- `userId`: 用户 ID
- `guaInfo`: 卦象信息（JSON）
- `paInfo`: 排盘信息（JSON）
- `notes`: 备注

### rules（神煞规则）
- `name`: 规则名称
- `category`: 规则分类
- `config`: 配置信息（JSON）
- `description`: 规则描述
- `enabled`: 是否启用

### dogma（流派规则）
- `name`: 流派名称
- `author`: 作者
- `version`: 版本
- `rules`: 流派规则（JSON）
- `description`: 流派描述
- `enabled`: 是否启用

## 目录结构

```
.
├── railway.json          # Railway 服务配置
├── pb_schema.json        # PocketBase 集合结构定义
├── Dockerfile            # 容器构建配置
├── .railwayignore        # Railway 排除文件
├── tools/
│   ├── migrate-old-data.html   # 数据迁移工具
│   ├── pb_upsert.js            # JSON 导入工具
│   └── pb_publish_collection.js # 集合发布工具
└── scripts/
    └── add-railway-service.sh   # 自动化部署脚本
```

## 数据迁移

使用 `tools/migrate-old-data.html` 将 Causaloop LocalStorage 数据迁移到 PocketBase。

## 自动部署

使用 `scripts/add-railway-service.sh` 一键部署并导入数据。

## 许可

MIT
