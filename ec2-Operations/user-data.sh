#!/bin/bash

# 로그 기록
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "🚀 시작: 시스템 업데이트"
apt-get update -y
apt-get install -y openjdk-17-jdk awscli

echo "📁 /app 디렉토리 생성"
mkdir -p /app
chown ubuntu:ubuntu /app

echo "⬇️ JAR 파일 다운로드"
# S3 버킷과 JAR 파일명을 환경변수로 설정
S3_BUCKET=${S3_BUCKET:-"your-s3-bucket-name"}
JAR_FILE=${JAR_FILE:-"apigateway-service-0.0.1-SNAPSHOT.jar"}
aws s3 cp s3://${S3_BUCKET}/${JAR_FILE} /app/application.jar



chmod +x /app/application.jar

echo "🛠️ systemd 서비스 등록"
cat << EOF > /etc/systemd/system/application.service
[Unit]
Description=Spring Boot Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/app
ExecStart=/usr/bin/java -jar /app/application.jar
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "✅ 서비스 시작"
sudo systemctl daemon-reload
sudo systemctl enable application
sudo systemctl start application


echo "✅ User Data 스크립트 완료!"
