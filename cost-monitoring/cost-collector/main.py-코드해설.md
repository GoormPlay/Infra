# AWS 비용 데이터 수집기 (main.py) 코드 해설

**문서 버전**: 1.0  
**작성일**: 2025-06-24  
**프로젝트**: AWS 비용 모니터링 시스템 - 데이터 수집기  

---

## 1. 개요

본 문서는 AWS 비용 데이터 수집기의 핵심 구현 파일인 `main.py`의 상세한 코드 해설을 제공합니다. 이 파일은 SRS, SAD, 설계도 문서에서 정의된 요구사항과 아키텍처를 실제로 구현한 코드입니다.

### 1.1 파일 구조 개요
- **총 라인 수**: 약 550줄
- **주요 클래스**: `EnhancedAWSCostCollector`
- **핵심 기능**: AWS API 통합, 데이터 수집, 메트릭 생성, 캐싱, API 제공

---

## 2. 임포트 및 초기 설정

### 2.1 라이브러리 임포트

```python
#!/usr/bin/env python3
import boto3
import json
import time
import os
import redis
import schedule
from datetime import datetime, timedelta
from prometheus_client import start_http_server, Gauge, Counter, Info
from flask import Flask, jsonify
import threading
import logging
```

**해설**:
- `boto3`: AWS SDK for Python - AWS API 호출을 위한 핵심 라이브러리
- `redis`: 캐싱 시스템 연결을 위한 라이브러리
- `schedule`: 주기적 작업 스케줄링을 위한 라이브러리
- `prometheus_client`: Prometheus 메트릭 생성 및 노출을 위한 라이브러리
- `flask`: REST API 서버 구현을 위한 웹 프레임워크
- `threading`: 백그라운드 작업 실행을 위한 멀티스레딩 지원

### 2.2 로깅 설정

```python
# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
```

**해설**:
- 시스템 전체의 로깅 레벨을 INFO로 설정
- 모든 중요한 작업과 오류를 로그로 기록하여 디버깅과 모니터링 지원
- SRS 문서의 "관찰 가능성" 요구사항을 충족

---

## 3. Prometheus 메트릭 정의

### 3.1 비용 관련 메트릭

```python
# Enhanced Prometheus metrics
cost_total = Gauge('aws_cost_total', 'Total AWS cost', ['service', 'account_id'])
cost_daily = Gauge('aws_cost_daily', 'Daily AWS cost', ['service', 'account_id', 'date'])
cost_forecast = Gauge('aws_cost_forecast', 'AWS cost forecast', ['account_id'])
```

**해설**:
- `Gauge`: 현재 값을 나타내는 메트릭 타입 (비용은 현재 상태를 나타냄)
- `cost_total`: 서비스별, 계정별 총 비용을 추적
- `cost_daily`: 일별 비용 추이를 추적하여 시계열 분석 가능
- `cost_forecast`: 미래 비용 예측값을 저장
- 라벨을 통해 다차원 데이터 분석 지원 (SAD 문서의 데이터 모델과 일치)

### 3.2 태그 기반 메트릭

```python
# Tag-based cost metrics
cost_by_tag = Gauge('aws_cost_by_tag', 'AWS cost by tag', ['tag_key', 'tag_value', 'service'])
tag_cost_total = Gauge('aws_tag_cost_total', 'Total cost by tag', ['tag_key', 'tag_value'])
tag_resource_count = Gauge('aws_tag_resource_count', 'Resource count by tag', ['tag_key', 'tag_value'])
```

**해설**:
- 태그 기반 비용 분석을 위한 메트릭들
- `cost_by_tag`: 특정 태그의 서비스별 비용 분포
- `tag_cost_total`: 태그별 총 비용 (FinOps에서 중요한 비용 할당 기준)
- `tag_resource_count`: 태그별 리소스 수 (비용 대비 리소스 효율성 분석)

### 3.3 최적화 및 인사이트 메트릭

```python
# Optimization metrics
optimization_savings = Gauge('aws_optimization_savings', 'Potential savings', ['type', 'category'])
optimization_recommendations = Counter('aws_optimization_recommendations_total', 'Total recommendations', ['type', 'priority'])

# Well-Architected metrics
wellarchitected_score = Gauge('aws_wellarchitected_score', 'Well-Architected pillar score', ['pillar'])
wellarchitected_risks = Gauge('aws_wellarchitected_risks', 'Well-Architected risks', ['pillar', 'risk_level'])
```

**해설**:
- `Counter`: 누적 카운터 타입 (권장사항 수는 계속 증가)
- 최적화 관련 메트릭은 FinOps의 핵심 가치인 비용 최적화를 지원
- Well-Architected 메트릭은 비용뿐만 아니라 전체적인 아키텍처 품질 추적

---

## 4. 메인 클래스 구조

### 4.1 클래스 초기화

```python
class EnhancedAWSCostCollector:
    def __init__(self):
        # AWS clients
        self.ce_client = boto3.client('ce')
        redis_host = os.getenv('REDIS_HOST', 'cost-monitoring-redis')
        redis_port = int(os.getenv('REDIS_PORT', '6379'))
        self.redis_client = redis.Redis(host=redis_host, port=redis_port, db=0, decode_responses=True)
        self.account_id = boto3.client('sts').get_caller_identity()['Account']
        
        # Flask app
        self.app = Flask(__name__)
        self.setup_routes()
```

**해설**:
- **AWS 클라이언트 초기화**: Cost Explorer API 접근을 위한 클라이언트 생성
- **Redis 연결**: 환경 변수를 통한 유연한 설정 (Docker 환경 고려)
- **계정 ID 획득**: STS API를 통해 현재 AWS 계정 ID 자동 획득
- **Flask 앱 초기화**: REST API 서버 준비
- **설계 원칙 반영**: 의존성 주입과 환경 기반 설정으로 유연성 확보

### 4.2 라우트 설정

```python
def setup_routes(self):
    @self.app.route('/health')
    def health():
        return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})
        
    @self.app.route('/recommendations')
    def recommendations():
        return jsonify(self.get_cached_recommendations())
        
    @self.app.route('/wellarchitected')
    def wellarchitected():
        return jsonify(self.get_cached_wellarchitected())
        
    @self.app.route('/cost/current')
    def current_cost():
        return jsonify(self.get_current_cost_summary())
```

**해설**:
- **헬스체크 엔드포인트**: 시스템 상태 모니터링 지원 (SRS의 상태 확인 요구사항)
- **캐시 기반 응답**: 성능 최적화를 위해 캐시된 데이터 우선 제공
- **RESTful 설계**: 명확한 URL 구조와 JSON 응답 형식
- **관심사 분리**: 각 엔드포인트는 특정 기능에 집중

---

## 5. 핵심 데이터 수집 메서드

### 5.1 비용 및 사용량 데이터 수집

```python
def get_cost_and_usage(self):
    """Get cost and usage data from AWS Cost Explorer"""
    try:
        end_date = datetime.now()
        start_date = end_date - timedelta(days=30)
        
        response = self.ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['BlendedCost'],
            GroupBy=[
                {'Type': 'DIMENSION', 'Key': 'SERVICE'}
            ]
        )
```

**해설**:
- **시간 범위 설정**: 최근 30일간의 데이터 수집 (적절한 분석 기간)
- **일별 세분화**: 시계열 분석을 위한 일별 데이터 수집
- **서비스별 그룹화**: 서비스별 비용 분석을 위한 차원 설정
- **BlendedCost 메트릭**: AWS의 표준 비용 계산 방식 사용

### 5.2 데이터 처리 및 메트릭 업데이트

```python
        # Process and set metrics
        for result in response['ResultsByTime']:
            date = result['TimePeriod']['Start']
            for group in result['Groups']:
                service = group['Keys'][0]
                cost = float(group['Metrics']['BlendedCost']['Amount'])
                
                cost_daily.labels(
                    service=service,
                    account_id=self.account_id,
                    date=date
                ).set(cost)
```

**해설**:
- **데이터 변환**: AWS API 응답을 Prometheus 메트릭 형식으로 변환
- **라벨 활용**: 다차원 분석을 위한 메타데이터 추가
- **타입 변환**: 문자열 비용을 float로 변환하여 수치 연산 가능
- **메트릭 업데이트**: Prometheus 메트릭에 실시간 데이터 반영

### 5.3 오류 처리

```python
        except Exception as e:
            logger.error(f"Error fetching cost data: {str(e)}")
```

**해설**:
- **포괄적 예외 처리**: 모든 예외 상황을 캐치하여 시스템 안정성 확보
- **로깅**: 오류 상황을 로그로 기록하여 디버깅 지원
- **우아한 실패**: 예외 발생 시에도 시스템이 중단되지 않도록 설계

---

## 6. 비용 예측 기능

### 6.1 예측 데이터 수집

```python
def get_cost_forecast(self):
    """Get cost forecast"""
    try:
        end_date = datetime.now() + timedelta(days=30)
        start_date = datetime.now()
        
        response = self.ce_client.get_cost_forecast(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Metric='BLENDED_COST',
            Granularity='MONTHLY'
        )
        
        forecast_amount = float(response['Total']['Amount'])
        cost_forecast.labels(account_id=self.account_id).set(forecast_amount)
```

**해설**:
- **미래 예측**: 향후 30일간의 비용 예측 (FinOps 계획 수립에 중요)
- **월별 세분화**: 예산 계획에 적합한 월별 예측
- **AWS 내장 예측**: AWS의 머신러닝 기반 예측 엔진 활용
- **메트릭 저장**: 예측값을 Prometheus에 저장하여 시각화 지원

---

## 7. 최적화 권장사항 수집

### 7.1 권장사항 생성 로직

```python
def collect_optimization_recommendations(self):
    """수집 최적화 권장사항 (간소화 버전)"""
    try:
        # self.cost_data가 설정되어 있는지 확인
        if not hasattr(self, 'cost_data') or not self.cost_data:
            logger.warning("cost_data가 아직 설정되지 않았습니다. 기본값을 사용합니다.")
            potential_savings = 0.0
            recommendations_count = 0
        else:
            # 실제 비용 데이터를 기반으로 최적화 계산
            total_cost = sum(self.cost_data.values())
            potential_savings = total_cost * 0.15  # 총 비용의 15%를 절약 가능으로 추정
            recommendations_count = min(5, len([cost for cost in self.cost_data.values() if cost > 1.0]))
```

**해설**:
- **데이터 의존성 확인**: 다른 메서드에서 수집한 데이터 활용
- **휴리스틱 계산**: 실제 비용 데이터를 기반으로 한 절약 가능성 추정
- **현실적 추정**: 업계 평균인 15% 절약 가능성 적용
- **조건부 처리**: 데이터 가용성에 따른 유연한 처리

### 7.2 서비스별 권장사항

```python
        # 실제 비용 데이터를 기반으로 권장사항 생성
        ec2_cost = self.cost_data.get('Amazon Elastic Compute Cloud - Compute', 0) if hasattr(self, 'cost_data') else 0
        rds_cost = self.cost_data.get('Amazon Relational Database Service', 0) if hasattr(self, 'cost_data') else 0
        ebs_cost = self.cost_data.get('Amazon Elastic Block Store', 0) if hasattr(self, 'cost_data') else 0
        
        basic_recommendations = {
            'rightsizing': [
                {'service': 'EC2', 'potential_savings': round(ec2_cost * 0.2, 2), 'recommendation': 'Right-size underutilized instances'},
                {'service': 'RDS', 'potential_savings': round(rds_cost * 0.15, 2), 'recommendation': 'Consider Reserved Instances'},
                {'service': 'EBS', 'potential_savings': round(ebs_cost * 0.1, 2), 'recommendation': 'Delete unused volumes'}
            ],
            'total_potential_savings': round(potential_savings, 2),
            'last_updated': datetime.now().isoformat()
        }
```

**해설**:
- **서비스별 최적화**: 각 AWS 서비스의 특성에 맞는 최적화 전략
- **차등 절약률**: 서비스별로 다른 절약 가능성 적용 (EC2 20%, RDS 15%, EBS 10%)
- **구체적 권장사항**: 실행 가능한 구체적인 최적화 방안 제시
- **타임스탬프**: 데이터 신선도 추적을 위한 업데이트 시간 기록

---

## 8. 태그 기반 비용 분석

### 8.1 태그 데이터 수집

```python
def collect_tag_based_costs(self):
    """실제 AWS 태그 기반 비용 수집"""
    try:
        # 실제 태그 키들 (일반적으로 사용되는 태그들)
        tag_keys = ['Name', 'Environment', 'Project', 'Team', 'Application', 'Owner', 'CostCenter']
        
        tag_cost_data = {}
        
        for tag_key in tag_keys:
            try:
                # AWS Cost Explorer API 호출
                end_date = datetime.now()
                start_date = end_date - timedelta(days=30)
                
                response = self.ce_client.get_cost_and_usage(
                    TimePeriod={
                        'Start': start_date.strftime('%Y-%m-%d'),
                        'End': end_date.strftime('%Y-%m-%d')
                    },
                    Granularity='MONTHLY',
                    Metrics=['BlendedCost'],
                    GroupBy=[
                        {'Type': 'TAG', 'Key': tag_key}
                    ]
                )
```

**해설**:
- **표준 태그 키**: 일반적으로 사용되는 AWS 태그 키들을 대상으로 분석
- **FinOps 관점**: 비용 할당과 책임 추적에 중요한 태그들 선별
- **월별 집계**: 태그별 비용 추이 분석을 위한 적절한 세분화
- **개별 처리**: 각 태그 키별로 독립적 처리하여 오류 격리

### 8.2 태그 데이터 처리

```python
                # 응답 데이터 처리
                for result in response.get('ResultsByTime', []):
                    for group in result.get('Groups', []):
                        keys = group.get('Keys', [])
                        if keys:
                            tag_value = keys[0].replace(f'{tag_key}$', '') or 'untagged'
                            cost = float(group.get('Metrics', {}).get('BlendedCost', {}).get('Amount', 0))
                            
                            if cost > 0:  # 비용이 있는 것만 포함
                                # 실제 리소스 수 추정 (비용 기반)
                                resource_count = max(1, int(cost / 5))  # $5당 1개 리소스로 추정
                                
                                tag_values[tag_value] = {
                                    'cost': round(cost, 2),
                                    'resources': min(resource_count, 100),  # 최대 100개로 제한
                                    'services': self._estimate_services_from_cost(cost)
                                }
```

**해설**:
- **안전한 데이터 접근**: `get()` 메서드로 KeyError 방지
- **태그 값 정규화**: AWS API 응답의 특수 문자 제거
- **미태그 리소스 처리**: 태그가 없는 리소스를 'untagged'로 분류
- **리소스 수 추정**: 비용 기반 휴리스틱으로 리소스 수 추정
- **데이터 검증**: 비용이 0인 항목 제외로 의미 있는 데이터만 처리

---

## 9. 캐싱 전략

### 9.1 Redis 캐시 활용

```python
        # Redis에 태그 데이터 캐시
        self.redis_client.setex(
            'tag_cost_data',
            3600,  # 1시간 캐시
            json.dumps(tag_cost_data, default=str)
        )
```

**해설**:
- **TTL 설정**: 1시간 캐시로 데이터 신선도와 성능의 균형
- **JSON 직렬화**: 복잡한 데이터 구조를 Redis에 저장 가능한 형태로 변환
- **성능 최적화**: AWS API 호출 빈도 감소로 응답 시간 개선
- **비용 절약**: API 호출 횟수 감소로 AWS 사용료 절약

### 9.2 캐시 조회 로직

```python
def get_cached_recommendations(self):
    """캐시된 권장사항 반환"""
    try:
        cached = self.redis_client.get('optimization_recommendations')
        if cached:
            return json.loads(cached)
        else:
            # 실제 비용 데이터 기반 기본 권장사항 반환
            total_cost = sum(self.cost_data.values()) if hasattr(self, 'cost_data') and self.cost_data else 0
            # ... 기본값 생성 로직
    except Exception as e:
        logger.error(f"Error getting cached recommendations: {str(e)}")
        return {}
```

**해설**:
- **캐시 우선**: 캐시된 데이터가 있으면 우선 반환
- **폴백 메커니즘**: 캐시 미스 시 기본값 생성으로 서비스 연속성 보장
- **오류 격리**: 캐시 오류가 전체 시스템에 영향을 주지 않도록 처리
- **성능 향상**: 복잡한 계산 결과를 캐시하여 응답 시간 단축

---

## 10. 스케줄링 시스템

### 10.1 작업 스케줄 설정

```python
def run_scheduler(self):
    """스케줄러 실행"""
    # 비용 데이터는 1시간마다
    schedule.every(1).hours.do(self.get_cost_and_usage)
    schedule.every(1).hours.do(self.get_cost_forecast)
    
    # 태그 기반 비용은 30분마다
    schedule.every(30).minutes.do(self.collect_tag_based_costs)
    
    # 최적화 권장사항은 2시간마다
    schedule.every(2).hours.do(self.collect_optimization_recommendations)
    
    # Well-Architected는 6시간마다
    schedule.every(6).hours.do(self.collect_wellarchitected_insights)
    
    while True:
        schedule.run_pending()
        time.sleep(60)
```

**해설**:
- **차등 주기**: 데이터의 중요도와 변경 빈도에 따른 차등 수집 주기
- **리소스 최적화**: 자주 변경되지 않는 데이터는 긴 주기로 수집
- **AWS API 제한 고려**: API 호출 빈도를 적절히 분산하여 제한 회피
- **무한 루프**: 지속적인 스케줄 실행을 위한 데몬 프로세스 구조

### 10.2 서비스 시작 로직

```python
def start(self):
    """Enhanced cost collector 시작"""
    # Set service info
    service_info.info({
        'version': '2.1.0',
        'account_id': self.account_id,
        'start_time': datetime.now().isoformat(),
        'features': 'cost,optimization,wellarchitected,recommendations,tags'
    })
    
    # Initial collection
    self.collect_all_metrics()
    
    # Start Prometheus metrics server
    start_http_server(8080)
    
    # Start scheduler in a separate thread
    scheduler_thread = threading.Thread(target=self.run_scheduler)
    scheduler_thread.daemon = True
    scheduler_thread.start()
    
    # Start Flask app
    logger.info("Enhanced AWS Cost Collector v2.1 started on port 5000")
    self.app.run(host='0.0.0.0', port=5000)
```

**해설**:
- **서비스 정보 설정**: Prometheus를 통해 서비스 메타데이터 노출
- **초기 데이터 수집**: 서비스 시작 시 즉시 데이터 수집으로 빠른 서비스 제공
- **멀티 서버**: Prometheus 메트릭 서버(8080)와 REST API 서버(5000) 동시 운영
- **백그라운드 스케줄러**: 데몬 스레드로 스케줄러 실행하여 메인 서비스와 분리
- **전체 바인딩**: `0.0.0.0`으로 바인딩하여 컨테이너 환경에서 외부 접근 허용

---

## 11. 설계 문서와의 연관성

### 11.1 SRS 요구사항 구현

| SRS 요구사항 | 코드 구현 |
|-------------|-----------|
| F1: AWS 비용 데이터 수집 | `get_cost_and_usage()` 메서드 |
| F2: 비용 예측 데이터 수집 | `get_cost_forecast()` 메서드 |
| F3: 태그 기반 비용 분석 | `collect_tag_based_costs()` 메서드 |
| F6: Prometheus 메트릭 노출 | 메트릭 정의 및 8080 포트 서버 |
| F7: RESTful API 제공 | Flask 라우트 및 5000 포트 서버 |
| F8: 데이터 캐싱 | Redis 클라이언트 및 캐싱 로직 |
| F9: 스케줄링 기반 수집 | `run_scheduler()` 메서드 |

### 11.2 SAD 아키텍처 구현

| 아키텍처 계층 | 코드 구현 |
|-------------|-----------|
| API 계층 | Flask 라우트 및 Prometheus 서버 |
| 비즈니스 로직 계층 | 데이터 수집 및 처리 메서드들 |
| 데이터 계층 | Redis 캐시 및 AWS 클라이언트 |

### 11.3 설계도 구현

- **클래스 설계**: `EnhancedAWSCostCollector` 클래스로 구현
- **메트릭 설계**: Prometheus 메트릭 정의와 일치
- **API 설계**: REST 엔드포인트 구현
- **오류 처리**: try-catch 블록과 로깅으로 구현

---

## 12. 코드 품질 및 개선 사항

### 12.1 장점
- **모듈화**: 기능별로 메서드가 잘 분리됨
- **오류 처리**: 포괄적인 예외 처리로 안정성 확보
- **캐싱**: Redis를 활용한 효율적인 성능 최적화
- **관찰 가능성**: 로깅과 메트릭을 통한 모니터링 지원

### 12.2 개선 가능 사항
- **비동기 처리**: AWS API 호출의 비동기 처리로 성능 향상 가능
- **설정 외부화**: 하드코딩된 값들을 설정 파일로 분리
- **테스트 코드**: 단위 테스트 및 통합 테스트 추가 필요
- **문서화**: 메서드별 상세 docstring 보완

---

**문서 관리**
- **작성자**: 코드 분석가
- **검토자**: 시니어 개발자
- **승인자**: 기술 리더
- **승인일**: 2025-06-24
