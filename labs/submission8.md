# Lab 8 — Submission

## Task 1 — Key Metrics for SRE and System Analysis

### 1.1 Monitor System Resources

#### Install monitoring tools

Command:
```sh
sudo apt install htop sysstat -y
```

Output:

![8_img_1.png](screenshots%2F8_img_1.png)

#### Resource monitoring

Command:
```sh
htop
```

Output:

![8_img_2.png](screenshots%2F8_img_2.png)

Command:
```sh
iostat -x 1 5
```

Output:

![8_img_3.png](screenshots%2F8_img_3.png)

#### Top resource consumers

Top 3 CPU consumers:
- /usr/bin/gnome-shell
- /usr/bin/gnome-shell
- /usr/bin/gnome-shell

Top 3 memory consumers:
- /usr/bin/gnome-shell
- /snap/telegram-desktop/.../telegram-desktop
- /usr/bin/gnome-shell

Top 3 I/O consumers:
- /usr/bin/gnome-shell
- /usr/bin/htop
- /usr/bin/gnome-terminal-server

![8_img_4.png](screenshots%2F8_img_4.png)
![8_img_5.png](screenshots%2F8_img_5.png)
---

### 1.2 Disk Space Management

#### Disk usage

Command:
```sh
df -h
```

Output:

![8_img_6.png](screenshots%2F8_img_6.png)

Command:
```sh
du -h /var | sort -rh | head -n 10
```

Output:

![8_img_7.png](screenshots%2F8_img_7.png)

#### Largest files in /var

Command:
```sh
sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3
```

Output:

![8_img_8.png](screenshots%2F8_img_8.png)

---

### Analysis

Monitoring CPU, memory and disk I/O helps identify system bottlenecks and performance issues.

Tools like `htop` provide a real-time overview of system resource usage, while `iostat` helps analyze disk activity and detect I/O saturation.

Disk usage analysis allows identifying large directories and files that consume the most space, which is important for system maintenance and optimization.

---

### Reflection

In this task, I learned how to monitor system resources using standard Linux tools and identify processes that consume the most CPU, memory and disk I/O.

This knowledge is essential for troubleshooting performance issues and maintaining system stability.

---

## Task 2 — Practical Website Monitoring Setup

### Chosen website

- URL: https://example.com

---

### API Check

- Purpose: Check if the website is reachable and returns a valid HTTP response
- Assertion: Status code equals 200
- Frequency: Every 1 minute

---

### Browser Check

- What is being checked: Page load and main content visibility
- Expected result: Page loads successfully and main elements are visible

---

### Alerts

- Alert type: Email alert
- Threshold: Failure of 2 consecutive checks
- Notification method: Email

---

### Screenshots

- Browser check configuration
- Successful check result
- Alert settings
- Dashboard overview

---

### Analysis

Website monitoring ensures service availability and helps detect outages early.

API checks verify basic availability, while browser checks simulate real user interactions and ensure that the website works correctly from the user's perspective.

Alerts allow quick reaction to incidents and reduce downtime.

---

### Reflection

In this task, I learned how to set up basic monitoring for a website, including API and browser checks.

Monitoring is a key part of DevOps and SRE practices because it helps maintain reliability and quickly detect issues in production systems.