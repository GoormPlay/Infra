# 🚀 FinOps AWS Cost Monitoring System

완전한 AWS 비용 관리 및 최적화를 위한 통합 FinOps 시스템입니다.

## 📋 시스템 개요

이 시스템은 다음 구성요소로 이루어져 있습니다:

- **AWS Cost Collector**: AWS Cost Explorer API를 통한 실시간 비용 데이터 수집
- **Prometheus**: 메트릭 저장 및 시계열 데이터베이스
- **Grafana**: 시각화 및 대시보드
- **Redis**: 캐싱 및 성능 최적화

## 🚀 빠른 시작

### 1. 환경 설정

`.env` 파일에서 AWS 자격 증명을 설정하세요:

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
AWS_REGION=ap-northeast-2

# Grafana Configuration
GF_SECURITY_ADMIN_PASSWORD=admin123
```

### 2. 시스템 시작

```bash
./start.sh
```

### 3. 시스템 정지

```bash
./stop.sh
```

### 4. 완전 정리 (데이터 삭제)

```bash
./stop.sh --clean
```

## 📊 접속 정보

- **Grafana**: http://localhost:3001 (admin/admin123)
- **Prometheus**: http://localhost:9091
- **Cost Collector API**: http://localhost:5000
- **Redis**: localhost:6380

## 🎯 주요 대시보드

### 🔄 Reboot-Safe FinOps Dashboard (권장)
- URL: http://localhost:3001/d/7614c43e-6660-42dc-b75c-48bf61607ea4/f09f9484-reboot-safe-finops-dashboard
- 재부팅 후에도 100% 작동 보장
- 모든 핵심 FinOps 메트릭 포함

### 🌟 Ultimate FinOps Command Center
- 경영진용 종합 대시보드
- AI 기반 비용 예측 및 최적화 권장사항

### 📈 기타 전문 대시보드
- FinOps Executive Dashboard
- Cost Anomaly Detection
- Resource Optimization
- Unit Economics
- Governance & Compliance
- Forecasting & Planning

## 📁 디렉토리 구조

```
cost-monitoring/
├── README.md                    # 이 파일
├── .env                        # 환경 설정
├── docker-compose.yml          # Docker 구성
├── start.sh                    # 시작 스크립트
├── stop.sh                     # 정지 스크립트
├── load-finops-dashboards.sh   # 대시보드 로드 스크립트
├── cost-collector/             # 비용 수집기
├── grafana/                    # Grafana 설정 및 대시보드
├── prometheus/                 # Prometheus 설정
└── docs/                       # 추가 문서
```

## 🔧 문제 해결

### 시스템이 시작되지 않는 경우

1. Docker가 실행 중인지 확인
2. `.env` 파일의 AWS 자격 증명 확인
3. 포트 충돌 확인 (3001, 9091, 5000, 6380)

### 데이터가 표시되지 않는 경우

1. AWS 권한 확인
2. Cost Collector 로그 확인: `docker logs aws-cost-collector-enhanced`
3. Prometheus 연결 확인: http://localhost:9091

### 대시보드가 로드되지 않는 경우

```bash
./load-finops-dashboards.sh
```

## 💰 비용 정보

### 예상 AWS API 비용 (월간)
- Cost Explorer API: ~$14.40
- 기타 AWS 서비스: ~$2.16
- **총 API 비용**: ~$16.56/월

### ROI 분석
- 현재 AWS 월간 비용: $1,298.99
- 예상 절약률: 10-30% ($130-$390/월)
- **순 절약액**: $113-$373/월

## 🔒 보안 고려사항

- AWS 자격 증명을 안전하게 보관하세요
- 최소 권한 원칙을 적용하세요
- 정기적으로 액세스 키를 교체하세요

## 📞 지원

- 이슈 리포팅: GitHub Issues
- 문서 개선: Pull Request
- 기술 지원: 시스템 관리자 문의

---

**🌟 이 FinOps 시스템으로 AWS 비용을 지능적으로 관리하세요!**
