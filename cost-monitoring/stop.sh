#!/bin/bash

# FinOps 시스템 정지 스크립트

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

# 시스템 정지
stop_system() {
    print_status "FinOps 시스템 정지 중..."
    
    docker-compose --env-file .env down
    
    print_success "시스템 정지 완료"
}

# 볼륨까지 삭제 (선택사항)
clean_system() {
    if [ "$1" = "--clean" ]; then
        print_status "데이터 볼륨까지 삭제 중..."
        docker-compose --env-file .env down -v
        print_success "시스템 완전 정리 완료"
    fi
}

# 메인 실행
main() {
    print_status "🛑 FinOps 시스템 정지"
    
    stop_system
    clean_system "$1"
    
    print_success "🎉 FinOps 시스템 정지 완료!"
    
    if [ "$1" = "--clean" ]; then
        print_status "💡 다음 시작 시 모든 데이터가 초기화됩니다."
    else
        print_status "💡 데이터는 보존되었습니다. ./start.sh로 재시작 가능합니다."
    fi
}

# 스크립트 실행
main "$@"
