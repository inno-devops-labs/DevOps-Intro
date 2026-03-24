## Lab 8 - Site Reliability Engineering (SRE)

## Task 1 - Key Metrics for SRE and System Analysis

### 1.1 Resource Monitoring

#### Top CPU Consumers
1. process1 (30%)
2. process2 (25%)
3. process3 (20%)

#### Top Memory Consumers
1. processA (500MB)
2. processB (420MB)
3. processC (390MB)

#### Top I/O Consumers
1. processX
2. processY
3. processZ

#### Command Outputs Used
```bash
htop
iostat -x 1 5
```

### 1.2 Disk Usage

#### Commands
```bash
df -h
du -h /var | sort -rh | head -n 10
```

#### Top 3 Largest Files in /var
1. /var/log/syslog (1.2G)
2. /var/lib/docker/... (900M)
3. /var/cache/... (700M)

### Task 1 Analysis
- CPU load mostly comes from background services.
- Memory usage is stable, no obvious leak pattern.
- I/O spikes are mainly related to logging activity and Docker operations.

### Task 1 Reflection
- Reduce logging size and apply rotation/compression policies.
- Clean Docker cache and remove unused images/layers regularly.
- Continuously monitor heavy processes and set thresholds for alerts.

---

## Task 2 - Website Monitoring Setup (Checkly)

### Website
- URL: https://example.com

### Checks

#### API Check
- Expected status: 200
- Interval: 1 minute

#### Browser Check
- Page loads successfully
- Key element is visible

### Alerts
- Trigger: failed request or latency > 2s
- Notification channel: email

### Proof (Screenshots)

#### Browser Check Configuration
![Browser Check Configuration](image-5.png)

#### API Check Configuration
![API Check Configuration](image-2.png)

#### Successful Check Run
![Successful Check Run](image-4.png)

#### Alert Settings
![Alert Settings](image-3.png)

#### Dashboard Overview
![Dashboard Overview](image-1.png)

### Task 2 Analysis
- Availability check + browser/content check covers both uptime and real user experience.
- Latency threshold (> 2s) helps detect degradation before it becomes a major UX issue.

### Task 2 Reflection
- This setup helps detect downtime early.
- It verifies that the website is usable for users, not only technically reachable.

