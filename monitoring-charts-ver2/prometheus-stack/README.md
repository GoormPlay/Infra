# Prometheus Stack Helm Chart

이 Helm 차트는 Prometheus 기반의 메트릭 수집 스택을 배포합니다.

## 구성 요소

- **Prometheus Server**: 메트릭 수집 및 저장
- **kube-state-metrics**: Kubernetes 상태 메트릭 수집
- **prometheus-node-exporter**: 노드 수준 시스템 메트릭 수집

## 설치

```bash
# 네임스페이스 생성
kubectl create namespace observability

# Helm 차트 설치
helm install prometheus-stack ./prometheus-stack -n observability
```

## 주요 설정

### 보존 기간 (Retention)
기본값: 15일
```yaml
prometheus:
  retention:
    time: 15d
    size: 50GB
```

### 수집 주기 (Scrape Interval)
기본값: 15초
```yaml
global:
  scrapeInterval: 15s
```

### Alertmanager 연동
```yaml
prometheus:
  alertmanager:
    enabled: true
    url: "alertmanager.observability.svc.cluster.local:9093"
```

### 스토리지 설정
```yaml
prometheus:
  storage:
    enabled: true
    size: 50Gi
    storageClass: ""  # 기본 스토리지 클래스 사용
```

## 서비스 접근

- **Prometheus UI**: `http://prometheus.observability.svc.cluster.local:9090`
- **kube-state-metrics**: `http://kube-state-metrics.observability.svc.cluster.local:8080`
- **node-exporter**: 각 노드의 9100 포트

## 스크래핑 대상

차트는 다음 대상들을 자동으로 스크래핑합니다:

1. **Prometheus 자체 모니터링**
2. **Kubernetes API 서버**
3. **Kubernetes 노드**
4. **kube-state-metrics**
5. **node-exporter**
6. **어노테이션이 있는 Pod들**:
   - `prometheus.io/scrape: "true"`
   - `prometheus.io/port: "<port>"`
   - `prometheus.io/path: "<path>"`
7. **어노테이션이 있는 Service들**

## 필터링 기준

모니터링 설계서에 따라 다음 레이블로 메트릭을 분류합니다:

- `job`: 작업 유형
- `service`: 서비스 이름
- `path`: API 경로 (HTTP 메트릭)
- `method`: HTTP 메서드
- `status_code`: HTTP 상태 코드

## 알림 규칙

기본 알림 규칙이 포함되어 있습니다:

- **SLO 관련 규칙**: 가용성, 응답 시간, 오류율
- **인프라 규칙**: CPU, 메모리, 디스크 사용률
- **Kubernetes 규칙**: Pod 재시작, 리소스 사용량

## 커스터마이징

### 추가 스크래핑 설정
```yaml
additionalScrapeConfigs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['my-app:8080']
```

### 외부 레이블 추가
```yaml
externalLabels:
  cluster: "production"
  region: "us-west-2"
```

### 원격 저장소 설정
```yaml
remoteWrite:
  enabled: true
  configs:
    - url: "https://remote-storage.example.com/api/v1/write"
```

## 문제 해결

### 스토리지 이슈
PVC가 생성되지 않는 경우:
```bash
kubectl get storageclass
kubectl describe pvc prometheus-stack-prometheus-storage -n observability
```

### RBAC 권한 이슈
ServiceAccount 권한 확인:
```bash
kubectl auth can-i list pods --as=system:serviceaccount:observability:prometheus-stack-prometheus
```

### 메트릭 수집 확인
Prometheus UI에서 Targets 페이지를 확인하여 스크래핑 상태를 점검하세요.

## 업그레이드

```bash
helm upgrade prometheus-stack ./prometheus-stack -n observability
```

## 제거

```bash
helm uninstall prometheus-stack -n observability
```

**주의**: PVC는 자동으로 삭제되지 않으므로 필요시 수동으로 삭제해야 합니다.
