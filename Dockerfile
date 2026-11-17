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
