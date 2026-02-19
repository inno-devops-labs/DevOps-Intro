1. Изменения, которые я внес в файл рабочего процесса:
	Собственно, все его содержимое)
2. Системная информация от раннера:
	В разделе hardware specifications:

🔧=== CPU INFORMATION ===
Model name:                           AMD EPYC 7763 64-Core Processor
CPU(s):                               4
On-line CPU(s) list:                  0-3
NUMA node0 CPU(s):                    0-3
Thread(s) per core:                   2

💾=== MEMORY INFORMATION ===
               total        used        free      shared  buff/cache   available
Mem:            15Gi       953Mi       9.1Gi        40Mi       5.9Gi        14Gi
Swap:          4.0Gi          0B       4.0Gi

💽=== DISK INFORMATION ===
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        72G   50G   23G  70% /
tmpfs           7.9G   84K  7.9G   1% /dev/shm
tmpfs           3.2G 1008K  3.2G   1% /run
tmpfs           5.0M     0  5.0M   0% /run/lock
efivarfs        128M   32K  128M   1% /sys/firmware/efi/efivars
/dev/sda16      881M   62M  758M   8% /boot
/dev/sda15      105M  6.2M   99M   6% /boot/efi
/dev/sdb1        74G  4.1G   66G   6% /mnt
tmpfs           1.6G   12K  1.6G   1% /run/user/1001

	В разделе runner capabilities:
⚡=== RUNNER CAPABILITIES ===
Architecture: x86_64
Kernel version: 6.11.0-1018-azure
Hostname: runnervmwffz4
Current user: runner
Available processors: 4
Total memory: 15Gi

3. Автоматический запуск происходит сам по пушам в репозиторий. Удобно для постоянного тестирования, но не гибко - все привязано к веткам.
Ручной запускаешь когда хочешь сам через интерфейс GitHub. Можно настроить параметры под конкретную задачу, удобно для экспериментов или деплоя. В истории видно, что запускал вручную, а что сработало автоматически.

4. Работает на архитектуре x86_64. Вилдимо, на ubuntu. Окружение, исходя из runner.environment, github-hosted.