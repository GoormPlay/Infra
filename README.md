# Infrastructure Management Repository

이 저장소는 AWS 인프라 관리, 모니터링, 비용 최적화를 위한 도구와 스크립트들을 포함하고 있습니다.

## 📁 디렉토리 구조

### 🔍 monitoring-charts/
Kubernetes 클러스터를 위한 종합적인 모니터링 솔루션

**주요 구성요소:**
- **Prometheus Stack**: 메트릭 수집 및 저장
- **Grafana Stack**: 시각화 및 대시보드
- **Loki Stack**: 로그 수집 및 분석
- **Tempo Stack**: 분산 추적
- **Fluent Bit**: 로그 수집기
- **AlertManager**: 알림 관리
- **Test Applications**: 모니터링 테스트용 애플리케이션

**주요 스크립트:**
- `deploy-all-final.sh`: 모든 모니터링 컴포넌트 일괄 배포
- `cleanup-all.sh`: 모든 모니터링 컴포넌트 정리

### 💰 cost-monitoring/
AWS 비용 모니터링 및 분석 시스템

**기능:**
- AWS 비용 데이터 수집 및 시각화
- 비용 추세 분석 및 예측
- 비용 최적화 권장사항 제공
- Docker Compose 기반 배포

**주요 파일:**
- `docker-compose.yml`: 비용 모니터링 스택 정의
- `setup.sh`: 초기 설정 스크립트
- `start.sh` / `stop.sh`: 서비스 시작/중지
- `SRS-AWS-비용모니터링시스템.md`: 시스템 요구사항 명세서

### 📊 finops-report(Final)/
FinOps 전문 보고서 생성 시스템

**포함 내용:**
- 비용 낭비 분석 (waste-analysis)
- 이상 탐지 (anomaly-detection)
- 비용 추세 예측 (cost-trend-forecast)
- 절약 전략 (saving-strategies)
- 태그 할당 분석 (tag-allocation)
- PDF 보고서 자동 생성

**주요 파일:**
- `finops_report.sh`: 보고서 생성 스크립트
- `finops_professional_report.pdf`: 생성된 전문 보고서
- `*.md`: 각 섹션별 분석 보고서

### 🖥️ ec2-Operations/
EC2 인스턴스 운영 및 관리 도구

**기능:**
- EC2 인스턴스 자동 설정
- CloudWatch 에이전트 설치 및 구성
- Terraform을 통한 인프라 코드 관리

**주요 파일:**
- `user-data.sh`: EC2 인스턴스 초기 설정 스크립트
- `cloudwatch-agent.sh`: CloudWatch 에이전트 설치 스크립트
- `terraform-ec2/`: Terraform 구성 파일

## 🚀 시작하기

### 전제 조건
- AWS CLI 구성 완료
- Docker 및 Docker Compose 설치
- Kubernetes 클러스터 (모니터링용)
- Terraform (인프라 관리용)

### 빠른 시작

1. **모니터링 시스템 배포**
   ```bash
   cd monitoring-charts
   ./deploy-all-final.sh
   ```

2. **비용 모니터링 시작**
   ```bash
   cd cost-monitoring
   ./setup.sh
   ./start.sh
   ```

3. **FinOps 보고서 생성**
   ```bash
   cd finops-report\(Final\)
   ./finops_report.sh
   ```

## 📋 주요 기능

- **실시간 모니터링**: Prometheus, Grafana를 통한 메트릭 및 로그 모니터링
- **비용 최적화**: AWS 비용 분석 및 절약 권장사항 제공
- **자동화된 보고**: FinOps 전문 보고서 자동 생성
- **인프라 관리**: Terraform을 통한 코드형 인프라 관리
- **알림 시스템**: AlertManager를 통한 실시간 알림

## 🔧 구성 및 사용법

각 디렉토리의 개별 README.md 파일을 참조하여 상세한 설정 방법을 확인하세요.

## 📞 지원

문제가 발생하거나 질문이 있으시면 다음을 확인해주세요:
- 각 디렉토리의 README.md 파일
- 로그 파일 (각 서비스별 로그 디렉토리)
- AWS CloudWatch 로그

## 📝 라이선스

이 프로젝트는 내부 사용을 위한 것입니다.

---

**마지막 업데이트**: 2025-07-02
