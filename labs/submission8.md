# Lab 8 - Submission

## Task 1 - Key Metrics for SRE and System Analysis

### Commands used

```bash
sudo apt-get update -y
sudo apt-get install -y htop sysstat iotop

ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 15
ps -eo pid,comm,%mem,%cpu --sort=-%mem | head -n 15
iostat -x 1 5
pidstat -d 1 5

df -h
sudo du -h /var | sort -rh | head -n 10
sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3
```

### Key results

Top 3 CPU consumers (excluding short-lived `ps`):
1. `gnome-shell` (~1.2% CPU)
2. `packagekitd` (~0.7% CPU)
3. `happd` (~0.2% CPU)

Top 3 memory consumers:
1. `gnome-shell` (~5.8% MEM)
2. `mutter-x11-frames` (~1.7% MEM)
3. `gsd-xsettings` (~1.3% MEM)

Top 3 I/O consumers (`iotop` under controlled load):
1. `dd if=/dev/zero of=/tmp/lab8-io-test.bin ...` (write up to ~408 MB/s)
2. `dd if=/var/lib/snapd/snaps/gnome-42-2204_247.snap ...` (read ~21-38 MB/s)
3. `dd if=/var/lib/snapd/cache/... ...` (read ~30-39 MB/s)

Top 3 largest files in `/var`:
1. `607M /var/lib/snapd/cache/6b8f0b8920d12519d7c5e677950a231810fa253e34962f312b3dfa58af9d91eeab9d5c1b3483cf0da6df66f23f3f5f8d`
2. `532M /var/lib/snapd/snaps/gnome-42-2204_247.snap`
3. `395M /var/lib/snapd/cache/651a6f21a71dfa0a5303df4e7e5661ba7a9213d5177cdc99ae3f0a1798e47bd6ee4b3805063e8f86da1f7b1b8ce9eacb`

Artifacts:
- `labs/artifacts/lab8/top-cpu.txt`
- `labs/artifacts/lab8/top-mem.txt`
- `labs/artifacts/lab8/iostat-x-1-5.txt`
- `labs/artifacts/lab8/pidstat-d-1-5.txt`
- `labs/artifacts/lab8/iotop-active.txt`
- `labs/artifacts/lab8/df-h.txt`
- `labs/artifacts/lab8/du-var-top10.txt`
- `labs/artifacts/lab8/var-largest-3-files.txt`

### Analysis

The system stayed mostly idle on CPU, with desktop services as the primary steady consumers. Most disk usage in `/var` is concentrated in `snapd` cache and snap packages, while Docker storage usage is smaller in this snapshot.

### Reflection

Main optimization actions:
- Clean snap cache and remove unused snap revisions.
- Keep periodic Docker image cleanup.
- Track baseline CPU/I/O/storage trends and alert on deviations.

---

## Task 2 - Practical Website Monitoring Setup (Checkly)

### Monitored website

- `https://example.com`

### Configured checks

1. API Check
   - URL: `https://example.com`
   - Assertion: status code `200`
   - Frequency: every `5` minutes

2. Browser Check
   - URL: `https://example.com`
   - Validation: page title contains `Example Domain`
   - Validation: text `Example Domain` is visible

3. Alerts
   - Alert on failed checks
   - Alert on high latency threshold
   - Notification channel: email

### Evidence (screenshots)

- `labs/artifacts/lab8/screenshots/checkly-browser-config.png`
- `labs/artifacts/lab8/screenshots/checkly-success-result.png`
- `labs/artifacts/lab8/screenshots/checkly-alert-settings.png`
- `labs/artifacts/lab8/screenshots/checkly-dashboard-overview.png`

### Analysis

The setup combines availability checks (API) and user-facing behavior checks (Browser). This reduces blind spots where endpoint status is green but user experience is degraded.

### Reflection

This monitoring approach improves incident detection speed and helps reduce MTTR by alerting on both downtime and performance issues.
