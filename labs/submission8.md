# Lab 8 Solution

## Task 1

Outputs:

![all stats](<./Снимок экрана 2026-03-23 131725.png>)

Top CPU and memory consumers (Cursor server/extension host, cassandra DB):

![top cpu and mem](<./Снимок экрана 2026-03-23 132009.png>)

Top I/O consumers (sdd, main WSL root disk):

![top IO](<./Снимок экрана 2026-03-23 132134.png>)

Disk Usage:

```bash
(base) lexi@lexandrinnnt:~/DevOps-Intro$ df -h
du -h /var | sort -rh | head -n 10
Filesystem      Size  Used Avail Use% Mounted on
none            7.6G     0  7.6G   0% /usr/lib/modules/6.6.87.2-microsoft-standard-WSL2
none            7.6G  4.0K  7.6G   1% /mnt/wsl
drivers         895G  322G  574G  36% /usr/lib/wsl/drivers
/dev/sdd       1007G   79G  877G   9% /
none            7.6G  304K  7.6G   1% /mnt/wslg
none            7.6G     0  7.6G   0% /usr/lib/wsl/lib
rootfs          7.6G  2.7M  7.6G   1% /init
none            7.6G  944K  7.6G   1% /run
none            7.6G     0  7.6G   0% /run/lock
none            7.6G  1.1M  7.6G   1% /run/shm
none            7.6G   76K  7.6G   1% /mnt/wslg/versions.txt
none            7.6G   76K  7.6G   1% /mnt/wslg/doc
C:\             895G  322G  574G  36% /mnt/c

(base) lexi@lexandrinnnt:~/DevOps-Intro$ sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3
1.4G    /var/lib/mongodb/collection-47-8162888075226237177.wt
1.1G    /var/lib/postgresql/16/main/base/16452/16473
1.1G    /var/lib/postgresql/16/main/base/16421/16445
```

Reflection: I really should remove all databases that I used in the past :D

## Task 2

I created API check for yandex afisha and browser check for German Wikipedia.
Checks succeeded!!! But it was difficult :( 

![overview](<./Снимок экрана 2026-03-23 211137.png>)

![api check](<./Снимок экрана 2026-03-23 211627.png>)

![browser check](<./Снимок экрана 2026-03-23 211954.png>)