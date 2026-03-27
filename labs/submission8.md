# Lab 8

## Task 1

I worked in an Ubuntu VM.

Top CPU usage:
- htop - 5.9%
- gnome-shell - 2.6%
- gnome-terminal-server - 1.3%

Top memory usage:
- firefox - 11.5%, 480M RES
- gnome-shell - 11.2%, 467M RES
- mutter-x11-frames - 2.4%, 101M RES

Top I/O usage:
- pipewire - 0.00 B/s
- pipewire -c filter-chain.conf - 0.00 B/s
- wireplumber - 0.00 B/s

df -h

```
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           419M  1.5M  417M   1% /run
/dev/sda2        25G  5.8G   18G  26% /
tmpfs           2.1G     0  2.1G   0% /dev/shm
tmpfs           5.0M  8.0K  5.0M   1% /run/lock
CompArc         477G  469G  8.3G  99% /media/sf_CompArc
tmpfs           419M  132K  419M   1% /run/user/1000
/dev/sr0         51M   51M     0 100% /media/a/VBox_GAs_7.2.4
```

du -h /var | sort -rh | head -n 10

```
1.6G	/var
1.4G	/var/lib
1.1G	/var/lib/snapd/snaps
1.1G	/var/lib/snapd
241M	/var/lib/apt/lists
241M	/var/lib/apt
148M	/var/cache
118M	/var/cache/apt
81M	/var/log
78M	/var/log/journal/32c7d91fa6cf4bda80821da8c4682fc3
```

Top 3 files in /var:

```
532M	/var/lib/snapd/snaps/gnome-42-2204_247.snap
252M	/var/lib/snapd/snaps/firefox_7766.snap
92M	/var/lib/snapd/snaps/gtk-common-themes_1535.snap
```

Conclusion: the system was mostly idle. Firefox and desktop processes used the most memory, and snapd used most of the space in /var.

## Task 2

I chose this website: https://moodle.innopolis.university

Checks:
- API check for site availability
- Browser check for the Course search link
- Check that it opens https://moodle.innopolis.university/course/search.php

Screenshots:
- labs/lab8/browser_check_config.png
- labs/lab8/succesful_check.png
- labs/lab8/alerts_config.png
- labs/lab8/dashboard.png