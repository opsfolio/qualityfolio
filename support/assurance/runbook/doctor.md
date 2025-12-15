# **Spry for DevOps / SRE**

Spry is a lightweight framework that helps DevOps and SRE teams **combine
documentation and automation** in one place. Instead of maintaining separate
runbooks, scripts, and wiki pages, Spry lets you write Markdown that is both
**readable** and **executable** — ensuring everything stays current, consistent,
and automation-ready.

## What Spry Solves

Operational knowledge is often scattered across teams and tools. Spry helps fix:

- Outdated runbooks
- Different teams following different workflows
- Scripts stored in multiple repositories without explanation
- Manual steps that slow incident response
- No standard way to run monitoring or health checks

Spry treats **operations as code**, so documentation and execution always stay
in sync.

## Who Should Use Spry?

Spry is ideal for teams working on:

- Production operations
- Incident management
- Monitoring & alerting
- DevOps automation
- Cloud platform engineering
- Kubernetes or container operations
- Site Reliability Engineering (SRE)

## Why Spry Is a Game-Changer

- **Reduces reliance on tribal knowledge** — everything is documented and
  runnable
- **Standardizes operations** across teams
- **Improves production reliability** using proactive checks
- **Accelerates onboarding** for new developers and SREs
- **Connects documentation to automation**, eliminating outdated docs

## Unified Operational Workflow

Spry brings all key SRE and DevOps components together:

### Human-Readable Documentation

Write Markdown that explains the purpose, steps, and context of any operational
task.

### Embedded Automation

Run Bash, Python, SQL, osquery, etc., directly from the same document.

### Monitoring & Health Checks

Create executable tasks for CPU, disk, memory, service uptime, and more.

### Incident Response Runbooks

Give responders clear instructions _and_ executable buttons in a single file.

### Infra Provisioning

Integrate commands for Terraform, Ansible, Docker, Kubernetes, and cloud
services.

## Getting Started

### **Prerequisites**

- Spry CLI installed
  [Refer to the Spry documentation for installation instructions.](https://sprymd.org/docs/getting-started/installation/)

### **Initialize project**

You may:

- Use an existing Spry repository, or
- Create a new SRE/Infra automation module

## **Linux Monitoring Runbooks — Core Tasks**

These tasks are **simple, critical, and ideal for demos**, onboarding, and real
SRE/DevOps usage.

They include checks for:

- CPU
- Memory
- Disk
- SSH security
- Critical services

## **CPU Utilization Monitoring**

### **Purpose:**

Detect CPU overload conditions and notify when CPU usage exceeds 80%.

### Example Spry Task

```bash cpu-utilization -C CPUusage --descr "Check CPU utilization using osquery and notify if threshold crossed"
#!/usr/bin/env -S bash

THRESHOLD=80
EMAIL="devops-team@example.com"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")


CPU_USAGE=$(osqueryi --json "
  SELECT 
    ROUND(AVG(100.0 - (idle * 100.0 / (user + system + idle + nice))), 2)
    AS avg_cpu_usage_percent 
  FROM cpu_time;
" | jq -r '.[0].avg_cpu_usage_percent')

CPU_INT=$(printf "%.0f" "$CPU_USAGE")

echo "$TIMESTAMP Current CPU Usage: ${CPU_INT}%"

if [ "$CPU_INT" -gt "$THRESHOLD" ]; then
    SUBJECT="ALERT: High CPU Usage on $(hostname)"
    BODY="CPU usage is ${CPU_INT}% (Threshold: ${THRESHOLD}%)."
    echo "$BODY" | mail -s "$SUBJECT" "$EMAIL"
    exit 1
fi

echo "CPU usage normal"
```

## **Disk Usage Monitoring**

Alerts when the root filesystem exceeds 80% usage.

```bash check-disk -C Diskusage --descr "Check root disk usage"
#!/usr/bin/env -S bash

THRESHOLD=80
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

USAGE=$(df -h / | awk 'NR==2 {gsub("%","",$5); print $5}')

echo "$TIMESTAMP Disk Usage: ${USAGE}%"

if [ "$USAGE" -gt "$THRESHOLD" ]; then
  echo " ALERT: Disk usage exceeded ${THRESHOLD}%"
  exit 1
fi

echo "Disk usage normal"
```

## **Memory Usage Monitoring**

Monitors RAM utilization and triggers alert if crossing 80%.

```bash check-memory -C Memoryusage --descr "Check memory usage percentage"
#!/usr/bin/env -S bash

THRESHOLD=80
USED=$(free | awk '/Mem:/ {printf("%d"), ($3/$2)*100}')

echo "$TIMESTAMP Memory Usage: ${USED}%"

if [ "$USED" -gt "$THRESHOLD" ]; then
  echo " ALERT: High memory usage"
  exit 1
fi

echo " Memory usage normal"
```

## **Failed SSH Login Detection**

Detects brute-force attempts and abnormal SSH activity.

```bash check-ssh-fail --descr "Detect failed SSH login attempts"
#!/usr/bin/env -S bash

THRESHOLD=5

if [ -f /var/log/auth.log ]; then
    FAILS=$(grep -c "Failed password" /var/log/auth.log)
else
    echo "auth.log does not exist"
    FAILS=0
fi

echo "Failed SSH Logins: $FAILS"

if [ "$FAILS" -gt "$THRESHOLD" ]; then
    echo "ALERT: Possible brute-force attack"
    exit 1
fi

echo "SSH login activity normal"
```

## **Critical Service Availability Check**

Ensures critical system services (example: nginx) are running.

```bash check-Service-running --capture ./Service-status.txt --decr "Check if Critical Service is Running"
#!/usr/bin/env -S bash

SERVICE="nginx"
EMAIL="devops-team@example.com"

IS_RUNNING=$(osqueryi --json "
SELECT count(*) AS running
FROM processes
WHERE name = 'nginx'
AND cmdline LIKE '%master process%';
" | jq -r '.[0].running')

echo "Master process count: $IS_RUNNING"

if [ "$IS_RUNNING" -eq 0 ]; then
    SUBJECT="ALERT: Service $SERVICE Not Running"
    BODY="Critical service '$SERVICE' is NOT running on $(hostname)."

    echo "$BODY" | mail -s "$SUBJECT" "$EMAIL"
    echo "Alert email sent!"
else
    echo "$SERVICE is running."
fi
```

This shows the output of each task

```bash Compilation-Results -I --descr "Show captured output"
#!/usr/bin/env -S cat
# captured output (safe): "${captured.CPUusage}"  "${memoized.Diskusage}" "${captured.Memoryusage}"
# captured output (unsafe): "$!{captured.CPUusage.text().trim()}"  "$!{captured.Diskusage.text().trim()}" "$!{memoized.Memoryusage.text().trim()}"
```

## How To Run Tasks

- Append the above code blocks in order in the Spryfile.md file.
- Execute the following commands in a bash terminal:

  ### Check CPU usage

  ```bash
  ./spry.ts task CPU-Utlization Spryfile.md --verbose rich
  ```

  ### Check Disk usage

  ```bash
  ./spry.ts task Disk-Usage Spryfile.md --verbose rich
  ```

  ### Memory Usage Monitoring

  ```bash
  ./spry.ts task check-memory Spryfile.md --verbose rich
  ```

  ### Check SSL expiry

  ```bash
  ./spry.ts task check-ssh-fail Spryfile.md --verbose rich
  ```

  ### Ensure essential services (nginx, mysql, redis, etc.) are running

  ```bash
  ./spry.ts task Critical-Service-Availability Spryfile.md --verbose rich
  ```

  ### Run the whole code block in a single command

  ```bash
  ./spry.ts run Spryfile.md --verbose rich
  ```

```spry exectutionReportLog
If you run `./spry rb report doctor.md` the output log of the report will be
inserted here.
```
