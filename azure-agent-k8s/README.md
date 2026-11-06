# Azure DevOps Self-Hosted Agent on Kubernetes (DinD Sidecar) - Helm Chart

Helm Chart để triển khai cụm **Azure DevOps / Azure DevOps Server (TFS) Self-Hosted Agents** trên Kubernetes, tích hợp **Docker-in-Docker (DinD)** sidecar cho phép build, push container images và triển khai ứng dụng bằng Helm/Kubectl trực tiếp từ agent pod.

Cấu hình nhạy cảm (`AZP_URL`, `AZP_TOKEN`, `AZP_POOL`) được phân tách an toàn và nạp qua **Kubernetes Secret được tạo độc lập từ file `.env`**.

---

## 📋 Yêu cầu hệ thống (Prerequisites)

* Cụm Kubernetes v1.24+
* Helm v3.0+
* Personal Access Token (PAT) trên Azure DevOps với quyền `Agent Pools (Read & manage)`
* Agent Pool đã được tạo sẵn trên Azure DevOps

---

## ⚙️ Cấu hình biến môi trường (`.env`)

File `.env` chứa các thông tin kết nối tới Azure DevOps:

| Biến môi trường | Mô tả | Ví dụ |
| :--- | :--- | :--- |
| `AZP_URL` | URL tổ chức Azure DevOps hoặc TFS Collection | `https://dev.azure.com/<organization>` |
| `AZP_TOKEN` | Personal Access Token (PAT) | `xxxxxxxxxxxxxxxxxxxxxxxx` |
| `AZP_POOL` | Tên Agent Pool đã tạo | `my-agent-pool` |

---

## 🚀 Hướng dẫn triển khai

### Bước 1: Tạo file `.env` và Kubernetes Secret

1. Tạo file `.env` từ mẫu:
   ```bash
   cp .env.example .env
   ```

2. Cập nhật các giá trị thực tế của bạn vào file `.env`.

3. Tạo Kubernetes Secret bằng tay từ file `.env`:
   ```bash
   kubectl create secret generic azure-agent-secret \
     --from-env-file=.env \
     --namespace <your-namespace>
   ```

---

### Bước 2: Triển khai bằng Helm

Triển khai chart và truyền các thông tin image / registry của bạn qua cờ `--set`:

```bash
helm upgrade --install azure-agent ./charts/azure-agent \
  --namespace <your-namespace> \
  --create-namespace \
  --set agent.image.repository=<your-registry>/<your-agent-image> \
  --set agent.image.tag=<your-tag> \
  --set imagePullSecrets[0].name=<your-image-pull-secret>
```

Nếu bạn không sử dụng Private Registry hoặc image là Public, có thể bỏ qua cờ `imagePullSecrets`:

```bash
helm upgrade --install azure-agent ./charts/azure-agent \
  --namespace <your-namespace> \
  --create-namespace \
  --set agent.image.repository=<your-agent-image> \
  --set agent.image.tag=<your-tag>
```

---

### Bước 3: Kiểm tra trạng thái và Logs

1. Kiểm tra trạng thái Pods:
   ```bash
   kubectl get pods -n <your-namespace>
   ```

2. Theo dõi log khởi động của Azure Pipelines Agent:
   ```bash
   kubectl logs -n <your-namespace> <pod-name> -c azp-agent -f
   ```

3. Theo dõi log của Docker daemon (DinD sidecar):
   ```bash
   kubectl logs -n <your-namespace> <pod-name> -c dind -f
   ```

---

### Bước 4: Cấu hình Pipeline Azure DevOps

Trong file pipeline (`azure-pipelines.yml`) của dự án, chỉ định tên Agent Pool tương ứng:

```yaml
pool:
  name: <your-agent-pool>

steps:
  - script: |
      docker build -t my-app:latest .
      echo "Build hoàn tất trực tiếp trên K8s DinD Agent!"
    displayName: "Build image trên Self-Hosted Agent"
```

---

## 🛠️ Danh sách tham số cấu hình (`values.yaml`)

| Tham số | Mặc định | Mô tả |
| :--- | :--- | :--- |
| `global.imageRegistry` | `""` | Registry dùng chung cấp global |
| `global.imagePullSecrets` | `[]` | Mảng pull secrets cấp global |
| `imagePullSecrets` | `[]` | Danh sách image pull secrets dùng kéo image agent |
| `replicaCount` | `2` | Số lượng Agent Pods chạy đồng thời |
| `fullnameOverride` | `k8s-agent` | Tên gốc của StatefulSet và Headless Service |
| `secret.name` | `azure-agent-secret` | Tên Secret K8s chứa URL, Token, Pool |
| `serviceAccount.name` | `admin` | Tên ServiceAccount được gán cho Pod |
| `agent.image.repository` | `azure-agent` | Repository image Agent |
| `agent.image.tag` | `1.0.0` | Tag image Agent |
| `agent.agentNamePrefix` | `K8S-AGENT` | Tiền tố tên Agent hiển thị trên Azure DevOps |
| `agent.resources` | *500m/512Mi - 2000m/2Gi* | Giới hạn CPU / RAM cho Agent |
| `dind.enabled` | `true` | Bật/tắt Docker-in-Docker sidecar |
| `dind.autoPrune.enabled` | `true` | Bật/tắt dọn dẹp cache Docker thừa định kỳ |
| `dind.autoPrune.intervalSeconds` | `1800` | Chu kỳ tự dọn dẹp (giây) |
| `kubeconfig.enabled` | `true` | Mount secret Kubeconfig vào container để deploy K8s |
| `kubeconfig.secretName` | `kubeconfig` | Tên Kubernetes Secret chứa Kubeconfig |
| `nightlyRestart.enabled` | `true` | Bật/tắt CronJob restart pod ban đêm |
| `nightlyRestart.schedule` | `0 2 * * *` | Lịch chạy CronJob restart (02:00 AM) |

