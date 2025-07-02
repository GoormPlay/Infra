#!/bin/bash

# 📁 보고서 저장 경로
REPORT_DIR="/home/lch/finops-report"
mkdir -p "$REPORT_DIR"

# 📄 로그 파일
LOG_FILE="${REPORT_DIR}/report-generation.log"
> "$LOG_FILE"

# 🛠️ 리포트 정의
declare -A reports=(
  ["01_waste-analysis.md"]="서울 리전 기준, 리소스 낭비 탐지 및 절감 전략 보고서를"
  ["02_anomaly-detection.md"]="서울 리전 기준, 비용 이상징후 탐지 및 알림 분석 보고서를"
  ["03_cost-trend-forecast.md"]="서울 리전 기준, 최근 4주간 비용 트렌드 분석 및 다음달 비용 예측 보고서를"
  ["04_saving-strategies.md"]="서울 리전 기준, EC2/RDS/Lambda 절감 전략 및 세이빙 플랜 추천 보고서를"
  ["05_tag-allocation.md"]="서울 리전 기준, 태그 기반 리소스 책임 분류 및 서비스별 비용 분석 보고서를"
)

# 📦 병렬 실행 함수
run_q_chat() {
  local file="$1"
  local prompt="$2"
  echo "[`date '+%T'`] [START] $file" >> "$LOG_FILE"
  q chat --no-interactive --trust-all-tools "${prompt} ${REPORT_DIR}/${file} 에 저장해줘. 보고서 외 어떤 파일도 만들지 마." \
    && echo "[`date '+%T'`] [END]   $file 성공" >> "$LOG_FILE" \
    || echo "[`date '+%T'`] [FAIL]  $file 실패" >> "$LOG_FILE"
}

# ▶ 병렬 실행
for file in "${!reports[@]}"; do
  run_q_chat "$file" "${reports[$file]}" &
done

# ⏳ 완료 대기
wait

echo "[`date '+%T'`] [INFO] 모든 보고서 생성 완료됨" >> "$LOG_FILE"

# ✅ 최종 FinOps 종합 보고서 생성
q chat --no-interactive --trust-all-tools "
다음 5개의 보고서를 참고해서 서울 리전 기준 최종 FinOps 종합 보고서를 작성해줘. Markdown 형식으로 ${REPORT_DIR}/final_finops_summary.md 에 저장해줘. 그 외 파일은 만들지 마.

📄 참고 보고서:
1. ${REPORT_DIR}/01_waste-analysis.md
2. ${REPORT_DIR}/02_anomaly-detection.md
3. ${REPORT_DIR}/03_cost-trend-forecast.md
4. ${REPORT_DIR}/04_saving-strategies.md
5. ${REPORT_DIR}/05_tag-allocation.md

📌 보고서 목적:
- 실행 가능한 비용 최적화 인사이트 도출
- 절감 우선순위와 예상 절감액 포함
- 서비스/팀별 책임 분리
- 다음 달 예상 지출 리스크 포함
- 핵심 Action Items 정리 (예: 어떤 EC2를 중지, 어떤 팀에게 조치 권고)

🧠 형식:
- 핵심 요약
- 절감 우선순위 TOP 5
- 이상지출 원인과 대응 방안
- 태그 기반 책임 분배 분석
- 다음달 위험 항목 예측
- 조치 권장안(Action Plan)
" >> "$LOG_FILE"

# 백그라운드 아니라서 필요는 없음. 논리 구분 상 명시
wait

q chat --no-interactive --trust-all-tools "
final_finops_summary.md를 pondac, xelatex, eisvogel(FinOps 비즈니스 템플릿)를 이용해 PDF로 변환하고, 실제 회사 Finops 보고서처럼 작성해줘. 템플릿은 /home/lch/finops-report/finops-template.tex을 참고해줘. ${REPORT_DIR}/finops_report.pdf로 저장해줘."

wait

# s3 저장, 배포, slack 설정
BUCKET_NAME="finops-cur-bucket001"
REGION="ap-northeast-2"
SLACK_WEBHOOK=""

# 현재 년월 (YYYYMM)
CURRENT_MONTH=$(date +%Y%m)

# 파일 경로
OLD_FILE="${REPORT_DIR}/finops_report.pdf"
NEW_FILE="${REPORT_DIR}/finops_report_${CURRENT_MONTH}.pdf"

echo "=== FinOps 보고서 업로드 및 배포 스크립트 ==="
echo "시작 시간: $(date)"

# 1. 파일 존재 확인
if [ ! -f "$OLD_FILE" ]; then
    echo "❌ 오류: $OLD_FILE 파일이 존재하지 않습니다."
    exit 1
fi

# 2. 파일명 변경
echo "📝 파일명 변경: finops_report.pdf → finops_report_${CURRENT_MONTH}.pdf"
mv "$OLD_FILE" "$NEW_FILE"

if [ $? -eq 0 ]; then
    echo "✅ 파일명 변경 완료"
else
    echo "❌ 파일명 변경 실패"
    exit 1
fi

# 3. S3 업로드
echo "☁️  S3 업로드 시작..."
aws s3 cp "$NEW_FILE" "s3://${BUCKET_NAME}/" --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ S3 업로드 완료"
else
    echo "❌ S3 업로드 실패"
    exit 1
fi

# 4. Pre-signed URL 생성 (3일 = 259200초)
echo "🔗 Pre-signed URL 생성 중..."
PRESIGNED_URL=$(aws s3 presign "s3://${BUCKET_NAME}/$(basename $NEW_FILE)" --expires-in 259200 --region "$REGION")

if [ $? -eq 0 ]; then
    echo "✅ Pre-signed URL 생성 완료"
    echo "URL: $PRESIGNED_URL"
else
    echo "❌ Pre-signed URL 생성 실패"
    exit 1
fi

# 5. 파일 크기 확인
FILE_SIZE=$(stat -c%s "$NEW_FILE")
FILE_SIZE_KB=$((FILE_SIZE / 1024))

# 6. 만료 날짜 계산
EXPIRE_DATE=$(date -d '+3 days' '+%m/%d %H:%M')

# 7. Slack 메시지 전송
echo "💬 Slack 메시지 전송 중..."
curl -X POST -H 'Content-type: application/json' \
--data "{
  \"text\": \"*FinOps $(date +%m)월 비용 분석 보고서*\n:memo: *문서:* 월간 비용 분석 보고서 (${FILE_SIZE_KB}KB)\n:chart_with_upwards_trend: *내용:* AWS 비용 최적화 및 절감 전략\n:clock3: *유효기간:* 72시간 (${EXPIRE_DATE}까지)\n:link: *다운로드:*\n${PRESIGNED_URL}\n:warning: *기밀문서 - 승인된 관계자만 액세스*\"
}" \
"$SLACK_WEBHOOK"

if [ $? -eq 0 ]; then
    echo "✅ Slack 메시지 전송 완료"
else
    echo "❌ Slack 메시지 전송 실패"
fi

echo "=== 작업 완료 ==="
echo "완료 시간: $(date)"
echo "업로드된 파일: $(basename $NEW_FILE)"
echo "S3 위치: s3://${BUCKET_NAME}/$(basename $NEW_FILE)"
echo "유효기간: 72시간 (${EXPIRE_DATE}까지)"


