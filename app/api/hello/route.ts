import { NextResponse } from "next/server";

export async function GET() {
  const features: {
    name: string;
    status: "stable" | "experimental" | "error";
    description: string;
    data: Record<string, unknown>;
  }[] = [];

  // 1. Built-in fetch (Node 22 中正式稳定)
  try {
    const start = performance.now();
    const res = await fetch("https://jsonplaceholder.typicode.com/posts/1");
    const json = await res.json();
    features.push({
      name: "Built-in fetch",
      status: "stable",
      description:
        "Node 22 中 fetch API 正式稳定，无需再安装 node-fetch 第三方库",
      data: {
        endpoint: "https://jsonplaceholder.typicode.com/posts/1",
        responseTime: `${(performance.now() - start).toFixed(0)}ms`,
        title: json.title,
      },
    });
  } catch (e) {
    features.push({
      name: "Built-in fetch",
      status: "error",
      description: "fetch 调用失败",
      data: { error: String(e) },
    });
  }

  // 2. structuredClone (Node 22 正式稳定，支持 Date、Map、Set 等内置类型)
  {
    const original = {
      name: "Node.js",
      version: 22,
      nested: { value: 42 },
      date: new Date().toISOString(),
    };
    const cloned = structuredClone(original);
    cloned.nested.value = 100;
    features.push({
      name: "structuredClone",
      status: "stable",
      description: "深度拷贝，原生支持 Date、Map、Set、ArrayBuffer 等类型",
      data: {
        originalNestedValue: original.nested.value,
        clonedNestedValue: cloned.nested.value,
        deepCopyWorked: original.nested.value !== cloned.nested.value,
      },
    });
  }

  // 3. WebSocket 全局对象 (Node 22 正式稳定)
  features.push({
    name: "WebSocket",
    status: "stable",
    description:
      "Node 22 内置 WebSocket 客户端，符合 Web API 标准，无需 ws 等第三方库",
    data: {
      available: typeof WebSocket !== "undefined",
      type: typeof WebSocket,
    },
  });

  // 4. node:sqlite (Node 22 实验性功能)
  try {
    const { DatabaseSync } = await import("node:sqlite");
    const db = new DatabaseSync(":memory:");
    db.exec(
      "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, role TEXT)"
    );
    db.exec(
      "INSERT INTO users VALUES (1, 'Alice', 'admin'), (2, 'Bob', 'user'), (3, 'Charlie', 'user')"
    );
    const stmt = db.prepare("SELECT * FROM users WHERE role = ?");
    const admins = stmt.all("admin");
    db.close();
    features.push({
      name: "node:sqlite",
      status: "experimental",
      description:
        "Node 22 实验性内置 SQLite 支持（启动时需 --experimental-sqlite 标志）",
      data: {
        available: true,
        query: "SELECT * FROM users WHERE role = 'admin'",
        result: admins,
      },
    });
  } catch (e) {
    features.push({
      name: "node:sqlite",
      status: "experimental",
      description:
        "Node 22 实验性内置 SQLite（当前环境未启用，需 --experimental-sqlite）",
      data: { available: false, hint: "启动时添加 --experimental-sqlite 标志" },
    });
  }

  // 5. node:fs globSync (Node 22 新增)
  try {
    const { globSync } = await import("node:fs");
    const tsxFiles = globSync("app/**/*.tsx");
    const apiRoutes = globSync("app/api/**/*.ts");
    features.push({
      name: "node:fs globSync",
      status: "stable",
      description:
        "Node 22 在 fs 模块中新增 glob/globSync，支持通配符模式匹配文件",
      data: {
        tsxFiles,
        apiRoutes,
      },
    });
  } catch (e) {
    features.push({
      name: "node:fs globSync",
      status: "error",
      description: "globSync 不可用",
      data: { error: String(e) },
    });
  }

  return NextResponse.json({
    nodeVersion: process.version,
    platform: process.platform,
    pid: process.pid,
    features,
  });
}
