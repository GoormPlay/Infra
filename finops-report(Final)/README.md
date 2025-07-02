# FinOps 전문 보고서 생성 시스템

AWS 서울 리전의 비용 분석 및 최적화를 위한 종합적인 FinOps 보고서 자동 생성 시스템입니다.

## 📋 개요

이 시스템은 AWS 비용 데이터를 분석하여 전문적인 FinOps 보고서를 자동으로 생성합니다. 비용 낭비 탐지, 이상 징후 분석, 절약 전략 수립 등 다양한 관점에서 비용 최적화 인사이트를 제공합니다.

## 📁 파일 구조

### 📊 분석 보고서
- `01_waste-analysis.md` - 리소스 낭비 탐지 및 절감 전략
- `02_anomaly-detection.md` - 비용 이상징후 탐지 및 알림 분석
- `03_cost-trend-forecast.md` - 비용 트렌드 분석 및 예측
- `04_saving-strategies.md` - EC2/RDS/Lambda 절감 전략
- `05_tag-allocation.md` - 태그 기반 리소스 분류 및 비용 분석

### 📄 종합 보고서
- `final_finops_summary.md` - 전체 분석 결과 종합
- `executive_finops_report.md` - 경영진용 요약 보고서
- `finops_professional_report.md` - 전문가용 상세 보고서
- `finops_professional_report.pdf` - PDF 형태의 최종 보고서

### 🛠️ 시스템 파일
- `finops_report.sh` - 보고서 자동 생성 스크립트
- `finops-template.tex` - LaTeX 템플릿 (PDF 생성용)
- `finops-template-fixed.tex` - 수정된 LaTeX 템플릿
- `report-generation.log` - 보고서 생성 로그

## 🚀 사용 방법

### 1. 보고서 생성
```bash
# 전체 보고서 생성
./finops_report.sh

# 실행 권한이 없는 경우
chmod +x finops_report.sh
./finops_report.sh
```

### 2. 개별 보고서 확인
```bash
# 비용 낭비 분석 보고서
cat 01_waste-analysis.md

# 이상 징후 탐지 보고서
cat 02_anomaly-detection.md

# 비용 예측 보고서
cat 03_cost-trend-forecast.md
```

### 3. PDF 보고서 생성
LaTeX가 설치된 환경에서:
```bash
pdflatex finops-template-fixed.tex
```

## 📊 주요 분석 항목

### 💰 비용 분석
- **월별 비용 추이**: 최근 4주간 비용 변화 분석
- **서비스별 비용 분포**: EC2, RDS, Lambda 등 서비스별 비용
- **리전별 비용**: 서울 리전 중심 분석
- **예상 비용**: 다음 달 비용 예측

### 🔍 낭비 탐지
- **유휴 리소스**: 사용되지 않는 EC2, RDS 인스턴스
- **과도한 프로비저닝**: 필요 이상으로 큰 인스턴스
- **미사용 스토리지**: 연결되지 않은 EBS 볼륨
- **비효율적 예약**: Reserved Instance 최적화

### 📈 이상 징후
- **급격한 비용 증가**: 일일 비용 변화 모니터링
- **예상치 못한 서비스 사용**: 새로운 서비스 도입 감지
- **비정상적 사용 패턴**: 평소와 다른 리소스 사용

### 💡 절약 전략
- **인스턴스 최적화**: 적절한 인스턴스 타입 추천
- **Reserved Instance**: 예약 인스턴스 구매 권장
- **Spot Instance**: 스팟 인스턴스 활용 방안
- **Auto Scaling**: 자동 확장/축소 설정

## 📋 보고서 예시

### 현재 분석 결과 (2025년 6월 기준)
- **5월 총 비용**: $26.82
- **6월 현재 비용**: $310.80 (19일 기준)
- **월 증가율**: 1,058% 급증
- **7월 예상 비용**: $390.52

### 주요 비용 요인
1. **Amazon EC2**: $192.32 (61.9%)
2. **Amazon RDS**: $35.16 (11.3%)
3. **Amazon VPC**: $29.21 (9.4%)
4. **Amazon EKS**: $18.68 (6.0%)

## ⚙️ 설정 및 커스터마이징

### 분석 기간 변경
`finops_report.sh` 파일에서 분석 기간을 수정할 수 있습니다:
```bash
# 분석 기간 설정
START_DATE="2025-05-01"
END_DATE="2025-06-19"
```

### 대상 리전 변경
```bash
# 대상 리전 설정
TARGET_REGION="ap-northeast-2"  # 서울 리전
```

### 임계값 설정
```bash
# 비용 증가 알림 임계값
COST_INCREASE_THRESHOLD=100  # 100% 증가시 알림
```

## 📊 대시보드 연동

이 보고서는 다음 모니터링 시스템과 연동됩니다:
- **Grafana**: 비용 시각화 대시보드
- **Prometheus**: 메트릭 수집 및 저장
- **AlertManager**: 비용 임계값 알림

## 🔧 문제 해결

### 보고서 생성 실패
```bash
# 로그 확인
cat report-generation.log

# 권한 확인
ls -la finops_report.sh
chmod +x finops_report.sh
```

### PDF 생성 오류
```bash
# LaTeX 설치 확인
which pdflatex

# 템플릿 문법 확인
pdflatex -interaction=nonstopmode finops-template-fixed.tex
```

## 📅 자동화

### Cron 설정 (주간 보고서)
```bash
# 매주 월요일 오전 9시 보고서 생성
0 9 * * 1 /home/lch/Infra/finops-report\(Final\)/finops_report.sh
```

### 일일 모니터링
```bash
# 매일 오전 8시 간단한 비용 체크
0 8 * * * /home/lch/Infra/finops-report\(Final\)/daily_cost_check.sh
```

## 📞 지원 및 문의

- **로그 파일**: `report-generation.log`
- **AWS 비용 대시보드**: AWS Cost Explorer
- **Grafana 대시보드**: 실시간 비용 모니터링

---

**마지막 업데이트**: 2025-07-02  
**분석 대상**: AWS 서울 리전 (ap-northeast-2)  
**보고서 형식**: Markdown, PDF
