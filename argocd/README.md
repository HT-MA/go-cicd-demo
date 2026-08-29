# ArgoCD 部署指南

## 快速安装 ArgoCD

### 1. 安装 ArgoCD (K8s 集群上)

```bash
# 创建 namespace
kubectl create namespace argocd

# 安装 ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 等待所有 Pod 就绪
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# 获取初始 admin 密码
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

### 2. 访问 ArgoCD Web UI

```bash
# 端口转发
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 浏览器打开 https://localhost:8080
# 用户名: admin
# 密码: 上面获取的初始密码
```

### 3. 使用 ArgoCD CLI

```bash
# 安装 CLI (Linux)
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd && sudo mv argocd /usr/local/bin/

# 登录
argocd login localhost:8080 --username admin --password <密码>

# 创建 Application
kubectl apply -f argocd/application.yaml

# 或者用 CLI 创建
argocd app create go-cicd-demo \
  --repo https://github.com/YOUR_ORG/go-cicd-deploy.git \
  --path k8s \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace go-cicd-demo \
  --sync-policy automated \
  --auto-prune \
  --self-heal
```

## GitOps 工作流

```
开发者 push 代码
       ↓
GitHub Actions CI 运行 (test + lint + build)
       ↓
推送 Docker 镜像到 GHCR
       ↓
push tag (v1.0.0) 触发 CD Pipeline
       ↓
CD 更新 go-cicd-deploy 仓库的 kustomization.yaml
       ↓
ArgoCD 检测到 Git 变更 (30秒轮询)
       ↓
ArgoCD 自动同步到 K8s 集群
       ↓
滚动更新完成 ✅
```

## 常用 ArgoCD 命令

```bash
# 查看应用状态
argocd app get go-cicd-demo

# 手动触发同步
argocd app sync go-cicd-demo

# 查看同步历史
argocd app history go-cicd-demo

# 回滚到上一版本
argocd app rollback go-cicd-demo 1

# 查看资源差异
argocd app diff go-cicd-demo
```

## 部署仓库结构 (go-cicd-deploy)

```
go-cicd-deploy/
├── k8s/
│   ├── namespace.yaml
│   ├── deployment.yaml    # 镜像 tag 由 CI/CD 自动更新
│   ├── service.yaml
│   └── kustomization.yaml
└── README.md
```
