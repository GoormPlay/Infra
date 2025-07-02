#!/bin/bash

# CloudWatch Agent 설치 및 구성 스크립트 (이상징후 탐지 최적화)
# 1주일 데이터 수집에 최적화된 버전

# 1. CloudWatch Agent 설치
echo "🛠️ CloudWatch Agent 설치 중..."

# 시스템 아키텍처 확인
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
  ARCH_DEB="amd64"
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_DEB="arm64"
else
  echo "❌ 지원되지 않는 아키텍처: $ARCH"
  exit 1
fi

# 필요한 패키지 설치
sudo apt update -y
sudo apt install -y wget unzip

# CloudWatch Agent 다운로드 및 설치
echo "📥 CloudWatch Agent 패키지 다운로드 중..."
wget -O /tmp/amazon-cloudwatch-agent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/$ARCH_DEB/latest/amazon-cloudwatch-agent.deb

if [ $? -ne 0 ]; then
  echo "❌ CloudWatch Agent 패키지 다운로드 실패"
  exit 1
fi

echo "📦 CloudWatch Agent 패키지 설치 중..."
sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb
if [ $? -ne 0 ]; then
  echo "❌ CloudWatch Agent 패키지 설치 실패"
  exit 1
fi

# 의존성 문제 해결
sudo apt-get install -f -y

# 2. 구성 파일 생성 (이상징후 탐지용 메트릭 및 로그 포함)
echo "📝 CloudWatch Agent 구성 파일 작성 중..."

sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/bin/
sudo tee /opt/aws/amazon-cloudwatch-agent/bin/config.json > /dev/null <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root",
    "region": "$(curl -s http://169.254.169.254/latest/meta-data/placement/region)"
  },
  "metrics": {
    "append_dimensions": {
      "InstanceId": "\${aws:InstanceId}",
      "InstanceType": "\${aws:InstanceType}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent",
          "mem_available"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent",
          "inodes_used"
        ],
        "resources": ["/"],
        "metrics_collection_interval": 60
      },
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": true
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "processes": {
        "measurement": [
          "running",
          "blocked",
          "zombies"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/syslog",
            "log_group_name": "system-logs",
            "log_stream_name": "{instance_id}-syslog",
            "retention_in_days": 7
          },
          {
            "file_path": "/var/log/auth.log",
            "log_group_name": "security-logs",
            "log_stream_name": "{instance_id}-auth",
            "retention_in_days": 7
          }
        ]
      }
    },
    "force_flush_interval": 15
  }
}
EOF

# 3. CloudWatch Agent 시작
echo "🚀 CloudWatch Agent 시작 중..."

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
  -s

# 4. 시스템 재부팅 시 CloudWatch Agent 자동 시작 설정
echo "⚙️ 시스템 재부팅 시 자동 시작 설정 중..."
sudo systemctl enable amazon-cloudwatch-agent

# 5. CloudWatch Agent 상태 확인
sleep 3  # 에이전트가 시작될 시간을 조금 줍니다
if systemctl is-active --quiet amazon-cloudwatch-agent; then
  echo "✅ CloudWatch Agent가 성공적으로 실행 중입니다."
  echo "✅ 이 인스턴스로 AMI를 생성하면 CloudWatch 메트릭 수집이 설정된 상태로 유지됩니다."
else
  echo "❌ CloudWatch Agent 실행 실패. 로그를 확인하세요: /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
  exit 1
fi

# 6. 이상징후 탐지 설정 안내
echo ""
echo "📊 이상징후 탐지 설정 안내:"
echo "  1. 최소 1주일 동안 데이터를 수집하세요 (권장: 2주)"
echo "  2. AWS CloudWatch 콘솔에서 수집된 메트릭을 선택하세요"
echo "  3. '그래프로 표시된 지표' 탭에서 '이상 탐지' 옵션을 활성화하세요"
echo "  4. 필요한 경우 이상징후 탐지 임계값을 조정하세요"
echo ""
echo "🔔 알림 설정 방법:"
echo "  1. CloudWatch 콘솔에서 '경보 생성'을 선택하세요"
echo "  2. 이상징후 탐지를 기반으로 경보를 설정하세요"
echo "  3. SNS 주제를 통해 이메일 또는 SMS 알림을 구성하세요"
echo ""
echo "🔑 참고: 이 AMI로 생성된 인스턴스에는 CloudWatch 메트릭을 게시할 수 있는 IAM 역할이 필요합니다."
echo "   인스턴스 시작 시 CloudWatchAgentServerPolicy가 연결된 IAM 역할을 지정하세요."

# 7. 임시 파일 정리
rm -f /tmp/amazon-cloudwatch-agent.deb
