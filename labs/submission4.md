# Lab 4: Operating Systems & Networking

## Task 1 — Operating System Analysis

### 1.1 Boot Performance Analysis

**Get-WinEvent -ProviderName Microsoft-Windows-Kernel-Boot | Select-Object -First 5 TimeCreated, Message | Format-List**
```
TimeCreated : 21.02.2026 17:28:52
Message     : Status of reading and unsealing the master key array package

              Status: STATUS_SUCCESS
              PrimarySealedBlobName: VsmLocalKey2
              SecondaryProtectorVariableName: VsmLocalKeyProtector
              BlobFromUefiVariableSize: 723
              UefiContentIsSealed: 1
              UnsealedBlobSize: 210
              Pcr7SealingUsed: 1
              PkgTpmSealMaskLocal: 0x880
              PkgTpmCreationMaskLocal: 0x880
              NeedToResealKeyPkg: 0
              NeedToResealBackup: 0
              NeedToResealPca2023Backup: 0
              PlaintextBlobSize: 210
              PlaintextIsLegacyFormat: 0
              UefiBlobIsCorrupt: 0
              NewKeyID: 0
              VerifiedMicrosoftAuthority: 0
              ContainsAuthorityData: 0
              BootmgrAuthorityEventCount: 0
              Authority: 1

              Substatus

              PrimaryBlobUnsealStatus: STATUS_SUCCESS
              BackupBlobUnsealStatus: STATUS_WAIT_1
              Pca2023ProtectorUnsealStatus: STATUS_WAIT_1
              BackupBlobValidityCheckStatus: {Object exists}
              Attempt to create an object with an existing name.
              BackupBlobStillValid: true
              Pca2023ProtectorValidityCheckStatus: {Object exists}
              Attempt to create an object with an existing name.
              Pca2023ProtectorStillValid: true
              PrimaryBlobResealStatus: STATUS_WAIT_1
              BackupBlobResealStatus: STATUS_WAIT_1
              Pca2023ProtectorResealStatus: STATUS_WAIT_1
              V2ProtectorsUsed: 0
              LegacyUefiVarQueryStatus: STATUS_WAIT_1
              LegacyUefiVarCleanupStatus: STATUS_WAIT_1
              ActivePolicyVersion: 0
              LatchedPolicyVersion: 0
              UnlatchedPolicyVersion: 0

TimeCreated : 21.02.2026 17:28:52
Message     : Failed to load Pluton-Windows firmware. Status code: STATUS_SUCCESS, reason: Failed to apply firmware.

TimeCreated : 21.02.2026 17:28:52
Message     : The following boot type was used: 0x2.

TimeCreated : 21.02.2026 17:28:52
Message     : The following boot menu policy was used: 0x0.

TimeCreated : 21.02.2026 17:28:52
Message     : Boot manager spent 0 ms waiting for user input.
```

**(Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime**
```
Days              : 8
Hours             : 5
Minutes           : 34
Seconds           : 59
Milliseconds      : 634
Ticks             : 7112996340251
TotalDays         : 8.23263465306829
TotalHours        : 197.583231673639
TotalMinutes      : 11854.9939004183
TotalSeconds      : 711299.6340251
TotalMilliseconds : 711299634.0251
```

**Get-WmiObject Win32_LogonSession | ForEach-Object { $user = $_.__SERVER; $time = $_.StartTime; Write-Host "User: $user, Logon Time: $time" }**
```
User: LEV_PERMIAKOV, Logon Time: 20260213142706.233442+180
User: LEV_PERMIAKOV, Logon Time: 20260213142706.225674+180
```

**Observations:**
- System has been running for 8 days 5 hours 34 minutes (since February 13, 2026)
- Pluton firmware loading issue during boot (firmware failed to apply)
- Boot manager did not wait for user input (0 ms)
- TPM is used for key protection (Pcr7SealingUsed: 1)

### 1.2 Process Forensics

**Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 Id, ProcessName, @{Name="Memory(MB)";Expression={[math]::Round($_.WorkingSet/1MB,2)}}, CPU | Format-Table -AutoSize**
```
   Id ProcessName        Memory(MB) CPU
   -- -----------        ---------- ---
 3560 Memory Compression    1245.22
21976 Code                   432.55 95.84375
 9424 Telegram               406.49 4339.3125
22688 Code                   404.37 667.71875
 5276 Code                   368.54 7.6875
```

**Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Id, ProcessName, @{Name="CPU(s)";Expression={[math]::Round($_.CPU,2)}}, @{Name="Memory(MB)";Expression={[math]::Round($_.WorkingSet/1MB,2)}} | Format-Table -AutoSize**
```
   Id ProcessName   CPU(s) Memory(MB)
   -- -----------   ------ ----------
11168 Code        23403.78     148.45
 6260 Taskmgr     22879.03     126.29
14228 browser     13822.19     357.39
 4124 Code        11679.97      75.09
 4020 browser     10265.17     213.54
```

**Observations:**
- **Top memory-consuming process:** "Memory Compression" (1245.22 MB) - system process for memory compression
- Multiple VS Code instances consuming significant memory (```400 MB each)
- Browser processes heavily using CPU (up to 13822 CPU ticks)
- Task Manager unexpectedly high in CPU usage (22879 CPU ticks)

### 1.3 Service Dependencies

``Get-Service | Where-Object {$_.DependentServices} | ForEach-Object { Write-Host "\`nService: $($_.Name) ($($_.Status))" -ForegroundColor Green; Write-Host "Depends on: $($_.ServicesDependedOn | ForEach-Object {$_.Name})"; Write-Host "Dependent services: $($_.DependentServices | ForEach-Object {$_.Name})" }``
```
Service: AppIDSvc (Stopped)
Depends on: RpcSs CryptSvc AppID
Dependent services: applockerfltr

Service: AppXSvc (Running)
Depends on: rpcss staterepository
Dependent services: WSAIFabricSvc

Service: AudioEndpointBuilder (Running)
Depends on:
Dependent services: midisrv AarSvc_a5be8 AarSvc Audiosrv

... (output shortened for readability)
```

**Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object Name, Status, ServicesDependedOn, DependentServices | Format-Table -AutoSize**
```
Name                            Status ServicesDependedOn                                      DependentServices
----                            ------ ------------------                                      -----------------
agent_ovpnconnect              Running {}                                                      {}
AmneziaVPN-service             Running {nsi, BFE}                                              {}
AmneziaWGTunnel$AmneziaVPN     Running {Nsi, TcpIp}                                            {}
... (output shortened for readability)
```

**Get-Service -Name *network* | Select-Object Name, Status, ServicesDependedOn, DependentServices**
```
Name           Status ServicesDependedOn DependentServices
----           ------ ------------------ -----------------
WMPNetworkSvc Stopped {WSearch, http}    {}
```

**Observations:**
- RpcSs (Remote Procedure Call) is a key service with many dependencies
- Multiple VPN services present (AmneziaVPN, ovpnconnect) - user uses VPN
- Network services are mostly running (Dnscache, Dhcp, Wcmsvc)
- WMPNetworkSvc is stopped - media service not in use

### 1.4 User Sessions

**Get-WmiObject Win32_LogonSession | ForEach-Object { $session = $_; $user = $session.__SERVER; $time = $session.StartTime; if ($time) { $timeStr = [System.Management.ManagementDateTimeConverter]::ToDateTime($time); Write-Host "User session on $user started at $timeStr" } }**
```
User session on LEV_PERMIAKOV started at 02/13/2026 14:27:06
User session on LEV_PERMIAKOV started at 02/13/2026 14:27:06
```

**Get-EventLog -LogName Security -InstanceId 4624 -Newest 5 | ForEach-Object { $time = $_.TimeGenerated; $message = $_.Message; Write-Host "`nLogin at: $time"; Write-Host "Details: $($message.Substring(0, [Math]::Min(100, $message.Length)))..." }**
```

Login at: 02/21/2026 20:02:03
Details: Account login successful.

Subject:
        Security ID:             S-1-5-18
        Account Name...

Login at: 02/21/2026 20:01:31
Details: Account login successful.

Subject:
        Security ID:             S-1-5-18
        Account Name...

Login at: 02/21/2026 19:56:42
Details: Account login successful.

Subject:
        Security ID:             S-1-5-18
        Account Name...

Login at: 02/21/2026 19:51:14
Details: Account login successful.

Subject:
        Security ID:             S-1-5-18
        Account Name...

Login at: 02/21/2026 19:49:13
Details: Account login successful.

Subject:
        Security ID:             S-1-5-18
        Account Name...
```

**qwinsta**
```
 SESSION               USER                 ID  STATE     TYPE        DEVICE
 services                                            0  Disc
>console                   LevPe                     1  Active
```

**Observations:**
- Current user session LevPe is active (console)
- System shows logins with S-1-5-18 (system account)
- User has been working since February 13
- Only one active user in the system

### 1.5 Memory Analysis

**Get-CimInstance Win32_OperatingSystem; $totalMem = [math]::Round($os.TotalVisibleMemorySize/1MB, 2); $freeMem = [math]::Round($os.FreePhysicalMemory/1MB, 2); $usedMem = $totalMem - $freeMem**
```
Memory Information:
Total RAM: 15.78 GB
Used RAM: 11.63 GB
Free RAM: 4.15 GB
```

**$computer = Get-CimInstance Win32_ComputerSystem; $os = Get-CimInstance Win32_OperatingSystem**
```
Detailed Memory Info:
Total Physical Memory: 15.78 GB
Free Physical Memory: 4.15 GB
Total Virtual Memory: 29.11 GB
Free Virtual Memory: 1.63 GB
```

**Answer to "What is the top memory-consuming process?":**
Top memory-consuming process is "Memory Compression" with 1245.22 MB. This is a Windows system process that compresses memory pages to improve performance.

**Resource Utilization Patterns:**
- System is using ```74% of physical memory (11.63 GB out of 15.78 GB)
- Virtual memory is nearly exhausted (only 1.63 GB free out of 29.11 GB)
- VS Code and browsers are the main application memory consumers
- High CPU load from browsers and VS Code

---

## Task 2 — Networking Analysis

### 2.1 Network Path Tracing

**tracert github.com**
```
Tracing route to github.com [4.225.11.194] with maximum of 30 hops:

  1    67 ms    66 ms    68 ms  10.8.1.0
  2    67 ms    73 ms    71 ms  172.29.172.1
  3   113 ms    85 ms    73 ms  169.254.1.232
  4    75 ms    78 ms   204 ms  10.12.0.1
  5    61 ms    62 ms    64 ms  be-11-110.pe3.sto1.se.portlane.net [80.67.3.134]
  6    59 ms    63 ms    61 ms  be-5.cr3.sto1.se.portlane.net [80.67.4.136]
  7    74 ms    58 ms    64 ms  as8075-20g-sk1.sthix.net [192.121.80.59]
  8    62 ms    59 ms    70 ms  ae27-0.ear01.sto31.ntwk.msn.net [104.44.43.236]
  9    62 ms    61 ms    62 ms  be-22-0.ibr01.sto31.ntwk.msn.net [104.44.22.162]
 10    71 ms    72 ms    69 ms  51.10.15.107
 11    62 ms    67 ms    62 ms  51.10.27.42
 12    89 ms    69 ms    62 ms  51.10.12.234
 13     *        *        *     Request timed out.
 14     *        *        *     Request timed out.
 15     *        *        *     Request timed out.
 16    79 ms    71 ms    71 ms  4.225.11.194
```

**Resolve-DnsName github.com | Format-List**
```
Name       : github.com
Type       : A
TTL        : 44
DataLength : 4
Section    : Answer
IPAddress  : 4.225.11.194
```

**nslookup github.com**
```
Server:  one.one.one.one
Address:  1.1.1.1

Non-authoritative answer:
Name:    github.com
Address:  4.225.11.194
```

**Observations:**
- GitHub resolves to IP 4.225.11.194
- Traffic routes through Sweden (sto1.se, sthix.net)
- DNS server is Cloudflare (1.1.1.1)
- 3 intermediate nodes do not respond to ping (but traffic passes through)
- Route passes through Microsoft network (msn.net)

### 2.2 Packet Capture

**netsh trace start capture=yes tracefile=C:\temp\dns_capture.etl maxsize=10; Start-Sleep -Seconds 10; netsh trace stop**
```
Trace configuration:
-------------------------------------------------------------------
Status:             Running
Trace file:         C:\temp\dns_capture.etl
Append:             Off
Circular:           On
Max size:           10 MB
Report:             Off

Merging traces... done.
Creating data collection...
Collecting group policy data...
Collecting registry data...
Collecting OS data...
Collecting battery data...
Collecting network adapter data...
Collecting wireless autoconfig data...
Collecting WCM data...
Collecting WWAN data...
Collecting environment data...
Collecting winsock data...
Collecting firewall data...
Collecting miracast data...
Collecting WCN data...
Collecting NetIO data...
Collecting DNS data...
Collecting network neighbor data...
Collecting file sharing data...
Collecting networking events data...
Collecting network state data...
Collecting port state data...
Collecting vmswitch data...
Collecting service data...
Collecting SCM data...
Collecting upgrade data...
Collecting NetSetup data...
Collecting EDP data...
Collecting PolicyManager data...
Collecting HomeGroup data...
Collecting NDF data...
Collecting powershell data...
Collecting WWAN profile data...
Completing data collection... done.
Trace file and additional diagnostic information compiled into "C:\temp\dns_capture.cab".
File location = C:\temp\dns_capture.etl
Trace session was successfully stopped.
```

**dir C:\temp\dns_capture.etl**
```
    Directory: C:\temp

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a----        21.02.2026     20:22        5242880 dns_capture.etl
```

**Example DNS Query:**
During tracing, DNS traffic was captured with file size 5 MB. The file is saved at C:\temp\dns_capture.etl. Microsoft Network Monitor or Wireshark is required for content analysis. Typical DNS queries in the system go to Cloudflare DNS (1.1.1.1) for domain name resolution.

### 2.3 Reverse DNS

**Resolve-DnsName -Name 8.8.4.4 -Type PTR | Format-List**
```
Name     : 4.4.8.8.in-addr.arpa
Type     : PTR
TTL      : 74701
Section  : Answer
NameHost : dns.google
```

**nslookup 8.8.4.4**
```
Server:  one.one.one.one
Address:  1.1.1.1

Name:    dns.google
Address:  8.8.4.4
```

**Resolve-DnsName -Name 1.1.2.2 -Type PTR**
```
Resolve-DnsName : 2.2.1.1.in-addr.arpa : DNS name does not exist
```

**nslookup 1.1.2.2**
```
Server:  one.one.one.one
Address:  1.1.1.1

*** one.one.one.one can't find 1.1.2.2: Non-existent domain
```

**Comparison of reverse lookup results:**
- **8.8.4.4** successfully resolves to **dns.google** (public Google DNS)
- **1.1.2.2** has no PTR record (no reverse DNS record)
- Both queries go through DNS server 1.1.1.1 (Cloudflare)

**Insights:**
- Google maintains reverse DNS records for their DNS servers
- Not all IP addresses have PTR records
- Reverse lookup is important for email server authentication and security