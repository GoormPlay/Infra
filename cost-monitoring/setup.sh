#!/bin/bash

# FinOps 시스템 빠른 설정 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 FinOps 시스템 빠른 설정                      ║"
    echo "║              AWS Cost Monitoring System                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

# 사전 요구사항 확인
check_prerequisites() {
    print_status "사전 요구사항 확인 중..."
    
    # Docker 확인
    if ! command -v docker &> /dev/null; then
        print_error "Docker가 설치되지 않았습니다."
        echo "설치 방법: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Docker Compose 확인
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose가 설치되지 않았습니다."
        echo "설치 방법: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # curl 확인
    if ! command -v curl &> /dev/null; then
        print_error "curl이 설치되지 않았습니다."
        echo "설치: sudo apt install curl (Ubuntu/Debian) 또는 sudo yum install curl (CentOS/RHEL)"
        exit 1
    fi
    
    # jq 확인
    if ! command -v jq &> /dev/null; then
        print_warning "jq가 설치되지 않았습니다. JSON 처리에 필요합니다."
        echo "설치: sudo apt install jq (Ubuntu/Debian) 또는 sudo yum install jq (CentOS/RHEL)"
    fi
    
    print_success "사전 요구사항 확인 완료"
}

# 환경 설정 파일 생성
setup_environment() {
    print_status "환경 설정 파일 구성 중..."
    
    if [ -f ".env" ]; then
        print_warning ".env 파일이 이미 존재합니다."
        read -p "덮어쓰시겠습니까? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "기존 .env 파일을 사용합니다."
            return
        fi
    fi
    
    # AWS 자격 증명 입력
    echo -e "${CYAN}AWS 자격 증명을 입력하세요:${NC}"
    read -p "AWS Access Key ID: " aws_access_key
    read -s -p "AWS Secret Access Key: " aws_secret_key
    echo
    read -p "AWS Region (기본: ap-northeast-2): " aws_region
    aws_region=${aws_region:-ap-northeast-2}
    
    # Grafana 비밀번호 입력
    echo -e "${CYAN}Grafana 설정:${NC}"
    read -s -p "Grafana 관리자 비밀번호 (기본: admin123): " grafana_password
    echo
    grafana_password=${grafana_password:-admin123}
    
    # .env 파일 생성
    cat > .env << EOF
# AWS Credentials
AWS_ACCESS_KEY_ID=${aws_access_key}
AWS_SECRET_ACCESS_KEY=${aws_secret_key}
AWS_REGION=${aws_region}

# Grafana Configuration
GF_SECURITY_ADMIN_PASSWORD=${grafana_password}
GF_INSTALL_PLUGINS=grafana-aws-cloudwatch-datasource,grafana-simple-json-datasource

# Cost Collection Settings
COLLECTION_INTERVAL=3600
PROMETHEUS_PORT=8080
FLASK_PORT=5000

# Port Settings
GRAFANA_PORT=3001
PROMETHEUS_PORT_EXTERNAL=9091
REDIS_PORT=6380

# Performance Settings
REDIS_MAX_MEMORY=256mb
PROMETHEUS_RETENTION=90d
LOG_LEVEL=INFO
EOF
    
    chmod 600 .env
    print_success "환경 설정 파일 생성 완료"
}

# AWS 자격 증명 테스트
test_aws_credentials() {
    print_status "AWS 자격 증명 테스트 중..."
    
    source .env
    
    # AWS CLI 설치 확인
    if command -v aws &> /dev/null; then
        # AWS CLI로 테스트
        if AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY aws sts get-caller-identity --region $AWS_REGION &> /dev/null; then
            print_success "AWS 자격 증명 확인 완료"
        else
            print_error "AWS 자격 증명이 올바르지 않습니다."
            exit 1
        fi
    else
        print_warning "AWS CLI가 설치되지 않아 자격 증명을 테스트할 수 없습니다."
        print_status "시스템 시작 후 Cost Collector 로그를 확인하세요."
    fi
}

# 포트 충돌 확인
check_ports() {
    print_status "포트 사용 가능성 확인 중..."
    
    local ports=(3001 9091 5000 6380)
    local conflicts=()
    
    for port in "${ports[@]}"; do
        if netstat -tlnp 2>/dev/null | grep -q ":${port} " || ss -tlnp 2>/dev/null | grep -q ":${port} "; then
            conflicts+=($port)
        fi
    done
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        print_warning "다음 포트가 사용 중입니다: ${conflicts[*]}"
        print_status "docker-compose.yml에서 포트를 변경하거나 사용 중인 서비스를 중지하세요."
    else
        print_success "모든 포트 사용 가능"
    fi
}

# 시스템 시작
start_system() {
    print_status "FinOps 시스템 시작 중..."
    
    # 이전 컨테이너 정리
    docker-compose down 2>/dev/null || true
    
    # 시스템 시작
    docker-compose --env-file .env up -d
    
    print_success "시스템 시작 완료"
}

# 서비스 상태 확인
verify_services() {
    print_status "서비스 상태 확인 중..."
    
    local max_attempts=30
    local services=("Grafana:3001" "Prometheus:9091" "Cost Collector:5000")
    
    for service_info in "${services[@]}"; do
        local service_name=$(echo $service_info | cut -d: -f1)
        local port=$(echo $service_info | cut -d: -f2)
        local attempt=1
        
        print_status "${service_name} 서비스 대기 중..."
        
        while [ $attempt -le $max_attempts ]; do
            if curl -s http://localhost:${port} > /dev/null 2>&1 || curl -s http://localhost:${port}/health > /dev/null 2>&1; then
                print_success "${service_name} 서비스 준비 완료!"
                break
            fi
            
            if [ $attempt -eq $max_attempts ]; then
                print_warning "${service_name} 서비스가 응답하지 않습니다. 로그를 확인하세요."
            fi
            
            sleep 2
            ((attempt++))
        done
    done
}

# 설치 완료 안내
show_completion_info() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    설치 완료!                                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${CYAN}📊 접속 정보:${NC}"
    echo "• Grafana: http://localhost:3001 (admin/$(grep GF_SECURITY_ADMIN_PASSWORD .env | cut -d= -f2))"
    echo "• Prometheus: http://localhost:9091"
    echo "• Cost Collector API: http://localhost:5000"
    echo ""
    
    echo -e "${CYAN}🎯 추천 대시보드:${NC}"
    echo "• Reboot-Safe FinOps Dashboard (재부팅 후에도 작동 보장)"
    echo "• Ultimate FinOps Command Center (종합 관리)"
    echo ""
    
    echo -e "${CYAN}🔧 관리 명령어:${NC}"
    echo "• 시스템 시작: ./start.sh"
    echo "• 시스템 정지: ./stop.sh"
    echo "• 대시보드 로드: ./load-finops-dashboards.sh"
    echo ""
    
    echo -e "${CYAN}📚 문서:${NC}"
    echo "• README.md - 시스템 개요"
    echo "• INSTALL.md - 상세 설치 가이드"
    echo "• USER-GUIDE.md - 사용자 가이드"
    echo ""
    
    echo -e "${YELLOW}⚠️  주의사항:${NC}"
    echo "• AWS 비용 데이터 수집까지 5-10분 소요될 수 있습니다."
    echo "• 첫 실행 시 Docker 이미지 다운로드로 시간이 걸릴 수 있습니다."
    echo ""
    
    echo -e "${GREEN}🎉 FinOps 시스템이 성공적으로 설치되었습니다!${NC}"
}

# 메인 실행
main() {
    print_header
    
    check_prerequisites
    setup_environment
    test_aws_credentials
    check_ports
    start_system
    verify_services
    show_completion_info
}

# 스크립트 실행
main "$@"
