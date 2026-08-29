# ============================================
# 多阶段构建 (Multi-stage Build)
# 阶段 1: 编译 Go 应用
# 阶段 2: 运行时只保留二进制文件
# ============================================

# --- Build Stage ---
FROM golang:1.22-alpine AS builder

# 安装 git（Go modules 需要）
RUN apk add --no-cache git

WORKDIR /app

# 先复制 go.mod/go.sum，利用 Docker 层缓存
COPY go.mod go.sum* ._
RUN if [ -f go.sum ]; then go mod download; fi

# 复制源码并编译
COPY . .
ARG VERSION=dev
ARG GIT_COMMIT=unknown
ARG BUILD_TIME=unknown

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags "-s -w \
    -X main.Version=${VERSION} \
    -X main.GitCommit=${GIT_COMMIT} \
    -X main.BuildTime=${BUILD_TIME}" \
    -o /app/server .

# --- Runtime Stage ---
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY --from=builder /app/server .

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/health || exit 1

ENTRYPOINT ["./server"]
