# Grafana Stack Helm Chart

이 Helm 차트는 Grafana와 Alertmanager를 포함한 시각화 및 알림 스택을 배포합니다.

## 개요

이 차트는 다음 구성 요소를 포함합니다:

- **Grafana**: 메트릭, 로그, 트레이스 데이터를 시각화하는 대시보드 플랫폼
- **Alertmanager**: Prometheus에서 전송된 알림을 처리하고 라우팅하는 서비스

## 주요 기능

### Grafana
- **Sidecar 기능**: ConfigMap과 Secret을 자동으로 탐지하여 데이터 소스와 대시보드를 동적으로 생성
- **외부 접근**: Ingress 또는 LoadBalancer를 통한 외부 접근 지원
- **영구 저장소**: PersistentVolume을 통한 데이터 영속성
- **보안**: 관리자 계정 설정 및 보안 구성

### Alertmanager
- **알림 라우팅**: 다양한 채널(Slack, Email 등)로 알림 전송
- **알림 그룹화**: 유사한 알림을 그룹화하여 스팸 방지
- **알림 억제**: 중복 알림 방지를 위한 억제 규칙
- **클러스터 내부 접근**: `alertmanager.observability.svc.cluster.local:9093`

## 설치

### 기본 설치
```bash
helm install grafana-stack ./grafana-stack -n observability --create-namespace
```

### 사용자 정의 값으로 설치
```bash
helm install grafana-stack ./grafana-stack -n observability --create-namespace -f custom-values.yaml
```

## 구성

### 주요 설정 값

#### Grafana 설정
```yaml
grafana:
  enabled: true
  adminUser: admin
  adminPassword: admin123  # 프로덕션에서는 변경 필요
  
  # 외부 접근 설정
  ingress:
    enabled: true
    hosts:
      - host: grafana.example.com
        paths:
          - path: /
            pathType: Prefix
  
  # 또는 LoadBalancer 사용
  loadBalancer:
    enabled: true
  
  # Sidecar 설정 (자동 데이터 소스/대시보드 탐지)
  sidecar:
    enabled: true
    datasources:
      enabled: true
      label: grafana_datasource
    dashboards:
      enabled: true
      label: grafana_dashboard
```

#### Alertmanager 설정
```yaml
alertmanager:
  enabled: true
  config:
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    
    receivers:
      - name: 'web.hook'
        slack_configs:
          - channel: '#alerts'
            title: 'Alert: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

### 데이터 소스 자동 구성

Grafana Sidecar는 다음 레이블을 가진 ConfigMap을 자동으로 탐지합니다:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-datasource
  labels:
    grafana_datasource: "1"
data:
  datasource.yaml: |
    apiVersion: 1
    datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus.observability.svc.cluster.local:9090
        access: proxy
        isDefault: true
```

## 대시보드 관리

### 📁 디렉토리 구조
```
grafana-stack/
├── provisioning/
│   ├── datasources/
│   │   └── datasources.yaml      # 데이터소스 설정
│   └── dashboards/
│       └── dashboards.yaml       # 대시보드 프로비저닝 설정
├── dashboards/
│   ├── kubernetes/               # Kubernetes 관련 대시보드
│   │   └── cluster-overview.json
│   ├── monitoring/               # 모니터링 시스템 대시보드
│   │   └── prometheus-stats.json
│   └── applications/             # 애플리케이션 대시보드
│       └── loki-logs.json
```

### 📊 포함된 대시보드
- **Kubernetes Cluster Overview**: 클러스터 전체 상태 모니터링
- **Prometheus Statistics**: Prometheus 자체 메트릭 모니터링
- **Loki Logs Dashboard**: 로그 분석 및 검색

### ➕ 새 대시보드 추가 방법

1. **JSON 파일로 추가**:
   ```bash
   # 적절한 카테고리 폴더에 JSON 파일 추가
   cp my-dashboard.json dashboards/kubernetes/
   
   # Helm 차트 업그레이드
   helm upgrade grafana-stack . -n observability
   ```

2. **Grafana UI에서 생성 후 내보내기**:
   - Grafana UI에서 대시보드 생성
   - Settings → JSON Model에서 JSON 복사
   - 해당 카테고리 폴더에 저장
   - Helm 업그레이드

### 🔄 자동 프로비저닝
- 모든 대시보드는 ConfigMap으로 자동 생성됨
- 파일 변경 시 Helm 업그레이드만으로 반영
- 폴더별로 자동 분류 (Kubernetes, Monitoring, Applications)

### 📝 대시보드 개발 가이드
1. **UID 설정**: 각 대시보드에 고유한 UID 부여
2. **태그 활용**: 검색과 분류를 위한 태그 설정
3. **템플릿 변수**: 재사용 가능한 대시보드를 위한 변수 활용
4. **폴더 분류**: 목적에 따른 적절한 폴더 배치
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Monitoring Dashboard",
        ...
      }
    }
```

## 서비스 접근

### 클러스터 내부 접근
- Grafana: `grafana-stack-grafana.observability.svc.cluster.local:3000`
- Alertmanager: `grafana-stack-alertmanager.observability.svc.cluster.local:9093`

### 외부 접근
설치 후 다음 명령으로 접근 방법을 확인할 수 있습니다:

```bash
helm status grafana-stack -n observability
```

## 모니터링

이 차트는 ServiceMonitor 리소스를 포함하여 Prometheus가 Grafana와 Alertmanager의 메트릭을 수집할 수 있도록 합니다.

## 보안 고려사항

1. **관리자 비밀번호**: 프로덕션 환경에서는 반드시 기본 비밀번호를 변경하세요
2. **Slack Webhook**: Slack 알림을 사용하는 경우 webhook URL을 안전하게 관리하세요
3. **RBAC**: Sidecar 기능을 위한 최소 권한 RBAC 설정이 포함되어 있습니다

## 업그레이드

```bash
helm upgrade grafana-stack ./grafana-stack -n observability
```

## 제거

```bash
helm uninstall grafana-stack -n observability
```

## 문제 해결

### 일반적인 문제

1. **Grafana 접속 불가**: Service 타입과 Ingress 설정을 확인하세요
2. **대시보드가 나타나지 않음**: ConfigMap의 레이블이 올바른지 확인하세요
3. **알림이 전송되지 않음**: Alertmanager 설정과 Slack webhook URL을 확인하세요

### 로그 확인

```bash
# Grafana 로그
kubectl logs -n observability deployment/grafana-stack-grafana -c grafana

# Alertmanager 로그
kubectl logs -n observability deployment/grafana-stack-alertmanager

# Sidecar 로그
kubectl logs -n observability deployment/grafana-stack-grafana -c grafana-sc-datasources
kubectl logs -n observability deployment/grafana-stack-grafana -c grafana-sc-dashboard
```

## 기여

이 차트에 대한 개선 사항이나 버그 리포트는 언제든지 환영합니다.
