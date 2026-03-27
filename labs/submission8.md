# Lab 8 — Site Reliability Engineering (SRE)

**Student:** Kamilya Shakirova
**Date:** 21-03-2026


---

## Task 1 — Key Metrics for SRE and System Analysis

- [x] Top 3 most consuming applications for CPU, memory, and I/O usage
- [x] Command outputs showing resource consumption
- [x] Top 3 largest files in the `/var` directory
- [x] Analysis: What patterns do you observe in resource utilization?
- [x] Reflection: How would you optimize resource usage based on your findings?

### 1.1 Monitor System Resources

1. **Install Monitoring Tools (if needed):**

```bash
kamilya@Kama:/mnt/d/Programs/DevOps-Intro$ sudo apt install htop sysstat -y
[sudo] password for kamilya: 
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
htop is already the newest version (3.0.5-7build2).
htop set to manually installed.
The following additional packages will be installed:
  libsensors-config libsensors5
Suggested packages:
  lm-sensors isag
The following NEW packages will be installed:
  libsensors-config libsensors5 sysstat
0 upgraded, 3 newly installed, 0 to remove and 61 not upgraded.
Need to get 519 kB of archives.
After this operation, 1649 kB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsensors-config all 1:3.6.0-7ubuntu1 [5274 B]
Get:2 http://archive.ubuntu.com/ubuntu jammy/main amd64 libsensors5 amd64 1:3.6.0-7ubuntu1 [26.3 kB]
Get:3 http://archive.ubuntu.com/ubuntu jammy-updates/main amd64 sysstat amd64 12.5.2-2ubuntu0.2 [487 kB]
Fetched 519 kB in 2s (212 kB/s)   
debconf: unable to initialize frontend: Dialog
debconf: (Dialog frontend requires a screen at least 13 lines tall and 31 columns wide.)
debconf: falling back to frontend: Readline
Preconfiguring packages ...
Selecting previously unselected package libsensors-config.
(Reading database ... 32117 files and directories currently installed.)                                                                                                     
Preparing to unpack .../libsensors-config_1%3a3.6.0-7ubuntu1_all.deb ...                                                                                                    
Unpacking libsensors-config (1:3.6.0-7ubuntu1) ...                                                                                                                          
Selecting previously unselected package libsensors5:amd64.                                                                                                                  
Preparing to unpack .../libsensors5_1%3a3.6.0-7ubuntu1_amd64.deb ...                                                                                                        
Unpacking libsensors5:amd64 (1:3.6.0-7ubuntu1) ...                                                                                                                          
Selecting previously unselected package sysstat.                                                                                                                            
Preparing to unpack .../sysstat_12.5.2-2ubuntu0.2_amd64.deb ...                                                                                                             
Unpacking sysstat (12.5.2-2ubuntu0.2) ...                                                                                                                                   
Setting up libsensors-config (1:3.6.0-7ubuntu1) ...                                                                                                                         
Setting up libsensors5:amd64 (1:3.6.0-7ubuntu1) ...                                                                                                                         
Setting up sysstat (12.5.2-2ubuntu0.2) ...                                                                                                                                  
debconf: unable to initialize frontend: Dialog                                                                                                                              
debconf: (Dialog frontend requires a screen at least 13 lines tall and 31 columns wide.)                                                                                    
debconf: falling back to frontend: Readline                                                                                                                                 
                                                                                                                                                                            
Creating config file /etc/default/sysstat with new version                                                                                                                  
update-alternatives: using /usr/bin/sar.sysstat to provide /usr/bin/sar (sar) in auto mode                                                                                  
Created symlink /etc/systemd/system/sysstat.service.wants/sysstat-collect.timer → /lib/systemd/system/sysstat-collect.timer.                                                
Created symlink /etc/systemd/system/sysstat.service.wants/sysstat-summary.timer → /lib/systemd/system/sysstat-summary.timer.                                                
Created symlink /etc/systemd/system/multi-user.target.wants/sysstat.service → /lib/systemd/system/sysstat.service.                                                          
Processing triggers for man-db (2.10.2-1) ...                                                                                                                               
Processing triggers for libc-bin (2.35-0ubuntu3.11) ...  
```

2. **Monitor CPU, Memory, and I/O Usage:**

htop
![alt text](image.png)

iostat -x 1 5
![alt text](image-1.png)

<details>
<summary>🔍 Understanding iostat output</summary>

- `%user`: CPU time in user space
- `%system`: CPU time in kernel space
- `%iowait`: CPU waiting for I/O operations
- `%idle`: CPU idle time

</details>

3. **Identify Top Resource Consumers:**

Find the top 3 most consuming applications for:
- **CPU usage**
- **Memory usage**
- **I/O usage**

### 1.2 Disk Space Management

1. **Check Disk Usage:**

```bash
df -h
du -h /var | sort -rh | head -n 10
```

2. **Identify Largest Files:**

```bash
sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3
```


### Analysis
#### What patterns do you observe in resource utilization?


### Reflection
#### How would you optimize resource usage based on your findings?




---

## Task 2 — Practical Website Monitoring Setup

- Website URL you chose to monitor
- Screenshots of browser check configuration
- Screenshots of successful check results
- Screenshots of alert settings
- Analysis: Why did you choose these specific checks and thresholds?
- Reflection: How does this monitoring setup help maintain website reliability?

### 2.1 Choose Your Website

1. **Select Target Website:**

   Pick ANY public website you want to monitor (e.g., your favorite store, news site, or portfolio)

### 2.2 Create Checks in Checkly

1. **Sign Up:**

   - Create a free account at [Checkly](https://checklyhq.com/)

2. **Create API Check for Basic Availability:**

   <details>
   <summary>💡 What to configure</summary>

   - **URL:** Your chosen website
   - **Assertion:** Status code is 200
   - **Frequency:** Choose appropriate check interval

   </details>

3. **Create Browser Check for Content & Interactions:**

   <details>
   <summary>💡 What to test</summary>

   Examples of what you can check:
   - Is a specific text/element visible on the page?
   - Does a button click work?
   - How long does page load take?
   - Can you fill out a form?

   Choose checks that make sense for your selected website.

   </details>

### 2.3 Set Up Alerts

1. **Configure Alert Rules:**

   Design alert rules of YOUR choice:
   - What to alert on? (e.g., failed checks, slow latency, downtime)
   - How to be notified? (email, Telegram, Slack, etc.)
   - Set thresholds that make sense for your site

### 2.4 Capture Proof & Documentation

1. **Run Checks Manually:**

   - Verify all checks work correctly
   - Observe the monitoring dashboard

2. **Take Screenshots:**

   Capture screenshots showing:
   - Your browser check configuration
   - A successful check result
   - Your alert settings
   - Dashboard overview

### Analysis
#### Why did you choose these specific checks and thresholds?


### Reflection
#### How does this monitoring setup help maintain website reliability?
