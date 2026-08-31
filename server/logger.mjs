const allowedLevels = new Set(["debug", "info", "warn", "error"]);

export function logEvent(level, event, fields = {}) {
  const safeLevel = allowedLevels.has(level) ? level : "info";
  const record = {
    timestamp: new Date().toISOString(),
    service: "hithub",
    level: safeLevel,
    event,
    ...fields,
  };
  process.stdout.write(`${JSON.stringify(record)}\n`);
}
