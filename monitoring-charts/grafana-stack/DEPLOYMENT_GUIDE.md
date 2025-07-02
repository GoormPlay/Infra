# Grafana Stack 배포 가이드

## 📋 Task 4 완료 요약

AI_PROMPT_BLUEPRINT.md의 Task 4 요구사항에 따라 Grafana와 Alertmanager를 포함한 시각화 및 알림 스택용 Helm 차트가 성공적으로 생성되었습니다.

## ✅ 구현된 요구사항

### 1. 결과물 위치
- ✅ `monitoring-charts/grafana-stack` 디렉터리에 Helm 차트 생성 완료

### 2. 구성 요소
- ✅ **Grafana**: 메트릭, 로그, 트레이스 시각화 대시보드
- ✅ **Alertmanager**: 알림 처리 및 라우팅 서비스

### 3. 핵심 설정 (values.yaml 통해 관리)

#### Alertmanager 설정
- ✅ **서비스 주소**: `alertmanager.observability.svc.cluster.local:9093`로 접근 가능
- ✅ **Slack 알림 설정**: 기본 리시버 설정 포함, Webhook URL은 placeholder로 설정
- ✅ **이메일 알림 설정**: SMTP 설정 포함
- ✅ **알림 억제 규칙**: 중복 알림 방지 설정

#### Grafana 설정
- ✅ **Sidecar 기능 활성화**: ConfigMap/Secret 자동 탐지로 데이터 소스/대시보드 생성
- ✅ **외부 접근**: Ingress 및 LoadBalancer 설정 지원
- ✅ **보안**: 관리자 계정 설정 및 인증 구성

## 🏗️ 차트 구조

```
monitoring-charts/grafana-stack/
├── Chart.yaml                           # 차트 메타데이터
├── values.yaml                          # 기본 설정 값
├── README.md                            # 상세 문서
├── DEPLOYMENT_GUIDE.md                  # 배포 가이드
├── test-chart.sh                        # 차트 검증 스크립트
├── examples/                            # 예제 설정 파일
│   ├── production-values.yaml           # 프로덕션 설정 예제
│   └── development-values.yaml          # 개발 환경 설정 예제
└── templates/                           # Kubernetes 매니페스트 템플릿
    ├── _helpers.tpl                     # 헬퍼 템플릿
    ├── NOTES.txt                        # 배포 후 안내 메시지
    ├── serviceaccount.yaml              # 서비스 계정
    ├── rbac.yaml                        # RBAC 설정
    ├── grafana-deployment.yaml          # Grafana 배포
    ├── grafana-service.yaml             # Grafana 서비스
    ├── grafana-configmap.yaml           # Grafana 설정
    ├── grafana-pvc.yaml                 # Grafana 영구 볼륨
    ├── grafana-ingress.yaml             # Grafana Ingress
    ├── alertmanager-deployment.yaml     # Alertmanager 배포
    ├── alertmanager-service.yaml        # Alertmanager 서비스
    ├── alertmanager-configmap.yaml      # Alertmanager 설정
    ├── alertmanager-pvc.yaml            # Alertmanager 영구 볼륨
    └── servicemonitor.yaml              # Prometheus 모니터링
```

## 🚀 배포 방법

### 1. 기본 배포
```bash
cd /home/lch/monitoring-charts/grafana-stack
helm install grafana-stack . -n observability --create-namespace
```

### 2. 개발 환경 배포
```bash
helm install grafana-stack . -n observability --create-namespace -f examples/development-values.yaml
```

### 3. 프로덕션 환경 배포
```bash
helm install grafana-stack . -n observability --create-namespace -f examples/production-values.yaml
```

### 4. 차트 검증
```bash
./test-chart.sh
```

## 🔧 주요 설정 포인트

### Grafana Sidecar 설정
```yaml
grafana:
  sidecar:
    enabled: true
    datasources:
      enabled: true
      label: grafana_datasource
      labelValue: "1"
    dashboards:
      enabled: true
      label: grafana_dashboard
      labelValue: "1"
```

### Alertmanager 서비스 주소
```yaml
# 클러스터 내부에서 접근 가능한 주소
alertmanager.observability.svc.cluster.local:9093
```

### Slack 알림 설정
```yaml
alertmanager:
  config:
    global:
      slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'
    receivers:
      - name: 'web.hook'
        slack_configs:
          - channel: '#alerts'
            title: 'Alert: {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
```

## 🔍 검증 결과

- ✅ Helm lint 통과
- ✅ Template 렌더링 성공
- ✅ 다양한 설정 조합 테스트 통과
- ✅ RBAC 및 보안 설정 포함
- ✅ ServiceMonitor를 통한 Prometheus 연동 준비

## 🔗 Task 5 연동 준비

이 차트는 Task 5의 Umbrella Chart에서 의존성으로 사용될 수 있도록 설계되었습니다:

1. **데이터 소스 자동 탐지**: Sidecar가 ConfigMap을 통해 Prometheus, Loki, Tempo 연동
2. **표준 서비스 주소**: `alertmanager.observability.svc.cluster.local:9093`
3. **레이블 기반 설정**: `grafana_datasource=1`, `grafana_dashboard=1` 레이블 사용

## 📞 접근 방법

배포 후 다음 명령으로 접근 정보를 확인할 수 있습니다:

```bash
helm status grafana-stack -n observability
```

기본 로그인 정보:
- Username: `admin`
- Password: `admin123` (프로덕션에서는 변경 필요)

## 🎯 다음 단계

Task 5에서 이 차트를 Umbrella Chart의 의존성으로 추가하고, 다른 모니터링 스택들과 연동하는 설정을 구성하게 됩니다.
