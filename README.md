# Go CI/CD Demo - GitHub Actions + ArgoCD 完整练手项目

一个完整的 CI/CD 学习项目，涵盖 **GitHub Actions (CI+CD)** + **ArgoCD (GitOps)** 的全流程。

## 📐 架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline 完整流程                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  开发者 push ──→ GitHub Actions CI ──→ GitHub Actions CD         │
│                      │                      │                    │
│              ┌───────┴───────┐      ┌───────┴───────┐           │
│              │  1. go test   │      │  1. docker    │           │
│              │  2. golangci  │      │     build+push│           │
│              │     -lint     │      │  2. 更新 k8s  │           │
│              │  3. docker    │      │     manifests │           │
│              │     build     │      │  3. 创建      │           │
│              └───────────────┘      │     Release   │           │
│                                     └───────┬───────┘           │
│                                             │                    │
│                                     go-cicd-deploy 仓库更新       │
│                                             │                    │
│                                      ArgoCD 检测变更              │
│                                             │                    │
│                                      自动同步到 K8s               │
│                                             │                    │
│                                        🚀 部署完成               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🗂️ 项目结构

```
go-cicd-demo/
├── main.go                          # Go Web 应用 (健康检查 + Hello API)
├── main_test.go                     # 单元测试
├── go.mod                           # Go 模块定义
├── Dockerfile                       # 多阶段 Docker 构建
├── .github/workflows/
│   ├── ci.yml                       # CI: test → lint → build image
│   └── cd.yml                       # CD: tag → release → update manifests
├── k8s/
│   ├── namespace.yaml               # K8s Namespace
│   ├── deployment.yaml              # K8s Deployment (滚动更新)
│   ├── service.yaml                 # K8s Service (ClusterIP)
│   └── kustomization.yaml           # Kustomize 配置
└── argocd/
    ├── application.yaml             # ArgoCD Application 资源
    └── README.md                    # ArgoCD 安装说明
```

## 🚀 快速开始

### 前置条件

- GitHub 账号
- K8s 集群 (minikube/kind/k3s/云集群 都行)
- kubectl CLI

### Step 1: 创建 GitHub 仓库

```bash
# 在 GitHub 创建仓库 go-cicd-demo
cd go-cicd-demo
git init
git add .
git commit -m "feat: initial CI/CD demo project"
git remote add origin git@github.com:YOUR_USER/go-cicd-demo.git
git push -u origin main
```

### Step 2: 触发 CI

```bash
# 做一次修改，push 触发 CI
echo "# test" >> README.md
git add . && git commit -m "test: trigger CI" && git push
```

去 GitHub → Actions 页面查看运行状态。

### Step 3: 触发 CD

```bash
# 打 tag 触发 CD
git tag v1.0.0
git push origin v1.0.0
```

### Step 4: 安装 ArgoCD (在 K8s 集群上)

参考 `argocd/README.md`

## 📖 学习路线

| 阶段 | 内容 | 验证方式 |
|------|------|---------|
| 1️⃣ 本地运行 | `go run main.go` | curl localhost:8080/health |
| 2️⃣ Docker 构建 | `docker build -t demo . && docker run -p 8080:8080 demo` | 同上 |
| 3️⃣ CI 流程 | push 代码，查看 GitHub Actions | Actions 页面绿勾 |
| 4️⃣ CD 流程 | 打 tag，镜像自动构建并推送 | GHCR 看到新镜像 |
| 5️⃣ K8s 部署 | `kubectl apply -f k8s/` | kubectl get pods |
| 6️⃣ GitOps | 安装 ArgoCD，创建 Application | ArgoCD UI 看到同步状态 |

## 🔑 GitHub Secrets 配置

在仓库 Settings → Secrets and variables → Actions 中添加：

| Secret | 说明 | 获取方式 |
|--------|------|---------|
| `GITHUB_TOKEN` | 自动提供，无需配置 | 用于推送 Docker 镜像到 GHCR |
| `DEPLOY_TOKEN` | 部署仓库的写权限 Token | 创建 PAT (repo scope) |

## 💡 关键知识点

### CI vs CD 的区别

```
CI (持续集成):  代码变更 → 自动构建 + 测试 → 保证代码质量
CD (持续交付):  通过 CI → 自动构建镜像 → 随时可部署
CD (持续部署):  通过 CI → 自动部署到生产环境
```

### GitOps 的核心思想

```
传统方式:  kubectl apply → 直接操作集群
GitOps:    Git 变更 → ArgoCD 检测 → 自动同步到集群

优点:
- Git 是唯一真相源 (Single Source of Truth)
- 所有变更可审计 (谁改了什么、什么时候改的)
- 自动修复漂移 (有人手动改了? ArgoCD 自动改回来)
- 回滚就是 revert commit
```

### GitHub Actions 关键概念

```yaml
# Workflow: 一个完整的自动化流程
# Job:     一个阶段 (如 test、lint、build)
# Step:    Job 中的一个步骤
# Action:  可复用的步骤 (如 actions/checkout@v4)
# Runner:  执行 Job 的机器 (GitHub 提供或自托管)
```
