#!/bin/bash

# 완전한 관찰성 스택 정리 스크립트 (완전 버전)
set -e

echo "🧹 Complete Observability Stack Cleanup Starting..."

# 현재 디렉토리 저장
ORIGINAL_DIR=$(pwd)

# Helm 릴리스 확인 및 제거
echo "🎯 Checking and removing Helm releases..."
HELM_RELEASES=$(helm list -n observability -q 2>/dev/null || true)
if [ ! -z "$HELM_RELEASES" ]; then
    echo "Found Helm releases: $HELM_RELEASES"
    for release in $HELM_RELEASES; do
        echo "📦 Removing Helm release: $release"
        helm uninstall $release -n observability || true
    done
else
    echo "✅ No Helm releases found in observability namespace"
fi

# Grafana Stack 제거 (Helm) - 백업 방법
echo "📈 Removing Grafana Stack (backup method)..."
if [ -d "grafana-stack" ]; then
    cd grafana-stack
    helm uninstall grafana-stack -n observability || true
    cd "$ORIGINAL_DIR"
fi

# Loki Stack 제거 (Helm) - 새로 추가
echo "📄 Removing Loki Stack (Helm)..."
if [ -d "loki-stack" ]; then
    cd loki-stack
    helm uninstall loki-stack -n observability || true
    cd "$ORIGINAL_DIR"
fi

# Test Applications 제거
echo "🧪 Removing Test Applications..."
kubectl delete -f test-applications/enhanced-test-app.yaml --ignore-not-found=true || true
kubectl delete -f test-applications/traffic-generator.yaml --ignore-not-found=true || true
kubectl delete -f test-applications/test-app-deployment.yaml --ignore-not-found=true || true

# Fluent Bit 제거 (독립 버전)
echo "📝 Removing Fluent Bit..."
kubectl delete -f fluent-bit/fluent-bit-daemonset.yaml --ignore-not-found=true || true

# Tempo Stack 제거
echo "🔗 Removing Tempo Stack..."
kubectl delete -f tempo-stack/tempo-deployment.yaml --ignore-not-found=true || true

# Loki Stack 제거 (독립 YAML 파일)
echo "📄 Removing Loki Stack (YAML files)..."
kubectl delete -f loki-stack/loki-deployment.yaml --ignore-not-found=true || true

# Prometheus Stack 제거 (독립 버전)
echo "📊 Removing Prometheus Stack..."
kubectl delete -f prometheus-stack/simple-prometheus.yaml --ignore-not-found=true || true

# RBAC 제거
echo "🔐 Removing RBAC and ServiceAccounts..."
kubectl delete -f prometheus-stack/rbac.yaml --ignore-not-found=true || true

# 기존 Prometheus Stack 리소스 강제 제거
echo "🔨 Force removing remaining Prometheus resources..."
kubectl delete deployment prometheus-stack-prometheus -n observability --ignore-not-found=true --force --grace-period=0 || true
kubectl delete deployment prometheus-stack-kube-state-metrics -n observability --ignore-not-found=true --force --grace-period=0 || true
kubectl delete daemonset prometheus-stack-node-exporter -n observability --ignore-not-found=true --force --grace-period=0 || true
kubectl delete deployment prometheus -n observability --ignore-not-found=true --force --grace-period=0 || true

# Loki Stack 관련 리소스 강제 제거 - 새로 추가
echo "🔨 Force removing Loki Stack resources..."
kubectl delete deployment loki-stack-loki -n observability --ignore-not-found=true --force --grace-period=0 || true
kubectl delete daemonset loki-stack-fluent-bit -n observability --ignore-not-found=true --force --grace-period=0 || true
kubectl delete deployment loki -n observability --ignore-not-found=true --force --grace-period=0 || true
kubectl delete daemonset fluent-bit -n observability --ignore-not-found=true --force --grace-period=0 || true

# 모든 Pod 강제 제거
echo "💀 Force removing all pods in observability namespace..."
kubectl delete pods --all -n observability --force --grace-period=0 || true

# 모든 ReplicaSet 제거
echo "🗑️ Removing all ReplicaSets..."
kubectl delete replicaset --all -n observability --ignore-not-found=true || true

# 모든 Deployment 제거 (추가 보완)
echo "🚀 Removing all Deployments..."
kubectl delete deployment --all -n observability --ignore-not-found=true || true

# 모든 DaemonSet 제거 (추가 보완)
echo "👥 Removing all DaemonSets..."
kubectl delete daemonset --all -n observability --ignore-not-found=true || true

# 모든 ConfigMap 제거
echo "📋 Removing all ConfigMaps..."
kubectl delete configmap --all -n observability --ignore-not-found=true || true

# 모든 Service 제거
echo "🔗 Removing all Services..."
kubectl delete service --all -n observability --ignore-not-found=true || true

# 모든 ServiceAccount 제거 (추가 보완)
echo "👤 Removing all ServiceAccounts..."
kubectl delete serviceaccount --all -n observability --ignore-not-found=true || true

# 모든 PVC 제거
echo "💾 Removing all PVCs..."
kubectl delete pvc --all -n observability --ignore-not-found=true || true

# ClusterRole 및 ClusterRoleBinding 제거 (보완)
echo "🌐 Removing Cluster-level resources..."
kubectl delete clusterrole prometheus-stack-prometheus --ignore-not-found=true || true
kubectl delete clusterrole prometheus-stack-kube-state-metrics --ignore-not-found=true || true
kubectl delete clusterrole fluent-bit-read --ignore-not-found=true || true
kubectl delete clusterrole fluent-bit --ignore-not-found=true || true
kubectl delete clusterrolebinding prometheus-stack-prometheus --ignore-not-found=true || true
kubectl delete clusterrolebinding prometheus-stack-kube-state-metrics --ignore-not-found=true || true
kubectl delete clusterrolebinding fluent-bit-read --ignore-not-found=true || true
kubectl delete clusterrolebinding fluent-bit --ignore-not-found=true || true

# 추가 정리 - 남아있을 수 있는 리소스들
echo "🧽 Additional cleanup for remaining resources..."
kubectl delete statefulset --all -n observability --ignore-not-found=true || true
kubectl delete job --all -n observability --ignore-not-found=true || true
kubectl delete cronjob --all -n observability --ignore-not-found=true || true

# Finalizer가 있는 리소스들 강제 정리
echo "⚡ Force cleaning resources with finalizers..."
kubectl patch pvc --all -n observability -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
kubectl patch pods --all -n observability -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true

# 네임스페이스 제거 확인
echo "📦 Checking observability namespace..."
read -p "Do you want to remove the observability namespace? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "⏳ Waiting for resources to be fully deleted..."
    sleep 15
    
    # Finalizer 제거 후 네임스페이스 삭제
    kubectl patch namespace observability -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
    kubectl delete namespace observability --ignore-not-found=true --force --grace-period=0 || true
    echo "✅ Namespace removed"
else
    echo "⏭️ Namespace kept"
fi

echo ""
echo "🎉 Complete Observability Stack Cleanup Completed!"
echo ""
echo "🔍 Final check - Remaining resources in observability namespace:"
kubectl get all -n observability 2>/dev/null || echo "✅ No resources found or namespace doesn't exist"

echo ""
echo "🔍 Checking for any remaining pods with prometheus in name:"
kubectl get pods --all-namespaces | grep prometheus 2>/dev/null || echo "✅ No prometheus pods found"

echo ""
echo "🔍 Checking for any remaining pods with loki in name:"
kubectl get pods --all-namespaces | grep loki 2>/dev/null || echo "✅ No loki pods found"

echo ""
echo "🔍 Checking for any remaining pods with fluent-bit in name:"
kubectl get pods --all-namespaces | grep fluent 2>/dev/null || echo "✅ No fluent-bit pods found"

echo ""
echo "🔍 Checking remaining Helm releases:"
helm list --all-namespaces | grep -E "(loki|grafana|prometheus)" 2>/dev/null || echo "✅ No monitoring-related Helm releases found"

echo ""
echo "✨ Cleanup completed successfully!"
