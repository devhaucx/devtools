# ==============================================================================
# DevTools - Helm Charts Automation Makefile
# Inspired by sun-asterisk-research/helm-charts
# ==============================================================================

SHELL := /bin/bash
PACKAGE_DIR ?= .deploy
HELM_URL ?= https://devhaucx.github.io/devtools

# Danh sách đường dẫn tới các charts
CHARTS := azure-agent-k8s/charts/azure-agent cronjob-k8s/charts/cronjob

.PHONY: all help lint template package index clean

all: help

help:
	@echo "DevTools Helm Charts Helper"
	@echo ""
	@echo "Sử dụng:"
	@echo "  make lint       - Chạy helm lint kiểm tra cú pháp toàn bộ charts"
	@echo "  make template   - Dry-run render Kubernetes manifests của các charts"
	@echo "  make package    - Đóng gói các charts thành file .tgz vào thư mục $(PACKAGE_DIR)"
	@echo "  make index      - Tạo/cập nhật index.yaml cho Helm repository (GitHub Pages)"
	@echo "  make clean      - Dọn dẹp thư mục $(PACKAGE_DIR) và các file tạm"
	@echo ""

lint:
	@echo "==> Kiểm tra cú pháp các Helm Charts..."
	@for chart in $(CHARTS); do \
		echo "--> Linting $$chart"; \
		helm lint $$chart || exit 1; \
	done
	@echo "==> Tất cả các charts đều hợp lệ!"

template:
	@echo "==> Render thử nghiệm manifests (dry-run)..."
	@helm template test-azure-agent azure-agent-k8s/charts/azure-agent > /dev/null
	@helm template test-cronjob cronjob-k8s/charts/cronjob > /dev/null
	@echo "==> Render thành công 100%!"

package: clean
	@echo "==> Đóng gói các charts thành file .tgz..."
	@mkdir -p $(PACKAGE_DIR)
	@for chart in $(CHARTS); do \
		echo "--> Packaging $$chart"; \
		helm package $$chart -d $(PACKAGE_DIR) || exit 1; \
	done
	@echo "==> Đã đóng gói xong vào $(PACKAGE_DIR)/:"
	@ls -la $(PACKAGE_DIR)/*.tgz

index: package
	@echo "==> Tạo index.yaml cho Helm Repo tại $(HELM_URL)..."
	@helm repo index $(PACKAGE_DIR) --url $(HELM_URL)
	@echo "==> Đã tạo xong index.yaml:"
	@head -n 25 $(PACKAGE_DIR)/index.yaml

clean:
	@echo "==> Dọn dẹp thư mục $(PACKAGE_DIR)..."
	@rm -rf $(PACKAGE_DIR) .cr-release-packages
