# 🔍 Loki 쿼리 가이드 - 장애 추적용

## 📊 **현재 로그 구조**

Enhanced Test App에서 생성하는 JSON 로그 예시:
```json
{
  "service": "enhanced-test-app",
  "level": "error",
  "endpoint": "/api/users",
  "method": "GET",
  "status_code": 500,
  "error_type": "database_timeout",
  "processing_time": 0.8,
  "trace_id": "ddde3a5a8a87b2f3f005e09ee17bf583",
  "span_id": "bd03879dae4c9933",
  "event": "Database timeout occurred",
  "timestamp": "2025-06-21T14:45:12.947583Z"
}
```

## 🎯 **올바른 Loki 쿼리**

### **1. 에러 로그만 필터링**
```logql
{service="enhanced-test-app"} | json | level=~"error|ERROR|warning|WARNING"
```

### **2. 특정 에러 타입 필터링**
```logql
{service="enhanced-test-app"} | json | error_type!=""
```

### **3. 느린 요청 필터링**
```logql
{service="enhanced-test-app"} | json | processing_time > 2.0
```

### **4. 특정 엔드포인트 에러**
```logql
{service="enhanced-test-app"} | json | endpoint="/api/orders" | status_code >= 400
```

### **5. Trace ID가 있는 에러 로그**
```logql
{service="enhanced-test-app"} | json | level="error" | trace_id!=""
```

### **6. 복합 조건 (에러 또는 느린 요청)**
```logql
{service="enhanced-test-app"} | json | level=~"error|warning" or processing_time > 1.0
```

## 🔗 **드릴다운용 쿼리**

### **1. 에러 로그 + 포맷팅**
```logql
{service="enhanced-test-app"} 
| json 
| level=~"error|ERROR|warning|WARNING" 
| line_format "{{.timestamp}} [{{.level}}] {{.endpoint}} - {{.event}} (trace: {{.trace_id}})"
```

### **2. 시간대별 에러 집계**
```logql
sum by (error_type) (
  count_over_time(
    {service="enhanced-test-app"} | json | error_type!="" [5m]
  )
)
```

### **3. 엔드포인트별 에러율**
```logql
sum by (endpoint) (
  rate(
    {service="enhanced-test-app"} | json | status_code >= 400 [5m]
  )
)
```

## 🚨 **대시보드에서 사용할 쿼리**

### **에러 로그 패널:**
```logql
{service="enhanced-test-app"} | json | level=~"error|ERROR|warning|WARNING" or error_type!=""
```

### **트레이스 연결 로그 패널:**
```logql
{service="enhanced-test-app"} | json | trace_id!="" | line_format "{{.timestamp}} [{{.level}}] {{.event}} | TraceID: {{.trace_id}} | Endpoint: {{.endpoint}}"
```

### **성능 이슈 로그 패널:**
```logql
{service="enhanced-test-app"} | json | processing_time > 1.0 | line_format "SLOW: {{.endpoint}} took {{.processing_time}}s | TraceID: {{.trace_id}}"
```

## 📈 **메트릭 생성용 쿼리**

### **에러율 계산:**
```logql
sum(rate({service="enhanced-test-app"} | json | status_code >= 400 [5m])) 
/ 
sum(rate({service="enhanced-test-app"} | json | status_code > 0 [5m]))
```

### **평균 응답시간:**
```logql
avg_over_time(
  {service="enhanced-test-app"} | json | unwrap processing_time [5m]
)
```

## 🔧 **템플릿 변수 활용**

### **서비스별 필터링:**
```logql
{service="$service"} | json | level=~"error|ERROR|warning|WARNING"
```

### **시간 범위 활용:**
```logql
{service="$service"} | json | level="error" | __timestamp__ >= $__from and __timestamp__ <= $__to
```

## ⚠️ **주의사항**

1. **JSON 파싱 필수**: `| json` 파이프라인 필수
2. **필드명 정확성**: 로그의 실제 필드명과 일치해야 함
3. **성능 고려**: 너무 복잡한 쿼리는 성능 저하 유발
4. **인덱싱**: 자주 사용하는 필드는 라벨로 설정 권장

## 🎯 **실제 사용 예시**

### **장애 발생 시 드릴다운 시나리오:**
1. **에러 감지**: `{service="enhanced-test-app"} | json | level="error"`
2. **에러 타입 확인**: `{service="enhanced-test-app"} | json | error_type="database_timeout"`
3. **관련 트레이스**: `{service="enhanced-test-app"} | json | trace_id="특정_trace_id"`
4. **시간대 분석**: 위 쿼리에 시간 범위 추가
