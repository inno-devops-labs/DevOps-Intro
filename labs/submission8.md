## Task 1.

CPU
![[cpu.png.png]]

Memory![[io.png.png]]

I/O
![[memory.png.png]]```
```
df -h

Filesystem      Size  Used Avail Use% Mounted on
none            1.9G     0  1.9G   0% /usr/lib/modules/6.6.87.2-microsoft-standard-WSL2
none            1.9G  4.0K  1.9G   1% /mnt/wsl
drivers         117G  113G  3.9G  97% /usr/lib/wsl/drivers
/dev/sdd       1007G  2.0G  954G   1% /
none            1.9G   76K  1.9G   1% /mnt/wslg
none            1.9G     0  1.9G   0% /usr/lib/wsl/lib
rootfs          1.9G  2.7M  1.9G   1% /init
none            1.9G  532K  1.9G   1% /run
none            1.9G     0  1.9G   0% /run/lock
none            1.9G     0  1.9G   0% /run/shm
none            1.9G   76K  1.9G   1% /mnt/wslg/versions.txt
none            1.9G   76K  1.9G   1% /mnt/wslg/doc
C:\             117G  113G  3.9G  97% /mnt/c
D:\              10G  7.8G  2.3G  78% /mnt/d
Z:\             350G  250G  101G  72% /mnt/z
tmpfs           1.9G   16K  1.9G   1% /run/user/1000

sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3

70M     /var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_noble_universe_binary-amd64_Packages
60M     /var/cache/apt/srcpkgcache.bin
60M     /var/cache/apt/pkgcache.bin
```

Анализируется wsl, а он не нагружен. Windows процессы не учитываются.
Как оптимизировать:
- лишние процессы
- очистить логи

---
## Task 2.

Выбранный сайт - https://github.com

![[check.png]]

![[browser.png]]

Проверка подтверждает, что главная страница GitHub загружается корректно.
- Проверяет, что заголовок страницы содержит слово "GitHub"
- Проверяет, что кнопка/ссылка "Sign in" видима на странице