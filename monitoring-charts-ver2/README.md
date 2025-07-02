# 🎯 Complete Observability Stack

완전한 관찰성 스택으로 메트릭, 로그, 트레이스를 통합하여 완벽한 드릴다운 분석이 가능한 모니터링 시스템입니다.

## 📦 **구성 요소**

### **Core Components**
- **📊 Prometheus**: 메트릭 수집 및 저장
- **📄 Loki**: 로그 수집 및 저장  
- **🔗 Tempo**: 트레이스 수집 및 저장
- **📈 Grafana**: 통합 시각화 및 대시보드
- **🚨 Alertmanager**: 알림 관리
- **📝 Fluent Bit**: 로그 수집기

### **Test Applications**
- **🧪 Enhanced Test App**: 구조화된 로그, 메트릭, 트레이스 생성
- **🔄 Traffic Generator**: 실제 부하 패턴 시뮬레이션

## 🚀 **빠른 시작**

### **전체 스택 배포**
```bash
cd /home/lch/monitoring-charts
./deploy-all.sh
```

### **개별 구성 요소 배포**
```bash
# Prometheus Stack
kubectl apply -f prometheus-stack/current-prometheus-stack.yaml

# Loki Stack  
kubectl apply -f loki-stack/loki-deployment.yaml

# Tempo Stack
kubectl apply -f tempo-stack/tempo-deployment.yaml

# Fluent Bit
kubectl apply -f fluent-bit/fluent-bit-daemonset.yaml

# Test Applications
kubectl apply -f test-applications/enhanced-test-app.yaml
kubectl apply -f test-applications/traffic-generator.yaml

# Grafana Stack (with Dashboards)
cd grafana-stack
helm upgrade --install grafana-stack . -n observability
```

## 📊 **접속 정보**

### **Grafana Dashboard**
```bash
# NodePort 확인
export NODE_PORT=$(kubectl get --namespace observability -o jsonpath="{.spec.ports[0].nodePort}" services grafana-stack-grafana)
export NODE_IP=$(kubectl get nodes -o jsonpath="{.items[0].status.addresses[0].address}")
echo "URL: http://$NODE_IP:$NODE_PORT"

# 로그인 정보
Username: admin
Password: admin123
```

### **개별 서비스 접속**
```bash
# Prometheus
kubectl port-forward -n observability svc/prometheus 9090:9090

# Loki  
kubectl port-forward -n observability svc/loki 3100:3100

# Tempo
kubectl port-forward -n observability svc/tempo 3200:3200

# Alertmanager
kubectl port-forward -n observability svc/grafana-stack-alertmanager 9093:9093
```

## 🎯 **주요 대시보드**

### **1. Perfect Drill-Down Analysis Dashboard**
- **UID**: `perfect-drill-down-analysis`
- **기능**: 완벽한 드릴다운 분석, SLO 모니터링
- **특징**: 클릭 한 번으로 메트릭 → 로그 → 트레이스 연결

### **2. Incident Tracking & SLO Dashboard**  
- **UID**: `incident-tracking-slo`
- **기능**: 실시간 SLO 추적, 장애 감지
- **특징**: 가용성, 응답시간, 에러율 모니터링

### **3. Advanced Drill-Down Dashboard**
- **UID**: `advanced-drill-down`  
- **기능**: 심화 분석, 성능 히트맵
- **특징**: 섹션별 구조화된 분석

## 🔍 **드릴다운 분석 시나리오**

### **장애 감지 → 근본 원인 파악 (1분 내)**
```
1. SLO 게이지에서 임계값 위반 감지 (빨간색/노란색)
   ↓
2. 게이지 클릭 → 관련 에러 로그/트레이스로 즉시 이동
   ↓  
3. 로그에서 TraceID 클릭 → Tempo에서 상세 트레이스 분석
   ↓
4. 스팬별 처리시간 분석 → 정확한 병목 지점 식별
   ↓
5. 근본 원인 파악 완료 → 해결 방안 수립
```

## 📈 **생성되는 데이터**

### **메트릭**
- `http_requests_total`: HTTP 요청 수 (엔드포인트별, 상태코드별)
- `http_request_duration_seconds`: 응답시간 히스토그램
- `application_errors_total`: 애플리케이션 에러 (타입별)
- `business_events_total`: 비즈니스 이벤트

### **로그**
- **구조화된 JSON 로그** (trace_id 포함)
- **에러 레벨별 분류**: INFO, WARN, ERROR
- **컨텍스트 정보**: processing_time, order_id, endpoint

### **트레이스**
- **OpenTelemetry 표준** 트레이스
- **HTTP 요청별 스팬**
- **에러 상태 추적**
- **성능 속성**: duration, operation.type

## 🚨 **알림 설정**

### **SLO 기반 알림**
- **High Error Rate**: 에러율 > 1% (2분간)
- **High Response Time**: P95 > 1초 (5분간)  
- **Service Down**: 서비스 다운 (1분간)
- **High Resource Usage**: CPU/Memory > 80% (5분간)

### **비즈니스 메트릭 알림**
- **Low Order Creation Rate**: 주문 생성율 저하
- **High Database Timeouts**: 데이터베이스 타임아웃 증가

## 🔧 **설정 파일**

### **디렉토리 구조**
```
monitoring-charts/
├── prometheus-stack/          # Prometheus 설정
├── loki-stack/               # Loki 설정  
├── tempo-stack/              # Tempo 설정
├── fluent-bit/               # Fluent Bit 설정
├── test-applications/        # 테스트 앱
├── alertmanager-config/      # 알림 설정
├── grafana-stack/           # Grafana + 대시보드
├── deploy-all.sh            # 전체 배포 스크립트
├── cleanup-all.sh           # 전체 정리 스크립트
└── README.md               # 이 파일
```

### **주요 설정 파일**
- `alertmanager-config/alert-rules.yaml`: 알림 규칙
- `alertmanager-config/alertmanager.yaml`: 알림 라우팅
- `grafana-stack/values.yaml`: Grafana 설정
- `fluent-bit/fluent-bit-daemonset.yaml`: 로그 수집 설정

## 🧹 **정리**

### **전체 스택 제거**
```bash
./cleanup-all.sh
```

### **개별 구성 요소 제거**
```bash
# 역순으로 제거
kubectl delete -f test-applications/
kubectl delete -f fluent-bit/
kubectl delete -f tempo-stack/
kubectl delete -f loki-stack/
kubectl delete -f prometheus-stack/
helm uninstall grafana-stack -n observability
```

## 🎯 **성공 지표**

이 시스템을 통해 달성 가능한 목표:
- **MTTR < 1분**: 장애 감지부터 근본 원인 파악까지
- **완전한 관찰성**: 메트릭, 로그, 트레이스 통합
- **실용적인 드릴다운**: 클릭 한 번으로 상세 분석
- **SLO 준수율 > 99.9%**: 지속적인 서비스 품질 관리

## 🆘 **문제 해결**

### **일반적인 문제**
```bash
# Pod 상태 확인
kubectl get pods -n observability

# 로그 확인
kubectl logs -n observability deployment/grafana-stack-grafana
kubectl logs -n observability deployment/loki
kubectl logs -n observability deployment/tempo

# 서비스 상태 확인  
kubectl get svc -n observability
```

### **포트 포워딩 문제**
```bash
# 기존 포트 포워딩 종료
pkill -f "port-forward"

# 새로 시작
kubectl port-forward -n observability svc/grafana-stack-grafana 3000:3000
```

## 📞 **지원**

문제가 발생하면 다음을 확인하세요:
1. 모든 Pod가 Running 상태인지 확인
2. 서비스 엔드포인트가 정상인지 확인  
3. 네트워크 정책이 올바른지 확인
4. 리소스 제한이 충분한지 확인

---

**🎉 완전한 관찰성 스택으로 완벽한 드릴다운 분석을 경험하세요!**
