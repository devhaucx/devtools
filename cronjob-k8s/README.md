# Kubernetes CronJobs - Helm Chart

Helm Chart đa năng, tinh gọn và an toàn để định nghĩa và quản lý các **Kubernetes CronJobs / Batch Jobs** trên Kubernetes.

Tích hợp sẵn cơ chế **tự động kill và dọn dẹp Pod** ngay khi hoàn thành (`ttlSecondsAfterFinished: 0`), triệt tiêu hoàn toàn tình trạng kẹt ở `Completed` hoặc `Terminating`, hỗ trợ nạp cấu hình nhạy cảm qua **Kubernetes Secret được tạo độc lập từ file `.env`**.

---

## 📋 Yêu cầu hệ thống (Prerequisites)

* Cụm Kubernetes v1.24+ (khuyến nghị v1.27+ để hỗ trợ múi giờ `timeZone`)
* Helm v3.0+

---

## ⚙️ Cấu hình biến môi trường (`.env`)

File `.env` chứa các thông tin kết nối và cấu hình bảo mật được nạp vào Kubernetes Secret:

| Biến môi trường | Mô tả | Ví dụ |
| :--- | :--- | :--- |
| `DATABASE_URL` | Chuỗi kết nối Database | `mongodb+srv://user:password@cluster/db` |
| `REDIS_URL` | URL kết nối Redis | `redis://:password@redis-master:6379/0` |
| `API_KEY` | Token hoặc API Key bí mật | `xxxxxxxxxxxxxxxxxxxxxxxx` |

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
   kubectl create secret generic cronjob-secret \
     --from-env-file=.env \
     --namespace <your-namespace>
   ```

---

### Bước 2: Triển khai bằng Helm

Triển khai chart mặc định:

```bash
helm upgrade --install cronjob ./charts/cronjob \
  --namespace <your-namespace> \
  --create-namespace
```

Nếu bạn có file cấu hình values tùy chỉnh định nghĩa các jobs riêng:

```bash
helm upgrade --install cronjob ./charts/cronjob \
  --namespace <your-namespace> \
  --create-namespace \
  -f my-jobs.yaml
```

---

### Bước 3: Kiểm tra trạng thái và Logs

1. Kiểm tra danh sách CronJobs:
   ```bash
   kubectl get cronjob -n <your-namespace>
   ```

2. Kích hoạt chạy thử thủ công một Job:
   ```bash
   kubectl create job test-run --from=cronjob/<cronjob-name> -n <your-namespace>
   ```

3. Theo dõi log của Job:
   ```bash
   kubectl logs -n <your-namespace> job/test-run -f
   ```

*(Ngay sau khi chạy xong, Pod và Job sẽ tự động bị K8s dọn dẹp biến mất lập tức, không để lại rác trên cụm).*

---

## 💡 Các ví dụ cấu hình thực tế (Examples)

Dưới đây là các kịch bản thực tế phổ biến khi sử dụng chart:

### 1. Ví dụ cơ bản: Gọi API Healthcheck định kỳ
Một cronjob nhẹ nhàng sử dụng image `curl` để ping API giám sát mỗi 15 phút:

```yaml
jobs:
  healthcheck-ping:
    schedule: "*/15 * * * *" # Mỗi 15 phút
    image:
      repository: "curlimages/curl"
      tag: "8.6.0"
    command: ["curl"]
    args: ["-fsS", "-m", "10", "https://api.example.com/healthz"]
```

### 2. Ví dụ Worker/Dọn dẹp DB: Nạp Secret kết nối & Giới hạn CPU/RAM
Job chạy lúc **01:00 AM** mỗi ngày, tự động nạp `DATABASE_URL` từ Kubernetes Secret `cronjob-secret`:

```yaml
# Nạp toàn bộ biến môi trường từ Kubernetes Secret có sẵn
extraEnvFrom:
  - secretRef:
      name: cronjob-secret

jobs:
  daily-db-cleanup:
    schedule: "0 1 * * *" # 01:00 AM hàng ngày
    image:
      repository: "python"
      tag: "3.11-slim"
    command: ["python", "-c"]
    args:
      - |
        import os
        print("Đang kết nối database và dọn dẹp dữ liệu cũ...")
        print("Hoàn tất dọn dẹp!")
    resources:
      requests:
        cpu: "250m"
        memory: "256Mi"
      limits:
        cpu: "1000m"
        memory: "1Gi"
```

### 3. Ví dụ Crawler / Data Processing: Chạy đa Pod song song (`parallelism`)
Job crawl hoặc xử lý dữ liệu chạy vào lúc **02:00 AM Chủ Nhật hàng tuần**, chia việc cho **3 Pods chạy đồng thời** để xử lý nhanh:

```yaml
extraEnvFrom:
  - secretRef:
      name: cronjob-secret

jobs:
  weekly-data-sync:
    schedule: "0 2 * * 0" # 02:00 AM mỗi Chủ Nhật
    image:
      repository: "my-registry.com/crawlers/data-sync"
      tag: "v1.2.0"
    command: ["python", "sync_data.py"]
    parallelism: 3             # Chạy đồng thời 3 Pods cùng lúc
    activeDeadlineSeconds: 7200 # Cho phép chạy tối đa 2 tiếng (quá hạn tự kill)
    env:
      - name: BATCH_SIZE
        value: "500"
```

### 4. Triển khai file cấu hình tùy chỉnh
Lưu cấu hình job của bạn vào file `my-jobs.yaml`, sau đó triển khai:
```bash
helm upgrade --install my-cronjobs ./charts/cronjob \
  --namespace devops \
  --create-namespace \
  -f my-jobs.yaml
```

---

## 🛠️ Danh sách tham số cấu hình (`values.yaml`)

| Tham số | Mặc định | Mô tả |
| :--- | :--- | :--- |
| `image.repository` | `busybox` | Image mặc định dùng chung cho các job |
| `image.tag` | `latest` | Tag image mặc định |
| `jobDefaults.ttlSecondsAfterFinished` | `0` | Xóa Pod & Job ngay lập tức khi xong (chống kẹt `Completed`) |
| `jobDefaults.terminationGracePeriodSeconds` | `0` | Force terminate ngay lập tức, không chờ đợi (chống kẹt `Terminating`) |
| `jobDefaults.successfulJobsHistoryLimit` | `0` | Không giữ lại Pod `Completed` nào trong lịch sử |
| `jobDefaults.failedJobsHistoryLimit` | `1` | Số lượng job lỗi lưu lại để kiểm tra log |
| `jobDefaults.activeDeadlineSeconds` | `1800` | Giới hạn thời gian tối đa chạy (30 phút); quá hạn tự động kill |
| `jobDefaults.backoffLimit` | `1` | Số lần thử lại tối đa khi job thất bại rồi dừng dứt khoát |
| `jobDefaults.restartPolicy` | `Never` | Chính sách restart container (tránh vòng lặp CrashLoop) |
| `jobDefaults.timeZone` | `Asia/Ho_Chi_Minh` | Múi giờ chạy cronjob |
| `resources` | *100m/128Mi - 500m/512Mi* | Hạn mức CPU / RAM mặc định cho các jobs |
| `extraEnvFrom` | `[]` | Nạp biến môi trường bảo mật từ Kubernetes Secret có sẵn |
| `jobs` | `example-task` | Danh sách các CronJobs |
