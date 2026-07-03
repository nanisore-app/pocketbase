#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const config = parseArgs(args);

async function main() {
    try {
        const { pbUrl, adminEmail, adminPassword, file: filePath } = config;

        if (!pbUrl || !adminEmail || !adminPassword || !filePath) {
            printUsage();
            process.exit(1);
        }

        console.log('正在登录 PocketBase...');
        const token = await authenticate(pbUrl, adminEmail, adminPassword);
        console.log('登录成功');

        console.log(`正在读取脚本文件: ${filePath}`);
        const scriptContent = fs.readFileSync(filePath, 'utf-8');

        await publishCollectionScript(pbUrl, scriptContent, token);

        console.log('集合脚本发布成功');
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

async function publishCollectionScript(pbUrl, scriptContent, token) {
    const baseUrl = pbUrl.replace(/\/$/,'');

    const response = await fetch(`${baseUrl}/api/extension/jwt/claims`, {
        method: 'PATCH',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': token
        },
        body: JSON.stringify({
            script: scriptContent
        })
    });

    if (!response.ok) {
        const error = await response.json().catch(() => ({}));
        throw new Error(`发布失败: ${error.message || response.statusText}`);
    }

    return await response.json();
}

function parseArgs(args) {
    const config = {};

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
PocketBase 集合脚本发布工具

用法:
  node pb_publish_collection.js [options]

选项:
  -u, --url <url>     PocketBase 地址 (例如: http://localhost:8090)
  -e, --email <email> 管理员邮箱
  -p, --password <password> 管理员密码
  -f, --file <file>   要发布的 JS 脚本文件路径
  -h, --help          显示帮助

说明:
  此工具用于将自定义 JavaScript 脚本发布到 PocketBase 集合中。
  仅在需要自定义 JS 集合时使用。
`);
}

main();
