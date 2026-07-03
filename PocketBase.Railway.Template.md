# Railway PocketBase 模板与 Causaloop 数据迁移方案

## 概述

本方案用于在 Railway 上部署 PocketBase 实例，并配套工具将 Causaloop 原有的 LocalStorage 数据迁移到 PocketBase 服务端。

## 一、Railway 模板仓库结构

### 1.1 `railway.json`

定义 PocketBase 服务的启动命令、环境变量、存储卷挂载。

### 1.2 `pb_schema.json`

定义 PocketBase 集合结构：
- `guas`：用户卦例存档
- `rules`：神煞规则
- `dogma`：流派规则

### 1.3 `.railwayignore`

排除 `pb_upsert.js`、`pb_publish_collection.js`、`data/`、`node_modules/`

### 1.4 `Dockerfile`

多阶段构建，镜像体积 47MB+（官方推荐）

### 1.5 `README.md`

说明模板用法和后续部署步骤。

## 二、Causaloop 配套脚本

### 2.1 `tools/migrate-old-data.html`

读取 `data/` 目录，将规则、卦例、主题词条转为 PocketBase 字段格式。

### 2.2 `tools/pb_upsert.js`

Python 脚本，支持 JSON 格式 upsert 导入。

### 2.3 `tools/pb_publish_collection.js`

可选，仅用于自定义 JS 集合（如有需要再实现）。

## 三、Causaloop 集成脚本

### 3.1 `scripts/add-railway-service.sh`

接受参数：repo 地址、当前 PocketBase 实例名、导出的 JSON。步骤：
1. 部署模板（实例名默认 `<pb>pb`）
2. 获取 RPC 服务地址
3. Schema Upsert 导入 `pb_schema.json`
4. Records UpsertBatch 导入导出的 JSON
5. 输出成功日志

### 3.2 `causaloop.json` 字段扩展

新增字段 `railwayTemplateRepository`，记录模板 repo 地址。

## 四、预期效果

- PocketBase 独立实例，可共享与原有 `pb` 实例相同的密钥
- 用户数据自动迁移到云端，LocalStorage 降级为只读
- 分享链接溯源 `UID + 卦象 + 时间 + 盐`
- 新增功能：规则可抽换、多渠道发布
