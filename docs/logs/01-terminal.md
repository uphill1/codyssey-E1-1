# 01. 터미널 조작 및 권한 실습 로그

- 실습 일시: 2026-11-16
- 환경: macOS / zsh
- 작업 위치: ~/dev/codyssey-E1-1

---

## 1. 현재 위치 확인 (pwd)

**목적**: 현재 내가 어느 폴더에 있는지 확인

```bash
$ pwd
/Users/roy/dev/codyssey-E1-1
```

**관찰**: 출력이 /로 시작하니까 절대 경로를 의미한다.

---

## 2. 목록 확인 (ls -a)

**목적**: 숨김 파일까지 포함해서 폴더 안의 전체 내용을 확인한다.

```bash
$ ls -a
.              .git           app
..             01-terminal.md docs
```

**관찰**: `ls`만 쓰면 `.`으로 시작하는 숨김 항목(`.`, `..`, `.git`)은 안 보이고, `ls -a`를 쓰면 함께 보인다. `.`은 현재 폴더, `..`은 상위 폴더이고, `.git`은 이 폴더가 Git 저장소라는 표시다.

---

## 3. 디렉토리 생성 (mkdir -p)

**목적**: 폴더를 만들고, 하위 폴더까지 구조를 확인한다.

```bash
$ mkdir -p docs/logs
$ ls -R docs
logs        screenshots

docs/logs:
01-terminal.md

docs/screenshots:
```

**관찰**: `-p`는 중간 폴더까지 한 번에 만들어 준다. `ls -R`은 하위 폴더 안의 내용까지 재귀적(Recursive)으로 보여주는 옵션이다.

---

## 4. 빈 파일 생성 (touch)

**목적**: 내용이 없는 새 파일을 만든다.

```bash
$ touch docs/logs/01.terminal.md
$ ls -l docs/logs
total 0
-rw-r--r--@ 1 roy  staff  0 11월 16 16:07 01.terminal.md
```

**관찰**: `ls -l`로 보면 권한(`-rw-r--r--`), 소유자, 크기(0), 수정 시간까지 나온다. 빈 파일이라 크기가 0이다.

---

## 5. 이동 / 이름 변경 (mv)

**목적**: 파일 이름을 바꾼다.

```bash
$ mv docs/logs/01.terminal.md docs/logs/01-terminal.md
$ ls -l docs/logs
<여기에 실제 출력 붙여넣기>
```

**관찰**: `mv`는 같은 폴더 안에서 쓰면 이름 변경이 된다. 파일명 오타(`.` → `-`)를 이 명령으로 고쳤다.

## 6~9. 복사 / 내용 확인 / 삭제 / 경로 이동 (cp, cat, rm, cd)

**목적**: 연습용 폴더(`practice`)에서 파일 내용 확인, 복사, 삭제, 절대/상대 경로 이동을 실습한다.

```bash
$ mkdir -p practice && cd practice
$ echo "hello" > a.txt
$ cat a.txt
hello
$ cp a.txt b.txt
$ ls -l
total 16
-rw-r--r--@ 1 roy  staff  6 11월 17 11:14 a.txt
-rw-r--r--@ 1 roy  staff  6 11월 17 11:14 b.txt
$ rm b.txt
$ ls
a.txt
$ cd ~/dev/codyssey-E1-1
$ cd practice
```

**관찰**:
- `cat a.txt`로 파일 내용(`hello`)을 확인했다.
- `cp`는 원본(`a.txt`)을 그대로 두고 사본(`b.txt`)을 만든다. `ls -l`에서 두 파일의 크기(6바이트)가 같다.
- `rm b.txt` 후 `ls`에는 `a.txt`만 남았다. `rm`은 휴지통 없이 바로 삭제되므로 되돌릴 수 없다.
- `cd ~/dev/codyssey-E1-1`은 `/`나 `~`부터 시작하는 **절대 경로**라서 어느 위치에서든 같은 곳으로 간다. `cd practice`는 현재 위치 기준의 **상대 경로**라서 위치가 다르면 에러가 난다.

## 10. 권한 실습: 파일

**목적**: 파일 권한을 바꾸고 전/후를 비교한다.

**변경 전**
```bash
$ ls -l a.txt
-rw-r--r--@ 1 roy  staff  6 11월 17 11:14 a.txt
```

**변경 명령 / 변경 후**
```bash
$ chmod 600 a.txt
$ ls -l
total 8
-rw-------@ 1 roy  staff  6 11월 17 11:14 a.txt
$ chmod 000 a.txt
$ cat a.txt
cat: a.txt: Permission denied
$ chmod 644 a.txt
```

**관찰**: 숫자는 r=4, w=2, x=1을 더해 소유자/그룹/기타 순서로 읽는다. 600은 `rw-------`, 644는 `rw-r--r--`이다. 000으로 만들자 소유자도 `cat`이 거부됐고, 권한을 원래대로 복구했다.

---

## 11. 권한 실습: 디렉토리

**목적**: 디렉토리 권한 변경 전/후를 비교하고, `x` 권한의 의미를 확인한다.

```bash
$ ls -ld practice
drwxr-xr-x@ 3 roy  staff  96 11월 17 11:14 practice
$ chmod 644 practice
$ ls -ld practice
drw-r--r--@ 3 roy  staff  96 11월 17 11:14 practice
$ cd practice
cd: permission denied: practice
$ ls practice
ls: fts_read: Permission denied
$ chmod 755 practice
$ ls -ld practice
drwxr-xr-x@ 3 roy  staff  96 11월 17 11:14 practice
```

**관찰**: 디렉토리의 `x`는 "실행"이 아니라 "안으로 들어갈 수 있는 권한"이다. `x`를 빼자 `cd`와 `ls`가 모두 거부됐다. 755로 복구해 `drwxr-xr-x`로 돌아왔다.