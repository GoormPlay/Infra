# GoormPlay EC2 배포

이 Terraform 구성은 GoormPlay 애플리케이션의 각 마이크로서비스를 위한 EC2 인스턴스를 배포합니다.

## 배포되는 서비스

- Eureka 서비스 디스커버리
- UI 서비스
- 사용자 액션 테스트 서비스
- 구독 서비스
- 인증 서비스
- 인덱싱 서비스
- 리뷰 서비스
- 콘텐츠 서비스
- 회원 서비스
- 광고 서비스
- API 게이트웨이 서비스

## 구성 세부 정보

- 리전: 서울 (ap-northeast-2)
- 인스턴스 유형: t2.small
- AMI: ami-090190993f1fe3eac (Ubuntu)
- 서브넷 ID: subnet-00c246ce288c3cbf8
- 보안 그룹: sg-08dfb9c0d61c0062a
- 키 페어: test
- IAM 인스턴스 프로파일: ec2-ami-msa

## 사용 방법

1. Terraform 초기화:
   ```
   terraform init
   ```

2. 배포 계획 검토:
   ```
   terraform plan
   ```

3. 구성 적용:
   ```
   terraform apply
   ```

4. 인프라 삭제:
   ```
   terraform destroy
   ```

## 출력 값

- `instance_public_ips`: 배포된 모든 인스턴스의 공개 IP 주소
- `instance_private_ips`: 배포된 모든 인스턴스의 사설 IP 주소
- `instance_ids`: 배포된 모든 인스턴스의 ID
