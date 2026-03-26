I.

1. 

user@user-pc:~/Desktop$ top -b -n 1 -o %CPU | head -10
top - 18:34:18 up 16:05,  1 user,  load average: 1.11, 1.06, 2.10
Tasks: 183 total,   1 running, 182 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :   1968.7 total,     99.2 free,   1587.5 used,    334.5 buff/cache     
MiB Swap:      0.0 total,      0.0 free,      0.0 used.    381.2 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   3513 user      20   0  638352  73544  53676 S   9.1   3.6  50:53.54 RDD Pro+
  37160 user      20   0   14500   5416   3368 R   9.1   0.3   0:00.01 top
      1 root      20   0   22896   9388   4908 S   0.0   0.5   0:03.61 systemd


2. user@user-pc:~/Desktop$ top -b -n 1 -o %MEM | head -10
top - 18:34:25 up 16:05,  1 user,  load average: 0.94, 1.02, 2.08
Tasks: 183 total,   1 running, 182 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :   1968.7 total,     97.0 free,   1588.7 used,    335.9 buff/cache     
MiB Swap:      0.0 total,      0.0 free,      0.0 used.    380.0 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   3263 user      20   0   11.5g 480284  73172 S   0.0  23.8  22:45.63 firefox
   5801 user      20   0 7400732 410476  51928 S  10.0  20.4  33:02.71 Isolate+
   1205 root      20   0  370680 102616  26472 S  10.0   5.1      7,50 Xorg

3. user@user-pc:~/Desktop$ top -b -n 1 | head -10
top - 18:35:08 up 16:06,  1 user,  load average: 0.63, 0.94, 2.01
Tasks: 183 total,   2 running, 181 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.0 us, 12.5 sy,  0.0 ni, 87.5 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st 
MiB Mem :   1968.7 total,     85.9 free,   1592.7 used,    341.8 buff/cache     
MiB Swap:      0.0 total,      0.0 free,      0.0 used.    376.0 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
   3513 user      20   0  638336  73544  53676 S  20.0   3.6  51:01.40 RDD Pro+
   1205 root      20   0  370680 102616  26472 S  10.0   5.1      7,50 Xorg
   3263 user      20   0   11.5g 482760  73172 S  10.0  23.9  22:49.01 firefox
user@user-pc:~/Desktop$ 

4. user@user-pc:~/Desktop$ sudo find /var -type f -exec du -h {} + | sort -rh | head -n 3
532M    /var/lib/snapd/cache/bece47eaffcab46af8b7ec79322cdf6d6aa8f3ffaaa5b1f51e4dcec1333e33b6840775d7fbc4736d74ddfcbec1e8d58a
517M    /var/lib/snapd/seed/snaps/gnome-42-2204_202.snap
255M    /var/lib/snapd/cache/e1980a40b86b25c7212576fbb1ccb993f8237aeb65bde8725129ecf2730bcf44012e6034480c2442a2b2905f604f11f8

5. Как и ожидалось, firefox есть очень много памяти, но не прцоессор. 
Самые большие файлы - кэшевые, что видно из директории cache.

6. Добавил бы память, потому что firefox использует почти четверть всей памяти, которая у меня есть




II.

1. youtube.com
2. Вот код, который я запускал
const { expect, test } = require('@playwright/test')

test.setTimeout(210000)
test.use({ actionTimeout: 10000 })

test('visit page and take screenshot', async ({ page }) => {
  const response = await page.goto(process.env.ENVIRONMENT_URL || 'https://youtube.com')

  // Проверка заголовка
  await expect(page).toHaveTitle(/YouTube/);

  const acceptButton = page.locator('button:has-text("Accept all"), button:has-text("I agree"), button[aria-label*="accept"]').first();

    if (await acceptButton.isVisible({ timeout: 5000 })) {
      console.log('Cookie consent accepted');
      await page.waitForTimeout(1000);
    }
  
  const input = page.locator('input[name="search_query"]');
  await expect(input).toBeVisible();
  await input.fill("T-series")
  console.log("T-Series was filled correctly")
  
})

3. Вот вывод 
Starting job
Creating runtime version 2026.04 using Node.js 24
Running Playwright test script
Running 1 test using 1 worker
[1/1] [chromium] › test.spec.js › visit page and take screenshot
[chromium] › ../../checkly/functions/src/2026-04/node_modules/vm2/lib/bridge.js:672:11 › visit page and take screenshot
Cookie consent accepted
T-Series was filled correctly

4. https://drive.google.com/drive/folders/1bL2GmO4NvbKv0g_Y5uqsk14rZWvXdHP_?usp=drive_link
5. Потому что они довольно просты в использовании и тем не менее проверяют работоспособность сайта
6. Напрямую. Благодаря такому мониторингу можно отслеживать работоспособность сайта целиком и его компонент после любойго изменения.
