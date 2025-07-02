#!/bin/bash

# 완전한 관찰성 스택 배포 스크립트 (최종 수정 버전)
set -e

echo "🚀 Complete Observability Stack Deployment Starting..."

# 네임스페이스 생성
echo "📦 Creating observability namespace..."
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

# 1. RBAC 및 ServiceAccount 먼저 생성
echo "🔐 Creating RBAC and ServiceAccounts..."
kubectl apply -f prometheus-stack/rbac.yaml

# 2. 간단한 Prometheus 배포
echo "📊 Deploying Prometheus..."
kubectl apply -f prometheus-stack/simple-prometheus.yaml

# 3. Loki Stack 배포
echo "📄 Deploying Loki Stack..."
kubectl apply -f loki-stack/loki-deployment.yaml

# 4. Tempo Stack 배포
echo "🔗 Deploying Tempo Stack..."
kubectl apply -f tempo-stack/tempo-deployment.yaml

# 5. Fluent Bit 배포 (Grafana Stack에 포함되어 있으므로 생략)
echo "📝 Fluent Bit will be deployed as part of Grafana Stack..."
# kubectl apply -f fluent-bit/fluent-bit-daemonset.yaml

# 6. Test Applications 배포
echo "🧪 Deploying Test Applications..."
kubectl apply -f test-applications/enhanced-test-app.yaml
kubectl apply -f test-applications/traffic-generator.yaml

# 7. Grafana Stack 배포 (대시보드 포함)
echo "📈 Deploying Grafana Stack with Dashboards..."
cd grafana-stack
helm upgrade --install grafana-stack . -n observability --wait --timeout=10m
cd ..

# 배포 상태 확인
echo "⏳ Waiting for pods to be ready..."
sleep 30

echo "🔍 Checking deployment status..."
kubectl get pods -n observability

echo ""
echo "🎉 Complete Observability Stack Deployment Completed!"
echo ""
echo "📊 Access Information:"
export NODE_PORT=$(kubectl get --namespace observability -o jsonpath="{.spec.ports[0].nodePort}" services grafana-stack-grafana 2>/dev/null || echo "31000")
export NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}" 2>/dev/null || echo "localhost")
echo "Grafana URL: http://$NODE_IP:$NODE_PORT"
echo "Username: admin"
echo "Password: admin123"
echo ""
echo "🎯 Available Dashboards:"
echo "• Perfect Drill-Down Analysis Dashboard"
echo "• Incident Tracking & SLO Dashboard"
echo "• Advanced Drill-Down Dashboard"
echo "• Kubernetes Cluster Overview"
echo ""
echo "📈 Components Status:"
kubectl get pods -n observability --no-headers | awk '{print "• " $1 " - " $3}'
echo ""
echo "🔗 Quick Access Commands:"
echo "• Prometheus: kubectl port-forward -n observability svc/prometheus 9090:9090"
echo "• Loki: kubectl port-forward -n observability svc/loki 3100:3100"
echo "• Tempo: kubectl port-forward -n observability svc/tempo 3200:3200"
echo "• Grafana: kubectl port-forward -n observability svc/grafana-stack-grafana 3000:3000"
