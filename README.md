# DevTools - Kubernetes Helm Charts & Utilities

[![Helm Lint & Test](https://github.com/devhaucx/devtools/actions/workflows/lint.yml/badge.svg)](https://github.com/devhaucx/devtools/actions/workflows/lint.yml)
[![Release Charts](https://github.com/devhaucx/devtools/actions/workflows/release.yml/badge.svg)](https://github.com/devhaucx/devtools/actions/workflows/release.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Bộ sưu tập các **Helm Charts và công cụ DevOps chuẩn Kubernetes**, sẵn sàng cho môi trường production, tối ưu bảo mật và tự động hóa toàn diện từ đóng gói (packaging), xuất bản (releases) đến triển khai (deployments).

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

---

### Cách 3: Cài đặt từ mã nguồn (Local Source)

Clone repository và deploy trực tiếp qua thư mục chart:

```bash
# Cài đặt Azure Agent
helm upgrade --install azure-agent ./azure-agent-k8s/charts/azure-agent -n devops --create-namespace

# Cài đặt CronJob
helm upgrade --install cronjob ./cronjob-k8s/charts/cronjob -n devops --create-namespace
```

---

## 🛠️ Tự động hóa với Makefile

Dự án tích hợp `Makefile` hỗ trợ các tác vụ đóng gói, kiểm tra và release nhanh chóng:

```bash
# Kiểm tra cú pháp (lint) tất cả các charts
make lint

# Thử nghiệm render manifests (dry-run)
make template

# Đóng gói tất cả charts thành file .tgz vào thư mục .deploy/
make package

# Tạo hoặc cập nhật index.yaml cho Helm repository
make index

# Dọn dẹp các package và file tạm
make clean
```

---

## 🔄 CI/CD & Cơ chế Release tự động

Hệ thống GitHub Actions tự động hóa toàn diện quy trình:
1. **Lint & Test (`lint.yml`)**: Tự động kích hoạt khi có Pull Request hoặc Push để kiểm tra cú pháp và dry-run render template.
2. **Release Charts (`release.yml`)**:
   * Khi merge vào nhánh `main`, hệ thống tự động phát hiện chart có version mới.
   * Tự động đóng gói `.tgz` và tạo **GitHub Release** đính kèm package.
   * Cập nhật `index.yaml` và phát hành lên branch `gh-pages` (GitHub Pages).
   * Đẩy OCI package lên **GitHub Container Registry (GHCR)**.

---

## 🔒 Nguyên tắc Bảo mật (Security)

* **Zero Hardcoded Secrets**: Toàn bộ mật khẩu, tokens (Azure PAT, Database URI) được phân tách tuyệt đối và nạp độc lập qua Kubernetes Secrets.
* **Không lưu trữ file môi trường**: Tất cả file chứa mật khẩu (`.env`, `*.kubeconfig`) được chặn nghiêm ngặt bởi `.gitignore`.
* **Least Privilege**: Thiết lập `allowPrivilegeEscalation: false` và hạn chế tối đa đặc quyền container.

---

## 📄 License

Phát hành dưới giấy phép [MIT License](LICENSE).
