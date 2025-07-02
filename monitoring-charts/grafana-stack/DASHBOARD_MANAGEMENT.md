# 📊 Grafana 대시보드 관리 가이드

## 📁 디렉토리 구조

```
grafana-stack/
├── provisioning/
│   ├── datasources/
│   │   └── datasources.yaml      # 데이터소스 자동 구성
│   └── dashboards/
│       └── dashboards.yaml       # 대시보드 프로비저닝 설정
├── dashboards/
│   ├── kubernetes/               # Kubernetes 관련 대시보드
│   │   └── cluster-overview.json
│   ├── monitoring/               # 모니터링 시스템 대시보드
│   │   └── prometheus-stats.json
│   └── applications/             # 애플리케이션 대시보드
│       └── loki-logs.json
└── templates/
    └── grafana-provisioning-configmap.yaml  # ConfigMap 템플릿
```

## 🎯 포함된 대시보드

### Kubernetes 폴더
- **cluster-overview.json**: 클러스터 전체 상태 모니터링
  - CPU/Memory 사용률
  - Pod, Node, Namespace, Service 개수
  - 실시간 리소스 모니터링

### Monitoring 폴더
- **prometheus-stats.json**: Prometheus 자체 메트릭
  - Symbol Table Size
  - Head Series 개수
  - HTTP 요청 비율
  - 스토리지 사용량

### Applications 폴더
- **loki-logs.json**: 로그 분석 대시보드
  - 네임스페이스별 로그 비율
  - Observability 네임스페이스 로그
  - 에러 로그 필터링

## ➕ 새 대시보드 추가 방법

### 1. JSON 파일로 직접 추가
```bash
# 1. 적절한 카테고리 폴더에 JSON 파일 추가
cp my-new-dashboard.json dashboards/kubernetes/

# 2. Helm 차트 업그레이드
helm upgrade grafana-stack . -n observability

# 3. 확인
kubectl get configmaps -n observability | grep dashboards
```

### 2. Grafana UI에서 생성 후 내보내기
```bash
# 1. Grafana UI 접속 (http://NODE_IP:31000)
# 2. 대시보드 생성 및 편집
# 3. Settings → JSON Model에서 JSON 복사
# 4. 해당 카테고리 폴더에 파일로 저장
# 5. Helm 업그레이드
```

### 3. 기존 대시보드 수정
```bash
# 1. JSON 파일 직접 편집
vi dashboards/kubernetes/cluster-overview.json

# 2. 변경사항 적용
helm upgrade grafana-stack . -n observability
```

## 🔄 자동 프로비저닝 작동 방식

### ConfigMap 생성
- 각 폴더별로 별도 ConfigMap 생성
- `grafana-stack-dashboards-kubernetes`
- `grafana-stack-dashboards-monitoring`
- `grafana-stack-dashboards-applications`

### 볼륨 마운트
```yaml
# Grafana Pod에 자동 마운트
- name: dashboards-kubernetes
  mountPath: /var/lib/grafana/dashboards/kubernetes
- name: dashboards-monitoring
  mountPath: /var/lib/grafana/dashboards/monitoring
- name: dashboards-applications
  mountPath: /var/lib/grafana/dashboards/applications
```

### 폴더 자동 분류
- Kubernetes 폴더: Kubernetes 관련 대시보드
- Monitoring 폴더: 모니터링 시스템 대시보드
- Applications 폴더: 애플리케이션 대시보드

## 📝 대시보드 개발 가이드

### 필수 필드
```json
{
  "uid": "unique-dashboard-id",        // 고유 ID (필수)
  "title": "Dashboard Title",         // 대시보드 제목
  "tags": ["kubernetes", "monitoring"], // 검색용 태그
  "version": 1,                       // 버전 관리
  "schemaVersion": 27                 // Grafana 스키마 버전
}
```

### 권장 사항
1. **고유한 UID**: 각 대시보드마다 고유한 UID 설정
2. **의미있는 태그**: 검색과 분류를 위한 태그 활용
3. **템플릿 변수**: 재사용 가능한 대시보드를 위한 변수 사용
4. **적절한 폴더**: 목적에 따른 올바른 폴더 배치

### 예시 템플릿 변수
```json
"templating": {
  "list": [
    {
      "name": "namespace",
      "type": "query",
      "query": "label_values(kube_namespace_created, namespace)",
      "refresh": 1,
      "includeAll": true
    }
  ]
}
```

## 🛠️ 트러블슈팅

### 대시보드가 나타나지 않는 경우
```bash
# 1. ConfigMap 확인
kubectl get configmap grafana-stack-dashboards-kubernetes -n observability -o yaml

# 2. Pod 재시작
kubectl rollout restart deployment/grafana-stack-grafana -n observability

# 3. 로그 확인
kubectl logs -n observability deployment/grafana-stack-grafana -c grafana
```

### JSON 형식 오류
```bash
# JSON 유효성 검사
cat dashboards/kubernetes/my-dashboard.json | jq .

# Helm 템플릿 렌더링 테스트
helm template grafana-stack . --debug
```

## 📚 참고 자료

- [Grafana Dashboard API](https://grafana.com/docs/grafana/latest/http_api/dashboard/)
- [Grafana Provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)
- [Dashboard JSON Model](https://grafana.com/docs/grafana/latest/dashboards/json-model/)

## 🎉 완료!

이제 JSON 파일로 대시보드를 체계적으로 관리할 수 있습니다:
- ✅ 버전 관리 가능
- ✅ 자동 프로비저닝
- ✅ 폴더별 분류
- ✅ 쉬운 배포 및 업데이트
