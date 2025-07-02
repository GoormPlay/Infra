#!/bin/bash

# FinOps 대시보드 자동 로드 스크립트
# 재부팅 후 모든 FinOps 대시보드를 Grafana에 자동으로 로드합니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Grafana 연결 대기
wait_for_grafana() {
    print_status "Grafana 서비스 대기 중..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001/api/health | grep -q "200"; then
            print_success "Grafana 서비스가 준비되었습니다!"
            return 0
        fi
        print_status "Grafana 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    print_error "Grafana 서비스에 연결할 수 없습니다."
    return 1
}

# Prometheus 데이터소스 설정
setup_prometheus_datasource() {
    print_status "Prometheus 데이터소스 설정 중..."
    
    curl -X POST -H "Content-Type: application/json" \
        -d '{
            "name": "Prometheus",
            "type": "prometheus", 
            "url": "http://prometheus-enhanced:9090",
            "access": "proxy",
            "isDefault": true
        }' \
        http://admin:admin123@localhost:3001/api/datasources 2>/dev/null || true
    
    print_success "Prometheus 데이터소스 설정 완료"
}

# 대시보드 로드 함수
load_dashboard() {
    local file_path="$1"
    local dashboard_name="$2"
    
    if [ ! -f "$file_path" ]; then
        print_error "대시보드 파일을 찾을 수 없습니다: $file_path"
        return 1
    fi
    
    print_status "로드 중: $dashboard_name"
    
    # 대시보드 JSON을 올바른 형식으로 래핑
    local response=$(curl -X POST -H "Content-Type: application/json" \
        -d "{\"dashboard\": $(cat "$file_path"), \"overwrite\": true}" \
        http://admin:admin123@localhost:3001/api/dashboards/db 2>/dev/null)
    
    if echo "$response" | grep -q "success"; then
        print_success "✅ $dashboard_name 로드 완료"
        return 0
    else
        print_error "❌ $dashboard_name 로드 실패"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        return 1
    fi
}

# 메인 실행
main() {
    print_status "🚀 FinOps 대시보드 자동 로드 시작"
    
    # Grafana 대기
    if ! wait_for_grafana; then
        exit 1
    fi
    
    # 데이터소스 설정
    setup_prometheus_datasource
    
    # 대시보드 디렉토리
    local dashboard_dir="/home/lch/GoormPlay/cost-monitoring/grafana/dashboards"
    
    # FinOps 대시보드 로드
    print_status "📊 FinOps 대시보드 로드 중..."
    
    load_dashboard "$dashboard_dir/finops-executive-dashboard.json" "FinOps Executive Dashboard"
    load_dashboard "$dashboard_dir/finops-cost-anomaly-detection.json" "FinOps Cost Anomaly Detection"
    load_dashboard "$dashboard_dir/finops-resource-optimization.json" "FinOps Resource Optimization"
    load_dashboard "$dashboard_dir/finops-unit-economics.json" "FinOps Unit Economics"
    load_dashboard "$dashboard_dir/finops-governance-compliance.json" "FinOps Governance & Compliance"
    load_dashboard "$dashboard_dir/finops-forecasting-planning.json" "FinOps Forecasting & Planning"
    load_dashboard "$dashboard_dir/finops-master-dashboard.json" "FinOps Master Dashboard"
    load_dashboard "$dashboard_dir/ultimate-finops-command-center.json" "🌟 Ultimate FinOps Command Center"
    
    # 기존 대시보드도 로드
    print_status "📈 기존 AWS 비용 대시보드 로드 중..."
    
    load_dashboard "$dashboard_dir/simple-cost-dashboard.json" "AWS Cost Monitoring"
    load_dashboard "$dashboard_dir/enhanced-aws-optimization-dashboard-fixed.json" "Enhanced AWS Optimization"
    load_dashboard "$dashboard_dir/working-aws-cost-dashboard.json" "Working AWS Cost Dashboard"
    
    print_success "🎉 모든 FinOps 대시보드 로드 완료!"
    print_status "📊 Grafana 접속: http://localhost:3001 (admin/admin123)"
    print_status "🌟 Ultimate FinOps Command Center: http://localhost:3001/d/a6eb1346-d3e3-4cef-b75f-217dc1043a3a/2653ac8"
}

# 스크립트 실행
main "$@"
