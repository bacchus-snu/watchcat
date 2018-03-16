# Watchcat

> Monitoring tool for SNUCSE Machines

## Features
* 주기적인 metric 수집
* metric을 보는 API
* machine을 추가, 삭제, 수정하는 API
* remote command (replace `bdo`)

## 구성요소

* 서버
* 클라이언트
* 프론트엔드

## 사용 방법

### 서버

```bash
git clone https://github.com/bacchus-snu/watchcat.git
cd watchcat/apps/server
vim config/config.exs

mix start --no-halt
```

### watchcat.bacchus.snucse.org에 deploy

```bash
git push bacchus@watchcat.bacchus.snucse.org:watchcat.git master
# git hook will be triggered...
```

### 클라이언트
```bash
sudo apt install watchcat-client
```
**주의: bacchus-lab ppa가 추가되어 있어야 함.**

## 보안

모든 연결은 SSL 연결을 사용한다.

### Client side
* 최초 시작 시에 randomly generated certificate, private key pair을 생성
* key pair은 `root:root 400`으로 보호됨
* Server의 certificate가 `Let's Encrypt`의 Intermediate CA에 의해 Sign 되었는지 체크
* Server의 certificate의 domain name이 `watchcat.bacchus.snucse.org`인지 체크

### Server side
* 최초 실행 시에 randomly generated secret key를 생성
* 이 secret key에 기반한 token으로 REST API의 authentication을 수행
* 최초 Machine 추가 시에 Client certificate의 fingerprint를 저장
* 클라이언트의 연결을 fingerprint로 validation
