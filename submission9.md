I.
1. 2 медиум риск уязвимостей найдено

2. Первая интересная уязвимость:
Cross-Origin-Opener-Policy header is a response header that allows a site to control if others included documents share the same browsing context. Sharing the same browsing context with untrusted documents might lead to data leak.
Вторая интересная уязвимость:
A dangerous JS function seems to be in use that would leave the site vulnerable.

3. Content-Security-Policy Отсутствует
Cross-Origin-Embedder-Policy Отсутствует
Cross-Origin-Opener-Policy Отсутствует

4. https://drive.google.com/file/d/15WOh6y7_n8dTy_tjXcTXAZO4EclTtViK/view?usp=sharing

5. Ошибки конфигурации, контроль доступа и инъекции.

II.

1. 51 high и 10 critical

2.  braces (package.json)               │ CVE-2024-4068     
 express-jwt (package.json)          │ CVE-2020-15084

3. Различные типы code execution

4. https://drive.google.com/file/d/1uNhpA5QXES-7gAa8HtXIQJDC8VdiJPxM/view?usp=sharing

5. Потому что образ, который вы тестировали (bkimminich/juice-shop), наверняка содержит критические уязвимости, и если бы вы запустили его в production без проверки, злоумышленники могли бы взломать вашу систему через известные CVE.

6. Вот так может это выглядело бы в коде.

build:
  script:
    - docker build -t myapp:latest .
    
scan:  # <---- я добавил эту секцию
  script:
    - docker run aquasec/trivy:0.69.3 image myapp:latest
    - if [ $? -ne 0 ]; then exit 1; fi  # если ошибка, то всё стоп
    
deploy:
  script:
    - docker push myapp:latest
    - kubectl apply -f deployment.yaml