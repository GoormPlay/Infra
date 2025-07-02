# 🔍 수정된 Loki 쿼리 가이드

## ❌ **문제가 있던 쿼리**
```logql
{service="enhanced-test-app"} | json | level=~"error|ERROR|warning|WARNING" or error_type!=""
```

**문제점:**
- Loki에서 `or` 연산자를 파이프라인 내에서 직접 사용 불가
- 조건부 로직이 올바르지 않음

## ✅ **올바른 쿼리들**

### **1. 에러/경고 레벨 로그만**
```logql
{service="enhanced-test-app"} | json | level=~"error|ERROR|warning|WARNING"
```

### **2. 애플리케이션 에러가 있는 로그만**
```logql
{service="enhanced-test-app"} | json | error_type!=""
```

### **3. 느린 요청 로그**
```logql
{service="enhanced-test-app"} | json | processing_time > 2.0
```

### **4. 특정 엔드포인트 에러**
```logql
{service="enhanced-test-app"} | json | endpoint="/api/orders" | status_code >= 400
```

### **5. 트레이스 ID가 있는 에러 로그 (포맷팅)**
```logql
{service="enhanced-test-app"} | json | level="error" | line_format "{{.timestamp}} [{{.level}}] {{.event}} | TraceID: {{.trace_id}} | Endpoint: {{.endpoint}}"
```

## 🎯 **대시보드별 권장 쿼리**

### **Incident Tracking Dashboard - 에러 로그 패널:**
```logql
# Query A: 에러/경고 레벨
{service="enhanced-test-app"} | json | level=~"error|ERROR|warning|WARNING"

# Query B: 애플리케이션 에러
{service="enhanced-test-app"} | json | error_type!=""
```

### **Advanced Drill-Down Dashboard - 로그 패널:**
```logql
# Query A: 에러 로그
{service="enhanced-test-app"} | json | level=~"error|ERROR|warning|WARNING"

# Query B: 포맷된 에러 로그 (트레이스 연결용)
{service="enhanced-test-app"} | json | error_type!="" | line_format "{{.timestamp}} [{{.level}}] {{.event}} | ERROR: {{.error_type}} | TraceID: {{.trace_id}}"
```

## 📊 **메트릭 생성용 쿼리**

### **에러율 계산:**
```logql
sum(rate({service="enhanced-test-app"} | json | status_code >= 400 [5m])) 
/ 
sum(rate({service="enhanced-test-app"} | json | status_code > 0 [5m]))
```

### **에러 타입별 집계:**
```logql
sum by (error_type) (
  count_over_time(
    {service="enhanced-test-app"} | json | error_type!="" [5m]
  )
)
```

## 🔗 **드릴다운 시나리오별 쿼리**

### **시나리오 1: 에러율 증가 감지**
```logql
# 1단계: 전체 에러 로그
{service="enhanced-test-app"} | json | level="error"

# 2단계: 특정 에러 타입
{service="enhanced-test-app"} | json | error_type="database_timeout"

# 3단계: 해당 트레이스 ID
{service="enhanced-test-app"} | json | trace_id="특정_trace_id"
```

### **시나리오 2: 성능 이슈 분석**
```logql
# 1단계: 느린 요청
{service="enhanced-test-app"} | json | processing_time > 2.0

# 2단계: 특정 엔드포인트
{service="enhanced-test-app"} | json | endpoint="/api/slow" | processing_time > 2.0

# 3단계: 트레이스 연결
{service="enhanced-test-app"} | json | endpoint="/api/slow" | trace_id!="" | line_format "SLOW: {{.processing_time}}s | TraceID: {{.trace_id}}"
```

## 🎨 **로그 포맷팅 예시**

### **기본 포맷:**
```logql
{service="enhanced-test-app"} | json | line_format "{{.timestamp}} [{{.level}}] {{.event}}"
```

### **트레이스 연결 포맷:**
```logql
{service="enhanced-test-app"} | json | line_format "{{.timestamp}} [{{.level}}] {{.event}} | TraceID: {{.trace_id}}"
```

### **상세 정보 포맷:**
```logql
{service="enhanced-test-app"} | json | line_format "{{.timestamp}} [{{.level}}] {{.endpoint}} {{.method}} {{.status_code}} | {{.event}} | TraceID: {{.trace_id}}"
```

## ⚡ **성능 최적화 팁**

1. **인덱스 활용**: `{service="enhanced-test-app"}` 라벨 필터를 먼저 적용
2. **시간 범위 제한**: 너무 긴 시간 범위는 피하기
3. **필드 필터링**: 필요한 필드만 추출
4. **정규식 최적화**: 복잡한 정규식보다 단순한 조건 사용

## 🔧 **실제 테스트 방법**

```bash
# Loki에 직접 쿼리 테스트
kubectl port-forward -n observability svc/loki 3100:3100 &

# 쿼리 테스트
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={service="enhanced-test-app"} | json | level="error"' \
  --data-urlencode 'start=1703097600000000000' \
  --data-urlencode 'end=1703184000000000000' \
  | jq '.data.result[0].values[][1]'
```

이제 Grafana 대시보드에서 올바른 Loki 쿼리로 구조화된 로그를 정확하게 필터링하고 표시할 수 있습니다!
