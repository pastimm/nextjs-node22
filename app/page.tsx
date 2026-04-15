"use client";

import { useEffect, useState } from "react";

interface FeatureResult {
  name: string;
  status: "stable" | "experimental" | "error";
  description: string;
  data: Record<string, unknown>;
}

interface ApiResponse {
  nodeVersion: string;
  platform: string;
  pid: number;
  features: FeatureResult[];
}

const statusConfig = {
  stable: { label: "STABLE", color: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300" },
  experimental: { label: "EXPERIMENTAL", color: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300" },
  error: { label: "ERROR", color: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300" },
};

export default function Home() {
  const [data, setData] = useState<ApiResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("/api/hello")
      .then((res) => res.json())
      .then((json) => {
        setData(json);
        setLoading(false);
      });
  }, []);

  return (
    <div className="min-h-screen bg-zinc-50 font-sans dark:bg-black">
      <div className="mx-auto max-w-4xl px-6 py-16">
        {/* Header */}
        <div className="mb-12">
          <p className="text-sm font-medium text-zinc-500 dark:text-zinc-400">
            Node.js Feature Demos
          </p>
          <h1 className="mt-2 text-4xl font-bold tracking-tight text-black dark:text-zinc-50">
            Node 22 新特性演示
          </h1>
          {data && (
            <div className="mt-3 flex gap-4 text-sm text-zinc-500 dark:text-zinc-400">
              <span className="rounded-full bg-blue-100 px-3 py-1 font-mono text-blue-800 dark:bg-blue-900 dark:text-blue-300">
                {data.nodeVersion}
              </span>
              <span>Platform: {data.platform}</span>
              <span>PID: {data.pid}</span>
            </div>
          )}
        </div>

        {/* Loading */}
        {loading && (
          <div className="flex items-center gap-3 text-zinc-500">
            <div className="h-5 w-5 animate-spin rounded-full border-2 border-zinc-300 border-t-black dark:border-zinc-600 dark:border-t-white" />
            <span>正在检测 Node 22 特性...</span>
          </div>
        )}

        {/* Feature Cards */}
        {data && (
          <div className="grid gap-6 md:grid-cols-2">
            {data.features.map((feature) => {
              const cfg = statusConfig[feature.status];
              return (
                <div
                  key={feature.name}
                  className="rounded-xl border border-zinc-200 bg-white p-6 dark:border-zinc-800 dark:bg-zinc-950"
                >
                  <div className="flex items-start justify-between gap-2">
                    <h2 className="text-lg font-semibold text-black dark:text-zinc-50">
                      {feature.name}
                    </h2>
                    <span className={`shrink-0 rounded-full px-2.5 py-0.5 text-xs font-bold ${cfg.color}`}>
                      {cfg.label}
                    </span>
                  </div>
                  <p className="mt-2 text-sm text-zinc-600 dark:text-zinc-400">
                    {feature.description}
                  </p>
                  <pre className="mt-4 overflow-x-auto rounded-lg bg-zinc-100 p-3 text-xs leading-relaxed text-zinc-700 dark:bg-zinc-900 dark:text-zinc-300">
                    {JSON.stringify(feature.data, null, 2)}
                  </pre>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
