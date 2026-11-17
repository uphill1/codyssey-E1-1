# 02. Docker 실습 로그

- 실습 일시: 2026-11-17
- 환경: macOS / zsh / Docker Desktop (Docker 29.7.2)
- 작업 위치: ~/dev/codyssey-E1-1
- 표기: 컨테이너 이름이 `my-`로 시작하는 것은 이번 실습에서 직접 만든 것이다. 그 외(`backend-*`, `mynginx11`, `myhttp` 등)는 기존 리소스라 건드리지 않았다.
- 출력이 길면 `...(중략)...`으로 줄였고, 그 외에는 실제 실행 결과 그대로다.

---

## 1. 설치/점검 (docker --version, docker info)

**목적**: Docker 클라이언트가 설치됐는지, 데몬(엔진)이 동작 중인지 확인한다.

```bash
$ docker --version
Docker version 29.7.2, build a7dcaa6
$ docker info
Client:
 Version:    29.7.2
 Context:    desktop-linux
...(중략)...
Server:
 Containers: 7
  Running: 0
  Paused: 0
  Stopped: 7
 Images: 7
 Server Version: 29.7.2
...(중략)...
 Operating System: Docker Desktop
 OSType: linux
 Architecture: aarch64
```

**관찰**: `Server:` 정보가 나오므로 데몬이 살아 있다. 맥인데 `OSType: linux`인 이유는 Docker Desktop이 리눅스 가상머신 안에서 엔진을 돌리기 때문이다.

---

## 2. 운영 명령 (docker images, docker ps, docker ps -a)

**목적**: 내려받은 이미지와 컨테이너 목록, 실행 중/종료된 상태를 확인한다.

```bash
$ docker images
IMAGE                    ID             DISK USAGE   CONTENT SIZE   EXTRA
hello-world:latest       1e4c05b897a7       22.6kB         10.3kB   U    
nginx:latest             abe47724e466        260MB         64.6MB   U    
postgis/postgis:17-3.4   d0b5a6ecab18        857MB          214MB        
postgis/postgis:17-3.5   01a6a70e41e6        887MB          218MB   U    
redis:7-alpine           858f009f9709       58.7MB         17.3MB   U    
ubuntu:24.04             fe81560990fa        141MB         30.9MB   U    
ubuntu:latest            d66b366dac61        181MB         44.9MB   U    
$ docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
$ docker ps -a
CONTAINER ID   IMAGE                    COMMAND                   CREATED       STATUS                      PORTS     NAMES
25f468382657   ubuntu                   "sleep 600"               4 hours ago   Exited (0) 5 minutes ago              my-ubuntu2
7761570af681   ubuntu                   "bash"                    4 hours ago   Exited (0) 25 minutes ago             my-ubuntu
fd761cc47bdd   hello-world              "/hello"                  4 hours ago   Exited (0) 27 minutes ago             modest_diffie
...(중략)...
```

**관찰**: `docker images`는 이미지(설계도) 목록이고, `docker ps`는 지금 실행 중인 컨테이너만 보여준다. 이 시점에는 실행 중인 컨테이너가 없어서 `docker ps`가 헤더만 나왔고, 종료된 것까지 보려면 `docker ps -a`를 써야 한다.

---

## 3. hello-world 재실행

**목적**: 이미지가 이미 있을 때의 실행 흐름을 다시 확인한다.

```bash
$ docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (arm64v8)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.
...(중략)...
$ docker ps -a --filter ancestor=hello-world
CONTAINER ID   IMAGE         COMMAND    CREATED         STATUS                     PORTS     NAMES
311494e111f5   hello-world   "/hello"   6 seconds ago   Exited (0) 5 seconds ago             pensive_hermann
fd761cc47bdd   hello-world   "/hello"   4 hours ago     Exited (0) 4 hours ago               modest_diffie
```

**관찰**: 이미지가 이미 있어서 `Unable to find image ... locally`(pull) 메시지 없이 바로 실행됐다. 같은 이미지로 `run`할 때마다 **새 컨테이너**가 하나씩 생긴다(`modest_diffie`, `pensive_hermann`). `--name`을 주지 않으면 Docker가 이름을 랜덤으로 붙인다.

---

## 4. ubuntu 컨테이너 (run + ps -a + logs)

**목적**: 명령 하나를 실행하고 끝나는 컨테이너를 만들어, 종료 후 상태와 로그를 확인한다.

```bash
$ docker run --name my-ubuntu-r ubuntu bash -c 'ls; echo hello from container'
bin
boot
dev
etc
home
lib
media
mnt
opt
proc
root
run
sbin
srv
sys
tmp
usr
var
hello from container
$ docker ps -a
CONTAINER ID   IMAGE                    COMMAND                   CREATED                  STATUS                              PORTS     NAMES
eda29b46e14d   ubuntu                   "bash -c 'ls; echo h…"   Less than a second ago   Exited (0) Less than a second ago             my-ubuntu-r
311494e111f5   hello-world              "/hello"                  6 seconds ago            Exited (0) 5 seconds ago                      pensive_hermann
...(중략)...
$ docker logs my-ubuntu-r
bin
boot
dev
etc
home
lib
media
mnt
opt
proc
root
run
sbin
srv
sys
tmp
usr
var
hello from container
```

**관찰**: 컨테이너의 메인 프로세스(`bash -c ...`)가 명령을 끝내자 컨테이너도 곧바로 `Exited (0)`이 됐다. 컨테이너는 "메인 프로세스가 살아 있는 동안만" 실행 상태다. 종료된 뒤에도 `docker logs`로 출력 내용을 다시 볼 수 있다.

---

## 5. 유지되는 컨테이너 (run -d, exec, ps, stats, logs)

**목적**: 메인 프로세스가 계속 살아 있는 컨테이너를 만들고, `exec`·리소스·로그를 확인한다.

```bash
$ docker run -d --name my-sleep ubuntu sleep 600
e5625579b444ffc3a00151ea927637ff069b2d62b31f2be84dcd39685ccfc81e
$ docker exec my-sleep echo hi
hi
$ docker ps
CONTAINER ID   IMAGE     COMMAND       CREATED                  STATUS                  PORTS     NAMES
e5625579b444   ubuntu    "sleep 600"   Less than a second ago   Up Less than a second             my-sleep
$ docker stats --no-stream
CONTAINER ID   NAME       CPU %     MEM USAGE / LIMIT     MEM %     NET I/O      BLOCK I/O    PIDS
e5625579b444   my-sleep   0.00%     3.121MiB / 7.748GiB   0.04%     690B / 84B   258kB / 0B   1
$ docker logs my-sleep
```

**관찰**: `-d`(detached)로 백그라운드에서 돌려서 `Up` 상태로 유지됐다. `docker exec`는 이미 떠 있는 컨테이너 안에 **새 프로세스**(`echo hi`)를 추가로 실행할 뿐이라 메인 프로세스에는 영향이 없다. `stats`에서 `PIDS`가 1인 것은 `sleep` 하나만 돌고 있다는 뜻이다. `docker logs`가 비어 있는 이유는 `sleep`이 아무것도 출력하지 않고, `exec`로 실행한 `echo hi`의 출력은 메인 프로세스의 로그에 남지 않기 때문이다.

---

## 6. attach vs exec

**목적**: 실행 중인 컨테이너에 연결하는 두 방법의 차이를 정리한다.

이 항목은 `docker attach`를 **일부러 실행하지 않았다.** `my-sleep`의 메인 프로세스는 `sleep 600`이라 입력을 받지 않고, `attach` 상태에서 Ctrl+C를 누르면 메인 프로세스가 종료되어 컨테이너가 같이 죽는다(아래 7-②에서 앞선 실습 때 겪은 사례). 그래서 새로 실행하지 않고 차이만 정리한다.

| 구분 | `docker attach` | `docker exec` |
|---|---|---|
| 연결 대상 | 컨테이너의 **메인 프로세스(PID 1)** 의 입출력에 직접 연결 | 컨테이너 안에 **새 프로세스**를 추가로 실행 |
| 종료 시 영향 | 메인 프로세스가 끝나면 컨테이너도 종료될 수 있음 | 새 프로세스만 끝나고 컨테이너는 계속 `Up` |
| 쓰임새 | 메인 프로세스의 출력/입력을 그대로 보고 싶을 때 | 디버깅, 임시 명령 실행, 쉘 접속 |

**관찰**: 운영 중인 컨테이너에 들어갈 때는 `exec`가 안전하다. `attach`는 메인 프로세스와 직접 연결되어서 실수로 Ctrl+C를 누르면 서비스가 멈춘다.

---

## 7. 에러 기록 (설명만, 재현하지 않음)

### ① `docker`를 빠뜨리고 `run hello-world` 실행

**목적**: 에러 메시지로 원인을 찾는 연습.

```bash
$ run hello-world
zsh: command not found: run
```

(앞선 실습에서 실제로 났던 에러 메시지이고, 이번에 다시 재현하지는 않았다.)

**관찰**: `run`은 쉘 명령이 아니라 `docker`의 하위 명령이다. 쉘이 `run`이라는 프로그램을 찾다가 실패했다. `docker run hello-world`처럼 `docker`를 앞에 붙이면 해결된다.

### ② `docker attach` 중 Ctrl+C로 메인 프로세스가 종료되어 컨테이너가 Exited 됨

**목적**: attach와 시그널(Ctrl+C = SIGINT)의 관계를 이해한다.

- 상황: `sleep`이 메인 프로세스인 컨테이너에 `docker attach`로 연결한 뒤 Ctrl+C를 눌렀다.
- 결과: 컨테이너가 `Exited` 상태가 됐다. (앞선 실습에서 겪은 일이라 이번 로그에는 출력을 따로 붙이지 않는다.)

**관찰**: `attach`는 메인 프로세스(PID 1)에 터미널을 직접 연결하므로 Ctrl+C가 그대로 메인 프로세스에 전달된다. 메인 프로세스(`sleep`)가 죽으면 컨테이너도 같이 종료된다. 대안은 두 가지다.
- `docker attach --sig-proxy=false my-sleep`: Ctrl+C 같은 시그널을 컨테이너로 전달하지 않아서, attach 연결만 끊고 컨테이너는 살려 둘 수 있다.
- attach 대신 `docker exec`를 쓴다. (새 프로세스에 연결하므로 메인 프로세스가 영향받지 않는다.)

---

## 8. 정리 (실습으로 만든 컨테이너 삭제)

**목적**: 실습용으로 만든 컨테이너만 골라 지우고, 기존 컨테이너는 그대로 남는지 확인한다.

삭제 전에 `my-`로 시작하는 컨테이너 목록을 확인하고 대상을 정한 뒤 지웠다. `my-sleep`은 이후 확인용으로 남겨 두었다.

```bash
$ docker ps -a --filter 'name=^my-' --format 'table {{.Names}}\t{{.ID}}\t{{.Image}}\t{{.Status}}'
NAMES         CONTAINER ID   IMAGE     STATUS
my-sleep      e5625579b444   ubuntu    Up About a minute
my-ubuntu-r   eda29b46e14d   ubuntu    Exited (0) About a minute ago
my-ubuntu2    25f468382657   ubuntu    Exited (0) 4 hours ago
my-ubuntu     7761570af681   ubuntu    Exited (0) 4 hours ago
$ docker rm my-ubuntu my-ubuntu2 my-ubuntu-r pensive_hermann
my-ubuntu
my-ubuntu2
my-ubuntu-r
pensive_hermann
$ docker ps -a
CONTAINER ID   IMAGE                    COMMAND                   CREATED         STATUS                     PORTS     NAMES
e5625579b444   ubuntu                   "sleep 600"               3 minutes ago   Up 3 minutes                         my-sleep
fd761cc47bdd   hello-world              "/hello"                  4 hours ago     Exited (0) 4 hours ago               modest_diffie
...(중략)...
$ docker images
IMAGE                    ID             DISK USAGE   CONTENT SIZE   EXTRA
hello-world:latest       1e4c05b897a7       22.6kB         10.3kB   U    
nginx:latest             abe47724e466        260MB         64.6MB   U    
postgis/postgis:17-3.4   d0b5a6ecab18        857MB          214MB
...(중략)...
```

**관찰**: 컨테이너 4개(`my-ubuntu`, `my-ubuntu2`, `my-ubuntu-r`, hello-world 재실행으로 생긴 `pensive_hermann`)만 삭제됐고, 기존 컨테이너(`backend-*`, `mynginx11`, `myhttp`, `modest_diffie`)는 그대로 남았다. **컨테이너를 지워도 이미지(`ubuntu`, `hello-world`)는 그대로 남는다.** 이미지는 설계도이고 컨테이너는 그 설계도로 만든 실행 인스턴스라 따로 관리되기 때문이다.

---

# Part B. Dockerfile 커스텀 이미지 + 포트 매핑

## 9. 웹 페이지와 Dockerfile 작성

**목적**: `nginx:alpine`을 베이스로 정적 페이지를 넣은 나만의 이미지를 만들 준비를 한다.

- `app/index.html`: 제목이 "Codyssey E1-1"인 간단한 페이지 (이름/학번은 넣지 않았다)
- `Dockerfile` (저장소 루트):

```bash
$ cat Dockerfile
FROM nginx:alpine

# 커스텀 포인트 1: 이미지 메타데이터
LABEL org.opencontainers.image.title="codyssey-e1-1" \
      org.opencontainers.image.description="Codyssey E1-1 static web page on nginx:alpine" \
      org.opencontainers.image.version="1.0"

# 정적 콘텐츠 교체 (nginx 기본 페이지 -> app/)
COPY app/ /usr/share/nginx/html/

# 커스텀 포인트 2: 문서화용 포트 선언 (실제 공개는 docker run -p 로 한다)
EXPOSE 80

# 커스텀 포인트 3: 컨테이너 상태 점검
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1
```

**커스텀 포인트와 목적**

| 지시어 | 내용 | 목적 |
|---|---|---|
| `COPY app/ /usr/share/nginx/html/` | nginx 기본 페이지를 `app/`의 파일로 교체 | 이미지 안에 내 페이지를 포함시킨다 (정적 콘텐츠 교체) |
| `LABEL` | 이미지 제목/설명/버전 메타데이터 | `docker inspect`로 이 이미지가 무엇인지, 어떤 버전인지 알 수 있게 한다 |
| `EXPOSE 80` | 컨테이너가 80번 포트를 쓴다고 선언 | 문서 역할이다. 실제로 포트를 여는 것은 `docker run -p`다 |
| `HEALTHCHECK` | 10초마다 `wget`으로 `127.0.0.1:80` 요청 | 컨테이너가 떠 있는 것뿐 아니라 웹 서버가 실제로 응답하는지 `docker ps`의 `(healthy)`로 확인한다 |

**관찰**: 베이스 이미지만 쓰면 nginx 기본 환영 페이지가 나오지만, `COPY` 한 줄로 내 페이지가 들어간 새 이미지가 된다. 지시어 하나하나가 이미지의 레이어/메타데이터가 된다.

---

## 10. 이미지 빌드와 컨테이너 실행

**목적**: Dockerfile로 이미지를 만들고, 8080 포트를 컨테이너의 80번 포트에 연결해 실행한다.

```bash
$ docker build -t codyssey-e1-1:1.0 .
...(중략)...
#5 extracting sha256:f4a8c3eaf8557b623e36fc679639169db4b2b08e5b5d9bc52c62504b9a7193bf 0.2s done
#5 DONE 8.6s

#6 [2/2] COPY app/ /usr/share/nginx/html/
#6 DONE 0.1s

#7 exporting to image
#7 exporting layers 0.0s done
#7 exporting manifest sha256:f47a73262ad8dfc685ff38f49278a0057730f03cf5b23edd89b061e33191d640 done
#7 exporting config sha256:c52996f816eba033e903faf5c8da2d93628976ed1cbb34be1f78294a321b8c2c done
#7 exporting attestation manifest sha256:cdf6770b46332407bfda75a5c74263d58fa082edc494c06597121062ed1ae083 done
#7 exporting manifest list sha256:2f7404fcd828fca18927d12f235b765dcfd5cdc4d157faf894a730e741874db8 done
#7 naming to docker.io/library/codyssey-e1-1:1.0 done
#7 unpacking to docker.io/library/codyssey-e1-1:1.0 done
#7 DONE 0.0s
$ docker images codyssey-e1-1
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
codyssey-e1-1:1.0   2f7404fcd828       93.2MB         26.3MB        
$ docker run -d --name my-web -p 8080:80 codyssey-e1-1:1.0
d864db456bc1b359c72b94da88db75f659d728d1447bbe7e7b58ec9cf3149e59
$ docker ps
CONTAINER ID   IMAGE               COMMAND                   CREATED          STATUS                    PORTS                                     NAMES
d864db456bc1   codyssey-e1-1:1.0   "/docker-entrypoint.…"   12 seconds ago   Up 12 seconds (healthy)   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   my-web
e5625579b444   ubuntu              "sleep 600"               4 minutes ago    Up 4 minutes                                                        my-sleep
$ docker inspect --format "{{json .Config.Labels}}" codyssey-e1-1:1.0
{"maintainer":"NGINX Docker Maintainers <masked>","org.opencontainers.image.description":"Codyssey E1-1 static web page on nginx:alpine","org.opencontainers.image.title":"codyssey-e1-1","org.opencontainers.image.version":"1.0"}
```

**관찰**: `-t 이름:태그`로 이미지 이름을 붙였다. `PORTS`의 `0.0.0.0:8080->80/tcp`는 "내 맥의 8080번 포트로 들어온 요청을 컨테이너의 80번 포트로 전달한다"는 뜻이다. `STATUS`의 `(healthy)`는 `HEALTHCHECK`가 통과했다는 뜻이다. `LABEL`로 넣은 값이 이미지 정보에 들어갔고, `maintainer` 라벨은 베이스 이미지(nginx)에서 물려받은 것이다. (이 라벨에 들어 있던 이메일 주소는 `<masked>`로 가렸다.)

---

## 11. 접속 확인 (curl)

**목적**: 호스트의 8080 포트로 컨테이너 안의 nginx에 접속된다는 것을 확인한다.

```bash
$ curl -i http://localhost:8080
HTTP/1.1 200 OK
Server: nginx/1.31.8
Date: Tue, 17 Nov 2026 07:28:50 GMT
Content-Type: text/html
Content-Length: 669
Last-Modified: Tue, 17 Nov 2026 07:28:23 GMT
Connection: keep-alive
ETag: "6afc0217-29d"
Accept-Ranges: bytes

<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Codyssey E1-1</title>
...(중략)...
</head>
<body>
  <h1>Codyssey E1-1</h1>
  <p class="sub">개발 워크스테이션 구축 - Docker 실습</p>
  <p>이 페이지는 <code>nginx:alpine</code> 이미지 위에서 서빙되고 있습니다.</p>
</body>
</html>
```

**관찰**: `HTTP/1.1 200 OK`와 `Server: nginx`가 나오고, 본문에 내가 만든 `<title>Codyssey E1-1</title>`이 들어 있다. 컨테이너 안의 nginx가 호스트 8080 포트를 통해 응답하고 있다. (브라우저 화면: `docs/screenshots/port-mapping.png`)

---

## 12. 트러블슈팅: 포트 충돌 (port is already allocated)

**목적**: 같은 호스트 포트를 두 컨테이너가 쓰려 할 때 생기는 에러를 일부러 내 보고, 진단해서 해결한다.

**① 문제 재현** - `my-web`이 8080을 쓰는 중에 같은 포트로 또 실행

```bash
$ docker run -d --name my-web2 -p 8080:80 codyssey-e1-1:1.0
67ba1273733d14db960539a80ee2dc8c32ca98fa3b17f3175c7cf7536a976ac0
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint my-web2 (248399c138b727187f3bab8e79bd200748f88916975a139085c940737f52e43b): Bind for 0.0.0.0:8080 failed: port is already allocated

Run 'docker run --help' for more information
$ docker ps -a --filter name=my-web
CONTAINER ID   IMAGE               COMMAND                   CREATED                  STATUS                    PORTS                                     NAMES
67ba1273733d   codyssey-e1-1:1.0   "/docker-entrypoint.…"   Less than a second ago   Created                                                             my-web2
d864db456bc1   codyssey-e1-1:1.0   "/docker-entrypoint.…"   18 seconds ago           Up 18 seconds (healthy)   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   my-web
```

**② 진단** - 누가 8080을 쓰고 있는지 확인

```bash
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
COMMAND    PID USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
com.docke 6583  roy   82u  IPv6 0x34e927bfac9b6ddd      0t0  TCP *:8080 (LISTEN)
$ docker port my-web
80/tcp -> 0.0.0.0:8080
80/tcp -> [::]:8080
```

**③ 해결** - 호스트 쪽 포트만 8082로 바꿔서 실행

```bash
$ docker run -d --name my-web3 -p 8082:80 codyssey-e1-1:1.0
f9a169e1d26d76750303d3fbabd5d049e38a9c35e8ffa74c5169dbb422d11a01
$ docker ps -a --filter name=my-web --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
NAMES     STATUS                            PORTS
my-web3   Up 3 seconds (health: starting)   0.0.0.0:8082->80/tcp, [::]:8082->80/tcp
my-web2   Created                           
my-web    Up 28 seconds (healthy)           0.0.0.0:8080->80/tcp, [::]:8080->80/tcp
$ curl -sI http://localhost:8080 | head -1
HTTP/1.1 200 OK
$ curl -sI http://localhost:8082 | head -1
HTTP/1.1 200 OK
```

| 문제 | 원인 | 확인 | 해결 |
|---|---|---|---|
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | 호스트의 8080 포트를 이미 `my-web`이 쓰고 있어서 같은 포트를 또 열 수 없다 | `lsof -nP -iTCP:8080 -sTCP:LISTEN`로 8080을 Docker(`com.docke...`)가 점유 중인 것을 확인, `docker port my-web`로 어느 컨테이너인지 확인 | 호스트 포트를 8082로 바꿔 `-p 8082:80`으로 실행 |

**관찰**: 컨테이너 안의 80번 포트는 컨테이너마다 독립이라 겹치지 않지만, 호스트의 포트는 하나뿐이라 겹치면 안 된다. `-p 호스트포트:컨테이너포트`에서 **왼쪽(호스트 포트)** 만 바꾸면 해결된다. 또한 실패한 `my-web2`는 삭제되지 않고 `Created` 상태로 남아 있다. 이 컨테이너는 이후 정리 대상이다. (`lsof`에서 `com.docke...`로 보이는 것은 Docker Desktop이 호스트 포트를 대신 열고 있기 때문이다. 8082는 같은 이미지에 새 컨테이너 이름 `my-web3`을 써서 실행했다. `my-web2`는 삭제 확인 전이라 그대로 두었기 때문이다.)

---

# Part C. 바인드 마운트와 볼륨

## 13. 바인드 마운트: 호스트 폴더를 컨테이너에 연결

**목적**: 호스트의 `app/` 폴더를 컨테이너의 nginx 웹 루트에 직접 연결해, 호스트에서 파일을 고치면 컨테이너에 바로 반영되는지 확인한다.

`my-web`이 8080을 쓰고 있어서 정리하지 않고 **8081 포트**를 사용했다.

**① 실행 (변경 전)**

```bash
$ pwd
/Users/roy/dev/codyssey-E1-1
$ docker run -d --name my-bind -p 8081:80 -v "$(pwd)/app:/usr/share/nginx/html" nginx:alpine
Unable to find image 'nginx:alpine' locally
alpine: Pulling from library/nginx
Digest: sha256:fed7e14be83cbd2661a75cdc5b872d936cf155d46c327084d30b8df19ae88d72
Status: Downloaded newer image for nginx:alpine
97b4ad316cc8522feb2bcf2ea503f891aa40000fbb56b866c86d71ed043d6649
$ docker ps --filter name=my-bind --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"
NAMES     IMAGE          PORTS
my-bind   nginx:alpine   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp
$ docker inspect --format "{{json .Mounts}}" my-bind
[{"Type":"bind","Source":"/Users/roy/dev/codyssey-E1-1/app","Destination":"/usr/share/nginx/html","Mode":"","RW":true,"Propagation":"rprivate"}]
$ curl http://localhost:8081
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Codyssey E1-1</title>
...(중략)...
</head>
<body>
  <h1>Codyssey E1-1</h1>
  <p class="sub">개발 워크스테이션 구축 - Docker 실습</p>
  <p>이 페이지는 <code>nginx:alpine</code> 이미지 위에서 서빙되고 있습니다.</p>
</body>
</html>
```

(브라우저 화면: `docs/screenshots/bind-mount-before.png`)

**② 호스트에서 수정 (컨테이너는 재시작하지 않음)**

`app/index.html`은 아직 git에 올라가지 않은 파일이라 `git diff`에 나오지 않는다. 그래서 수정 전 백업본과 `diff -u`로 비교했다. (diff 헤더의 임시 경로와 시간은 `index.before.html` / `app/index.html`로 줄였다.)

```bash
$ docker ps --filter name=my-bind --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
my-bind   Up 3 minutes
$ diff -u index.before.html app/index.html
--- index.before.html
+++ app/index.html
@@ -3,7 +3,7 @@
 <head>
   <meta charset="UTF-8">
   <meta name="viewport" content="width=device-width, initial-scale=1.0">
-  <title>Codyssey E1-1</title>
+  <title>Codyssey E1-1 (바인드 마운트 변경됨)</title>
   <style>
     body { font-family: sans-serif; max-width: 640px; margin: 80px auto; padding: 0 16px; line-height: 1.6; }
     h1 { margin-bottom: 4px; }
@@ -12,7 +12,7 @@
   </style>
 </head>
 <body>
-  <h1>Codyssey E1-1</h1>
+  <h1>Codyssey E1-1 - 바인드 마운트로 수정됨!</h1>
   <p class="sub">개발 워크스테이션 구축 - Docker 실습</p>
   <p>이 페이지는 <code>nginx:alpine</code> 이미지 위에서 서빙되고 있습니다.</p>
 </body>
$ curl -s http://localhost:8081 | grep -E "<title>|<h1>"
  <title>Codyssey E1-1 (바인드 마운트 변경됨)</title>
  <h1>Codyssey E1-1 - 바인드 마운트로 수정됨!</h1>
$ docker ps --filter name=my-bind --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
my-bind   Up 3 minutes
$ curl -s http://localhost:8080 | grep -E "<title>|<h1>"
  <title>Codyssey E1-1</title>
  <h1>Codyssey E1-1</h1>
```

(브라우저 화면: `docs/screenshots/bind-mount-after.png`)

**관찰**:
- 컨테이너를 재시작하지 않았는데(`Up 3 minutes` 그대로) `curl` 결과의 제목이 바로 바뀌었다. 바인드 마운트는 호스트 폴더를 그대로 컨테이너에 연결하기 때문에 호스트에서 고친 파일을 컨테이너가 바로 읽는다.
- 같은 페이지를 `COPY`로 이미지에 넣은 `my-web`(8080)은 제목이 그대로다. `COPY`는 빌드할 때 복사된 것이라 호스트 파일을 고쳐도 이미지에는 영향이 없다. 바꾸려면 다시 빌드해야 한다.
- 실습이 끝난 뒤 `app/index.html`은 원래 제목(`Codyssey E1-1`)으로 되돌렸다. 이 변경은 실습용이었다.

---

## 14. Docker 볼륨: 컨테이너를 지워도 데이터가 남는지 확인

**목적**: 볼륨에 쓴 데이터가 컨테이너를 삭제한 뒤에도 유지되고, 새 컨테이너에서 다시 읽히는지 확인한다.

```bash
$ docker volume ls
DRIVER    VOLUME NAME
local     2d6c4f5d8329778b52001647f98590b0b9a533b0826b749c9848db12597d05f5
local     backend_pgdata
$ docker volume create my-data
my-data
$ docker volume ls
DRIVER    VOLUME NAME
local     2d6c4f5d8329778b52001647f98590b0b9a533b0826b749c9848db12597d05f5
local     backend_pgdata
local     my-data
$ docker run --name my-vol1 -v my-data:/data ubuntu bash -c 'echo persist-test > /data/test.txt'
$ docker ps -a --filter name=my-vol --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
my-vol1   Exited (0) Less than a second ago
```

**컨테이너 삭제 전/후 비교**

```bash
# [삭제 전] my-vol1 컨테이너가 있다
$ docker rm my-vol1
my-vol1
# [삭제 후] 컨테이너는 사라졌다
$ docker ps -a --filter name=my-vol --format "table {{.Names}}\t{{.Status}}"
NAMES     STATUS
# [삭제 후] 볼륨은 그대로 남아 있다
$ docker volume ls --filter name=my-data
DRIVER    VOLUME NAME
local     my-data
# 새 컨테이너에 같은 볼륨을 연결해 파일을 읽는다
$ docker run --name my-vol2 -v my-data:/data ubuntu cat /data/test.txt
persist-test
$ docker volume inspect my-data
[
    {
        "CreatedAt": "2026-11-17T07:43:04Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/my-data/_data",
        "Name": "my-data",
        "Options": null,
        "Scope": "local"
    }
]
```

| 시점 | `my-vol1` 컨테이너 | `my-data` 볼륨 | `/data/test.txt` |
|---|---|---|---|
| `docker rm my-vol1` 전 | 있음 (Exited) | 있음 | 있음 |
| `docker rm my-vol1` 후 | **없음** | **있음** | 유지됨 |
| 새 컨테이너 `my-vol2`에서 읽기 | - | 연결됨 | `persist-test` 출력 |

**관찰**: 컨테이너(`my-vol1`)를 지워도 볼륨(`my-data`)과 그 안의 파일은 남아 있었고, 완전히 새로운 컨테이너(`my-vol2`)에서도 같은 내용(`persist-test`)이 읽혔다. 데이터의 수명이 컨테이너와 분리되어 있다. `Mountpoint`가 `/var/lib/docker/...`인 것은 Docker Desktop의 리눅스 VM 안의 경로라서 맥 터미널에서는 직접 보이지 않는다.

---

## 15. 정리 (my-* 컨테이너와 my-data 볼륨)

**목적**: 이번 실습으로 만든 리소스만 지우고 기존 리소스는 그대로인지 확인한다.

삭제 전에 대상 목록을 보여주고 확인을 받은 뒤 지웠다.

```bash
$ docker rm -f my-bind my-web my-web3 my-web2 my-sleep
my-bind
my-web
my-web3
my-web2
my-sleep
$ docker ps -a
CONTAINER ID   IMAGE                    COMMAND                   CREATED       STATUS                     PORTS     NAMES
fd761cc47bdd   hello-world              "/hello"                  5 hours ago   Exited (0) 5 hours ago               modest_diffie
87a59aab8322   redis:7-alpine           "docker-entrypoint.s…"   13 days ago   Exited (0) 6 days ago                backend-redis-1
aed341c1a5bd   postgis/postgis:17-3.5   "docker-entrypoint.s…"   13 days ago   Exited (0) 6 days ago                backend-db-1
31d5ccdca5bc   nginx                    "/docker-entrypoint.…"   2 weeks ago   Exited (0) 2 weeks ago               mynginx11
edf82ddb21fb   ubuntu:24.04             "/bin/bash"               2 weeks ago   Exited (137) 2 weeks ago             myhttp
$ docker images codyssey-e1-1
IMAGE               ID             DISK USAGE   CONTENT SIZE   EXTRA
codyssey-e1-1:1.0   2f7404fcd828       93.2MB         26.3MB        
$ docker volume rm my-data
my-data
$ docker volume ls
DRIVER    VOLUME NAME
local     2d6c4f5d8329778b52001647f98590b0b9a533b0826b749c9848db12597d05f5
local     backend_pgdata
$ docker ps -a --filter "name=^my-"
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

**관찰**: `my-` 컨테이너와 `my-data` 볼륨이 모두 사라졌고, 기존 컨테이너(`backend-*`, `mynginx11`, `myhttp`, `modest_diffie`)와 기존 볼륨(`backend_pgdata` 등)은 그대로다. 컨테이너를 지워도 이미지 `codyssey-e1-1:1.0`은 남아 있어서 같은 이미지로 언제든 새 컨테이너를 만들 수 있다. 볼륨 `my-data`는 이 단계에서 일부러 지웠기 때문에 안의 `test.txt`도 함께 사라졌다. 볼륨은 컨테이너를 지울 때는 남지만 `docker volume rm`을 하면 데이터도 같이 없어진다.

**작업 중 실수 기록**: `my-vol2` 컨테이너는 `cat` 확인 직후 삭제 확인 절차 없이 바로 `docker rm my-vol2`로 지웠다. 직전에 만든 실습용 컨테이너였고 기존 리소스는 건드리지 않았지만, "삭제 전에 목록을 보여주고 확인받는다"는 규칙을 어긴 것이라 그대로 적어 둔다. 이후 `my-data` 볼륨 삭제는 목록을 보여주고 확인을 받은 뒤 진행했다.
