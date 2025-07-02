# 🚨 장애 추적 통합 대시보드 가이드

## 📊 **구축된 통합 관찰성 시스템**

### 🎯 **목표**
- **즉각적인 상황 파악**: SLO 위반 시 1분 내 원인 식별
- **드릴다운 분석**: 메트릭 → 로그 → 트레이스 연계 추적
- **장애 영향도 분석**: 비즈니스 임팩트 측정
- **근본 원인 분석**: 인프라부터 애플리케이션까지 전체 스택 분석

## 🏗️ **시스템 아키텍처**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Test App      │    │ Traffic Gen     │    │  Grafana Stack  │
│                 │    │                 │    │                 │
│ • HTTP Metrics  │───▶│ • Load Testing  │───▶│ • Dashboards    │
│ • Structured    │    │ • Error Sim     │    │ • Alerting      │
│   Logs          │    │ • Burst Traffic │    │ • Drill-down    │
│ • OTEL Traces   │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │      Loki       │    │     Tempo       │
│                 │    │                 │    │                 │
│ • HTTP Metrics  │    │ • Error Logs    │    │ • Trace Data    │
│ • SLO Tracking  │    │ • Trace IDs     │    │ • Span Details  │
│ • Alerting      │    │ • Correlation   │    │ • Performance   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📈 **배포된 대시보드**

### 1. **🚨 Incident Tracking & SLO Dashboard**
- **UID**: `incident-tracking-slo`
- **목적**: 실시간 SLO 모니터링 및 장애 감지
- **주요 기능**:
  - Service Availability (SLO: >99%)
  - Response Time P95 (SLO: <1s)
  - Error Rate (SLO: <1%)
  - Request Rate 추적
  - 에러 타입별 분석
  - 리소스 사용량 모니터링

### 2. **🔍 Advanced Drill-Down Dashboard**
- **UID**: `advanced-drill-down`
- **목적**: 심화 분석 및 드릴다운 기능
- **주요 기능**:
  - 섹션별 구조화된 분석
  - 클릭 기반 드릴다운 링크
  - 히트맵 기반 성능 분석
  - 로그-트레이스 통합 뷰

## 🔍 **드릴다운 분석 시나리오**

### **시나리오 1: 높은 에러율 감지**
```
1. SLO 대시보드에서 Error Rate > 1% 감지
   ↓
2. "Error Rate by Type" 패널 클릭
   ↓
3. 특정 에러 타입 (예: database_timeout) 선택
   ↓
4. "View error logs" 링크 클릭
   ↓
5. Loki에서 해당 에러의 상세 로그 확인
   ↓
6. 로그에서 trace_id 추출
   ↓
7. Tempo에서 해당 트레이스 상세 분석
```

### **시나리오 2: 응답시간 지연 분석**
```
1. Response Time P95 > 1s 감지
   ↓
2. "Response Time Heatmap" 확인
   ↓
3. 느린 구간 (빨간색 영역) 식별
   ↓
4. "Request Rate by Endpoint" 에서 문제 엔드포인트 확인
   ↓
5. 해당 엔드포인트 클릭 → "View traces" 링크
   ↓
6. Tempo에서 느린 트레이스 분석
   ↓
7. 스팬별 처리시간 분석으로 병목 지점 식별
```

### **시나리오 3: 인프라 리소스 연관 분석**
```
1. 성능 저하 감지
   ↓
2. "Resource Usage by Pod" 확인
   ↓
3. CPU/Memory 사용률 급증 확인
   ↓
4. 해당 시점의 Request Rate 패턴 분석
   ↓
5. 트래픽 증가와 리소스 사용률 상관관계 분석
```

## 🎯 **생성되는 테스트 데이터**

### **HTTP 메트릭**
- `http_requests_total`: 요청 수 (status_code, endpoint별)
- `http_request_duration_seconds`: 응답시간 히스토그램
- `application_errors_total`: 애플리케이션 에러 (타입별)
- `business_events_total`: 비즈니스 이벤트

### **로그 데이터**
- **구조화된 JSON 로그**
- **trace_id 포함**: 트레이스 연계 가능
- **에러 레벨별 분류**: INFO, WARN, ERROR
- **컨텍스트 정보**: processing_time, order_id 등

### **트레이스 데이터**
- **OpenTelemetry 표준**
- **HTTP 요청별 스팬**
- **에러 상태 추적**
- **성능 속성**: duration, operation.type

### **트래픽 패턴**
- **정상 트래픽**: 1-3 RPS
- **버스트 트래픽**: 5분마다 30초간 고부하
- **에러 시나리오**: 1-3분마다 의도적 에러 생성

## 🚀 **사용 방법**

### **1. 대시보드 접속**
```bash
# NodePort 확인
kubectl get svc grafana-stack-grafana -n observability

# 브라우저에서 접속
http://NODE_IP:31000

# 로그인
Username: admin
Password: admin123
```

### **2. 대시보드 탐색**
- **Monitoring 폴더** → **Incident Tracking & SLO Dashboard**
- **Monitoring 폴더** → **Advanced Drill-Down Dashboard**

### **3. 실시간 모니터링**
- SLO 게이지에서 임계값 위반 확인
- 에러 스파이크 감지 시 즉시 드릴다운
- 히트맵에서 성능 패턴 분석

## 🔧 **커스터마이징**

### **SLO 임계값 조정**
```json
// 대시보드 JSON에서 thresholds 수정
"thresholds": {
  "steps": [
    {"color": "red", "value": null},
    {"color": "yellow", "value": 99},    // 가용성 경고
    {"color": "green", "value": 99.5}    // 가용성 정상
  ]
}
```

### **새로운 서비스 추가**
1. 애플리케이션에 OpenTelemetry 계측 추가
2. Prometheus 메트릭 엔드포인트 노출
3. 구조화된 로그 출력 (JSON + trace_id)
4. 대시보드 템플릿 변수에 서비스 추가

## 📊 **알림 설정**

### **Alertmanager 규칙 예시**
```yaml
groups:
- name: slo.rules
  rules:
  - alert: HighErrorRate
    expr: |
      (
        sum(rate(http_requests_total{status_code=~"5.."}[5m])) /
        sum(rate(http_requests_total[5m]))
      ) * 100 > 1
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value }}% for 2 minutes"
```

## 🎉 **완성된 기능**

✅ **실시간 SLO 모니터링**
✅ **메트릭-로그-트레이스 통합**
✅ **클릭 기반 드릴다운**
✅ **자동 데이터 생성**
✅ **장애 시뮬레이션**
✅ **비즈니스 임팩트 분석**
✅ **인프라 리소스 연관 분석**

이제 실제 장애 상황에서 1분 내에 근본 원인을 추적할 수 있는 완전한 관찰성 시스템이 구축되었습니다!
