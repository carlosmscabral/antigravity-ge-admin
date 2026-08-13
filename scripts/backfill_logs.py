#!/usr/bin/env python3
import json

def backfill():
    with open('/tmp/raw_logs.json', 'r') as f:
        logs = json.load(f)

    out_records = []
    for log in logs:
        record = {
            "timestamp": log.get("timestamp"),
            "receiveTimestamp": log.get("receiveTimestamp"),
            "insertId": log.get("insertId"),
            "logName": log.get("logName"),
            "severity": log.get("severity"),
            "labels": log.get("labels", {}),
            "jsonPayload": log.get("jsonPayload", {})
        }
        out_records.append(record)

    with open('/tmp/formatted_logs.json', 'w') as f:
        for r in out_records:
            f.write(json.dumps(r) + '\n')

    print(f"Formatted {len(out_records)} log records into /tmp/formatted_logs.json")

if __name__ == '__main__':
    backfill()
