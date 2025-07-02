#!/bin/bash

# FinOps 시스템 자동 시작 스크립트
# 재부팅 후 완전한 시스템 복구를 보장합니다.

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

# 환경 확인
check_environment() {
    print_status "환경 설정 확인 중..."
    
    if [ ! -f ".env" ]; then
        print_error ".env 파일이 없습니다!"
        exit 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml 파일이 없습니다!"
        exit 1
    fi
    
    print_success "환경 설정 확인 완료"
}

# 시스템 시작
start_system() {
    print_status "FinOps 시스템 시작 중..."
    
    # 기존 컨테이너 정리
    docker-compose --env-file .env down 2>/dev/null || true
    
    # 시스템 시작
    docker-compose --env-file .env up -d
    
    print_success "시스템 시작 완료"
}

# 서비스 상태 확인
wait_for_services() {
    print_status "서비스 준비 상태 확인 중..."
    
    # Grafana 대기
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:3001/api/health > /dev/null 2>&1; then
            print_success "Grafana 서비스 준비 완료!"
            break
        fi
        print_status "Grafana 대기 중... ($attempt/$max_attempts)"
        sleep 5
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        print_error "Grafana 서비스 시작 실패"
        return 1
    fi
    
    # Prometheus 대기
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:9091/api/v1/status/config > /dev/null 2>&1; then
            print_success "Prometheus 서비스 준비 완료!"
            break
        fi
        print_status "Prometheus 대기 중... ($attempt/$max_attempts)"
        sleep 3
        ((attempt++))
    done
    
    # Cost Collector 대기
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:5000/health > /dev/null 2>&1; then
            print_success "Cost Collector 서비스 준비 완료!"
            break
        fi
        print_status "Cost Collector 대기 중... ($attempt/$max_attempts)"
        sleep 3
        ((attempt++))
    done
}

# 데이터 수집 확인
verify_data_collection() {
    print_status "데이터 수집 상태 확인 중..."
    
    sleep 10  # 데이터 수집 대기
    
    local metric_count=$(curl -s http://localhost:8080/metrics | grep "aws_cost_total{" | wc -l)
    
    if [ "$metric_count" -gt 0 ]; then
        print_success "AWS 비용 데이터 수집 중 (${metric_count}개 서비스)"
    else
        print_warning "데이터 수집이 아직 시작되지 않았습니다. 잠시 후 다시 확인하세요."
    fi
    
    # Prometheus에서 데이터 확인
    local total_cost=$(curl -s "http://localhost:9091/api/v1/query?query=sum(aws_cost_total)" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
    
    if [ "$total_cost" != "0" ] && [ "$total_cost" != "null" ]; then
        print_success "총 AWS 비용: \$${total_cost}"
    fi
}

# 대시보드 상태 확인
verify_dashboards() {
    print_status "대시보드 상태 확인 중..."
    
    local dashboard_count=$(curl -s http://admin:admin123@localhost:3001/api/search | jq '. | length' 2>/dev/null || echo "0")
    
    if [ "$dashboard_count" -gt 0 ]; then
        print_success "${dashboard_count}개 대시보드 로드됨"
    else
        print_warning "대시보드가 로드되지 않았습니다."
    fi
}

# 메인 실행
main() {
    print_status "🚀 FinOps 시스템 자동 시작"
    
    check_environment
    start_system
    wait_for_services
    verify_data_collection
    verify_dashboards
    
    print_success "🎉 FinOps 시스템 시작 완료!"
    print_status "📊 Grafana 접속: http://localhost:3001 (admin/admin123)"
    print_status "🔄 Reboot-Safe Dashboard: http://localhost:3001/d/7614c43e-6660-42dc-b75c-48bf61607ea4/f09f9484-reboot-safe-finops-dashboard"
    print_status "📈 Prometheus: http://localhost:9091"
    print_status "🔧 Cost Collector API: http://localhost:5000"
}

# 스크립트 실행
main "$@"
