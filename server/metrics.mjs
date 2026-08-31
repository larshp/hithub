const requestMetrics = {
  requests: 0,
  errors: 0,
  duration_ms_total: 0,
  duration_ms_max: 0,
  statuses: {},
};

export function observeRequest(status, durationMs) {
  requestMetrics.requests += 1;
  if (status >= 500) requestMetrics.errors += 1;
  requestMetrics.duration_ms_total += durationMs;
  requestMetrics.duration_ms_max = Math.max(requestMetrics.duration_ms_max, durationMs);
  const statusKey = String(status);
  requestMetrics.statuses[statusKey] = (requestMetrics.statuses[statusKey] || 0) + 1;
}

export function metricsSnapshot() {
  return {
    requests: requestMetrics.requests,
    errors: requestMetrics.errors,
    duration_ms_total: requestMetrics.duration_ms_total,
    duration_ms_max: requestMetrics.duration_ms_max,
    statuses: {...requestMetrics.statuses},
  };
}
