#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const config = parseArgs(args);

async function main() {
    try {
        const { pbUrl, adminEmail, adminPassword, file: filePath, batch } = config;

        if (!pbUrl || !adminEmail || !adminPassword || !filePath) {
            printUsage();
            process.exit(1);
        }

        console.log('正在登录 PocketBase...');
        const token = await authenticate(pbUrl, adminEmail, adminPassword);
        console.log('登录成功');

        console.log(`正在读取文件: ${filePath}`);
        const data = JSON.parse(fs.readFileSync(filePath, 'utf-8'));

        const collections = Array.isArray(data) ? [{ name: 'default', records: data }] : data;
        const batchSize = batch || 10;
        let totalSuccess = 0;
        let totalFailed = 0;

        for (const collection of collections) {
            const collectionName = collection.name || collection.collectionId || 'unknown';
            console.log(`\n处理集合: ${collectionName}`);
            console.log(`记录数量: ${collection.records.length}`);

            const records = Array.isArray(collection.records) ? collection.records : [collection.records];

            for (let i = 0; i < records.length; i += batchSize) {
                const batch = records.slice(i, i + batchSize);
                const results = await upsertBatch(pbUrl, collection, batch, token);
                totalSuccess += results.success;
                totalFailed += results.failed;

                console.log(`进度: ${Math.min(i + batchSize, records.length)}/${records.length}`);
            }
        }

        console.log(`\n=== 迁移完成 ===`);
        console.log(`成功: ${totalSuccess}`);
        console.log(`失败: ${totalFailed}`);

        if (totalFailed > 0) {
            process.exit(1);
        }
    } catch (err) {
        console.error('错误:', err.message);
        process.exit(1);
    }
}

async function authenticate(pbUrl, email, password) {
    const response = await fetch(`${pbUrl.replace(/\/$/,'')}/api/admins/auth-with-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ identity: email, password })
    });

    if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(`认证失败: ${error.message || response.statusText}`);
    }

    const data = await response.json();
    return data.token;
}

async function upsertBatch(pbUrl, collection, records, token) {
    let success = 0;
    let failed = 0;
    const baseUrl = pbUrl.replace(/\/$/,'');
    const collectionId = collection.collectionId || collection.name;

    for (const record of records) {
        try {
            const method = record.id ? 'PUT' : 'POST';
            const path = record.id
                ? `${baseUrl}/api/collections/${collectionId}/records/${record.id}`
                : `${baseUrl}/api/collections/${collectionId}/records`;

            const res = await fetch(path, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': token
                },
                body: JSON.stringify(record)
            });

            if (!res.ok) {
                const error = await res.json().catch(() => ({}));
                console.error(`失败记录 ${record.id || 'new'}:`, error.message);
                failed++;
            } else {
                success++;
            }
        } catch (err) {
            console.error(`记录 ${record.id || 'new'} 请求错误:`, err.message);
            failed++;
        }
    }

    return { success, failed };
}

function parseArgs(args) {
    const config = {
        file: null,
        batch: 10
    };

    for (let i = 0; i < args.length; i++) {
        const arg = args[i];
        const value = args[i + 1];

        switch (arg) {
            case '--url':
            case '-u':
                config.pbUrl = value;
                i++;
                break;
            case '--email':
            case '-e':
                config.adminEmail = value;
                i++;
                break;
            case '--password':
            case '-p':
                config.adminPassword = value;
                i++;
                break;
            case '--file':
            case '-f':
                config.file = value;
                i++;
                break;
            case '--batch':
            case '-b':
                config.batch = parseInt(value) || 10;
                i++;
                break;
            case '--help':
            case '-h':
                printUsage();
                process.exit(0);
        }
    }

    return config;
}

function printUsage() {
    console.log(`
PocketBase 数据导入工具

用法:
  node pb_upsert.js [options]

选项:
  -u, --url <url>           PocketBase 地址 (例如: http://localhost:8090)
  -e, --email <email>       管理员邮箱
  -p, --password <password> 管理员密码
  -f, --file <file>         要导入的 JSON 文件路径
  -b, --batch <num>         批量处理数量 (默认: 10)
  -h, --help                显示帮助

JSON 文件格式示例:
  [
    {
      "collectionId": "guas",
      "records": [
        { "name": "卦例1", "userId": "user123", "guaInfo": {} }
      ]
    }
  ]

或者:
  {
    "guas": [ ... ],
    "rules": [ ... ],
    "dogma": [ ... ]
  }
`);
}

main();
