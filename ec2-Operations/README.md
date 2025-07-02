# EC2 Operations Management

AWS EC2 인스턴스의 자동화된 배포, 설정, 모니터링을 위한 보안 강화된 운영 도구 모음입니다.

## 📋 개요

이 디렉토리는 마이크로서비스 아키텍처를 위한 EC2 인스턴스 관리 도구들을 포함합니다. Terraform을 통한 인프라 코드 관리, 자동화된 애플리케이션 배포, CloudWatch 모니터링 설정을 제공하며, 보안 모범 사례를 준수합니다.

## 🔒 보안 주의사항

**⚠️ 중요: 이 저장소를 Public으로 설정하기 전에 다음 사항을 확인하세요:**

- 모든 민감정보가 환경변수로 처리되었는지 확인
- `.env` 파일이 `.gitignore`에 포함되었는지 확인  
- Terraform 상태 파일이 Git에서 제외되었는지 확인
- AWS 자격 증명이 하드코딩되지 않았는지 확인

## 📁 파일 구조

### 🚀 배포 스크립트
- `user-data.sh` - EC2 인스턴스 초기 설정 및 애플리케이션 자동 배포
- `cloudwatch-agent.sh` - CloudWatch 에이전트 설치 및 모니터링 설정
- `log-auto.sh` - 로그 자동화 스크립트 (개발 중)

### 📂 UserData 스크립트
- `userdata-scripts/` - 각 마이크로서비스별 개별 배포 스크립트
  - `eureka-userdata.sh` - 서비스 디스커버리
  - `*-service-userdata-updated.sh` - 각 마이크로서비스별 스크립트

### 🏗️ Terraform 인프라 코드
- `terraform-ec2/` - EC2 인스턴스 프로비저닝을 위한 Terraform 구성

### 🔒 보안 파일
- `.env.example` - 환경변수 템플릿 파일
- `.gitignore` - Git에서 제외할 민감 파일 목록

## 🎯 주요 기능

### 1. 자동화된 애플리케이션 배포
- **Spring Boot 애플리케이션** 자동 다운로드 및 설치
- **Systemd 서비스** 자동 등록 및 시작
- **Java 17** 환경 자동 구성
- **AWS CLI** 설치 및 설정

### 2. 마이크로서비스 아키텍처 지원
지원하는 서비스들:
- `eureka` - 서비스 디스커버리
- `UI-service` - 사용자 인터페이스
- `userAction-test-service` - 사용자 액션 테스트
- `subscribe-service` - 구독 서비스
- `auth-service` - 인증 서비스
- `indexing-service` - 인덱싱 서비스
- `review-service` - 리뷰 서비스
- `content-service` - 콘텐츠 서비스
- `member-service` - 회원 서비스
- `ad-service` - 광고 서비스
- `apigateway-service` - API 게이트웨이

### 3. 종합 모니터링
- **CloudWatch 메트릭** 수집 (CPU, 메모리, 디스크, 네트워크)
- **애플리케이션 로그** 자동 수집
- **이상 징후 탐지** 최적화된 설정
- **실시간 알림** 시스템

## 🚀 사용 방법

### 0. 환경 설정 (필수)

**환경변수 설정:**
```bash
# .env.example을 복사하여 실제 값으로 설정
cp .env.example .env
# .env 파일을 편집하여 실제 값 입력
nano .env
```

**필수 환경변수:**
- `AWS_REGION`: AWS 리전 (예: ap-northeast-2)
- `S3_BUCKET`: JAR 파일이 저장된 S3 버킷명
- `MYSQL_PASSWORD`: 데이터베이스 비밀번호
- `KEY_NAME`: EC2 키 페어 이름

### 1. Terraform을 통한 인프라 배포

```bash
cd terraform-ec2

# 환경변수 로드
source ../.env

# Terraform 초기화
terraform init

# 배포 계획 확인
terraform plan -var="key_name=${KEY_NAME}"

# 인프라 배포
terraform apply -var="key_name=${KEY_NAME}"
```

### 2. 개별 EC2 인스턴스 설정

#### User Data 스크립트 사용
```bash
# 환경변수 설정 후 EC2 인스턴스 생성 시 User Data로 사용
export S3_BUCKET="your-s3-bucket-name"
export JAR_FILE="your-application.jar"
cat user-data.sh
```

#### CloudWatch 에이전트 설치
```bash
# 기존 인스턴스에 CloudWatch 에이전트 설치
chmod +x cloudwatch-agent.sh
sudo ./cloudwatch-agent.sh
```

### 3. 애플리케이션 상태 확인

```bash
# 서비스 상태 확인
sudo systemctl status application.service

# 애플리케이션 로그 확인
sudo journalctl -u application.service -f

# CloudWatch 에이전트 상태 확인
sudo systemctl status amazon-cloudwatch-agent
```

## ⚙️ 구성 상세

### User Data 스크립트 (`user-data.sh`)

**주요 작업:**
1. **시스템 업데이트** 및 필수 패키지 설치
2. **Java 17** 및 **AWS CLI** 설치
3. **S3에서 JAR 파일** 다운로드
4. **Systemd 서비스** 등록 및 자동 시작 설정
5. **로그 기록** 및 모니터링 설정

**S3 버킷 설정:**
```bash
# 환경변수로 관리 (보안 강화)
S3_BUCKET=${S3_BUCKET:-"your-s3-bucket-name"}
JAR_FILE=${JAR_FILE:-"your-application.jar"}
```

**데이터베이스 연결:**
```bash
# 환경변수로 관리 (하드코딩 금지)
MYSQL_PASSWORD=${MYSQL_PASSWORD:-"secure_password_here"}
MYSQL_HOST=${MYSQL_HOST:-"your-rds-endpoint"}
```

### CloudWatch 에이전트 (`cloudwatch-agent.sh`)

**수집 메트릭:**
- **시스템 메트릭**: CPU, 메모리, 디스크, 네트워크
- **애플리케이션 메트릭**: JVM 메트릭, 애플리케이션 로그
- **커스텀 메트릭**: 비즈니스 로직 관련 메트릭

**로그 수집:**
- `/var/log/user-data.log` - 인스턴스 초기화 로그
- `/var/log/application.log` - 애플리케이션 로그
- `/var/log/syslog` - 시스템 로그

### Terraform 구성 (`terraform-ec2/`)

**리소스:**
- **EC2 인스턴스**: 각 마이크로서비스별 전용 인스턴스
- **보안 그룹**: 서비스별 네트워크 접근 제어
- **태그 관리**: 프로젝트 및 환경별 리소스 분류

**변수 설정:**
```hcl
# variables.tf에서 설정 가능한 값들
variable "region" {
  default = "ap-northeast-2"  # 서울 리전
}

variable "ami_id" {
  description = "Ubuntu AMI ID"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
}
```

## 📊 모니터링 및 알림

### CloudWatch 대시보드
- **인스턴스 상태**: CPU, 메모리, 네트워크 사용률
- **애플리케이션 성능**: 응답 시간, 처리량, 오류율
- **비용 모니터링**: 인스턴스별 비용 추적

### 알림 설정
```bash
# CPU 사용률 80% 초과 시 알림
# 메모리 사용률 85% 초과 시 알림
# 디스크 사용률 90% 초과 시 알림
# 애플리케이션 오류 발생 시 알림
```

## 🔧 문제 해결

### 일반적인 문제들

#### 1. 애플리케이션 시작 실패
```bash
# 로그 확인
sudo journalctl -u application.service -n 50

# JAR 파일 확인
ls -la /app/application.jar

# Java 버전 확인
java -version
```

#### 2. CloudWatch 에이전트 문제
```bash
# 에이전트 상태 확인
sudo systemctl status amazon-cloudwatch-agent

# 구성 파일 확인
sudo cat /opt/aws/amazon-cloudwatch-agent/bin/config.json

# 에이전트 재시작
sudo systemctl restart amazon-cloudwatch-agent
```

#### 3. Terraform 배포 오류
```bash
# 상태 확인
terraform show

# 리소스 새로고침
terraform refresh

# 특정 리소스 재생성
terraform taint aws_instance.service_instances["eureka"]
terraform apply
```

### 로그 위치
- **User Data 로그**: `/var/log/user-data.log`
- **애플리케이션 로그**: `/var/log/application.log`
- **CloudWatch 에이전트 로그**: `/opt/aws/amazon-cloudwatch-agent/logs/`
- **Terraform 상태**: `terraform-ec2/terraform.tfstate` (Git에서 제외됨)

## ⚠️ Public Repository 체크리스트

이 저장소를 Public으로 만들기 전에 다음 사항을 확인하세요:

- [ ] 모든 `.env` 파일이 `.gitignore`에 포함되었는가?
- [ ] Terraform 상태 파일이 Git에서 제외되었는가?
- [ ] 하드코딩된 비밀번호가 모두 환경변수로 변경되었는가?
- [ ] S3 버킷명이 환경변수로 처리되었는가?
- [ ] AWS 자격 증명이 코드에 포함되지 않았는가?
- [ ] 키 파일(.pem)이 Git에서 제외되었는가?
- [ ] 실제 도메인명이나 IP 주소가 노출되지 않았는가?

## 🔧 보안 검증 명령어

```bash
# 민감정보 검색
grep -r -i "password\|secret\|key\|token" . --exclude-dir=.git --exclude="*.md"

# 환경변수 사용 확인
grep -r "\${.*}" . --include="*.sh"

# .gitignore 적용 확인
git status --ignored
```

## 🔐 보안 고려사항

### 환경변수 관리
**필수 환경변수 설정:**
```bash
# .env 파일 생성 (Git에서 제외됨)
cp .env.example .env

# 실제 값으로 편집
AWS_REGION=ap-northeast-2
S3_BUCKET=your-actual-bucket-name
MYSQL_PASSWORD=your-secure-password
KEY_NAME=your-key-pair-name
```

### IAM 권한
EC2 인스턴스에 필요한 최소 권한:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    }
  ]
}
```

### Git 보안
**중요 파일들이 Git에서 제외되는지 확인:**
```bash
# .gitignore에 포함된 파일들
*.tfstate*          # Terraform 상태 파일
.env               # 환경변수 파일
*.pem              # 키 파일
*.log              # 로그 파일
terraform.tfvars   # Terraform 변수 파일
```

### 네트워크 보안
- **보안 그룹**: 필요한 포트만 개방
- **VPC**: 프라이빗 서브넷 사용 권장
- **SSL/TLS**: HTTPS 통신 설정

## 📈 성능 최적화

### 인스턴스 타입 권장사항
- **개발 환경**: t3.micro, t3.small
- **스테이징**: t3.medium, t3.large
- **프로덕션**: c5.large, m5.large 이상

### 자동 스케일링
```bash
# Auto Scaling Group 설정 (향후 추가 예정)
# Load Balancer 연동
# Health Check 설정
```

## 📅 유지보수

### 정기 작업
- **월간**: AMI 업데이트 및 보안 패치
- **주간**: 로그 정리 및 디스크 공간 확인
- **일간**: 애플리케이션 상태 및 성능 모니터링

### 백업 전략
- **EBS 스냅샷**: 일일 자동 백업
- **애플리케이션 데이터**: S3 백업
- **구성 파일**: Git 버전 관리

---

**마지막 업데이트**: 2025-07-02  
**대상 리전**: ap-northeast-2 (서울)  
**보안 상태**: 민감정보 제거 완료  
**Public Repository**: 준비 완료
