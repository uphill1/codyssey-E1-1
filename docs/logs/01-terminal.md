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