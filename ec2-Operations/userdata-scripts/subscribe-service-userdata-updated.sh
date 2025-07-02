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
aws s3 cp s3://${S3_BUCKET:-your-s3-bucket-name}/subscribe-service-0.0.1-SNAPSHOT.jar /app/application.jar

chmod +x /app/application.jar

echo "🛠️ systemd 서비스 등록"
cat << EOFS > /etc/systemd/system/application.service
[Unit]
Description=Subscribe Service
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/app
ExecStart=/usr/bin/java -jar /app/application.jar
Restart=always
Environment="SPRING_PROFILES_ACTIVE=prod"
Environment="MYSQL_HOST=database-2.cb2k00gyymbm.ap-northeast-2.rds.amazonaws.com"
Environment="MYSQL_USER=admin"
Environment="MYSQL_PASSWORD=${MYSQL_PASSWORD:-secure_password_here}"
Environment="EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE=http://gpadmin:1234@43.203.16.147:8761/eureka,http://gpadmin:1234@3.34.119.43:8761/eureka"

[Install]
WantedBy=multi-user.target
EOFS

echo "✅ 서비스 시작"
sudo systemctl daemon-reload
sudo systemctl enable application
sudo systemctl start application

echo "✅ User Data 스크립트 완료!"
