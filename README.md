# DevTools - Kubernetes Helm Charts & Utilities

[![Helm Lint & Test](https://github.com/devhaucx/devtools/actions/workflows/lint.yml/badge.svg)](https://github.com/devhaucx/devtools/actions/workflows/lint.yml)
[![Release Charts](https://github.com/devhaucx/devtools/actions/workflows/release.yml/badge.svg)](https://github.com/devhaucx/devtools/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

*My dev tools**

---

## 📦 Danh sách Helm Charts

| Chart | Version | Mô tả | Chi tiết |
| :--- | :--- | :--- | :--- |
| **`azure-agent`** | `0.1.0` | Azure DevOps / TFS Self-Hosted Agent tích hợp Docker-in-Docker (DinD) sidecar. Build, push container và deploy trực tiếp trên K8s pod. | [README](./azure-agent-k8s/README.md) |
| **`cronjob`** | `0.1.0` | Kubernetes CronJobs đa năng. Tự động xóa sạch Pod/Job ngay khi hoàn thành (`ttl: 0`), triệt tiêu hoàn toàn kẹt ở `Completed` / `Terminating`. | [README](./cronjob-k8s/README.md) |

---

## 🚀 Các cách cài đặt Charts

### Cách 1: Sử dụng Helm Repository (Khuyên dùng)

Thêm repository được lưu trữ tự động trên **GitHub Pages**:

```bash
helm repo add devtools https://devhaucx.github.io/devtools
helm repo update
```

Tìm kiếm các charts có sẵn:
```bash
helm search repo devtools
```

Cài đặt chart mong muốn:
```bash
# Cài đặt Azure DevOps Agent
helm install my-agent devtools/azure-agent -n devops --create-namespace

# Cài đặt CronJob
helm install my-cronjob devtools/cronjob -n devops --create-namespace
```

---

### Cách 2: Sử dụng OCI Registry (GitHub Container Registry - GHCR)

Các chart được tự động đóng gói và xuất bản dưới dạng OCI Artifacts trên **GHCR**:

```bash
# Cài đặt trực tiếp qua OCI
helm install my-agent oci://ghcr.io/devhaucx/devtools/azure-agent --version 0.1.0 -n devops --create-namespace
helm install my-cronjob oci://ghcr.io/devhaucx/devtools/cronjob --version 0.1.0 -n devops --create-namespace
```

