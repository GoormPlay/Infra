#!/bin/bash

#  보고서 저장 경로
REPORT_DIR="/home/lch/finops-report"
mkdir -p "$REPORT_DIR"

#  로그 파일
LOG_FILE="${REPORT_DIR}/report-generation.log"
> "$LOG_FILE"

# 리포트 정의
declare -A reports=(
  ["01_waste-analysis.md"]="서울 리전 기준, 리소스 낭비 탐지 및 절감 전략 보고서를"
  ["02_anomaly-detection.md"]="서울 리전 기준, 비용 이상징후 탐지 및 알림 분석 보고서를"
  ["03_cost-trend-forecast.md"]="서울 리전 기준, 최근 4주간 비용 트렌드 분석 및 다음달 비용 예측 보고서를"
  ["04_saving-strategies.md"]="서울 리전 기준, EC2/RDS/Lambda 절감 전략 및 세이빙 플랜 추천 보고서를"
  ["05_tag-allocation.md"]="서울 리전 기준, 태그 기반 리소스 책임 분류 및 서비스별 비용 분석 보고서를"
)

#  병렬 실행 함수
run_q_chat() {
  local file="$1"
  local prompt="$2"
  echo "[`date '+%T'`] [START] $file" >> "$LOG_FILE"
  q chat --no-interactive --trust-all-tools "${prompt} ${REPORT_DIR}/${file} 에 저장해줘. 보고서 외 어떤 파일도 만들지 마." \
    && echo "[`date '+%T'`] [END]   $file 성공" >> "$LOG_FILE" \
    || echo "[`date '+%T'`] [FAIL]  $file 실패" >> "$LOG_FILE"
}

#  1. 병렬 실행
for file in "${!reports[@]}"; do
  run_q_chat "$file" "${reports[$file]}" &
done

#  2. 완료 대기
wait

echo "[`date '+%T'`] [INFO] 모든 보고서 생성 완료됨" >> "$LOG_FILE"

# 3. 최종 FinOps 종합 보고서 생성
q chat --no-interactive --trust-all-tools "
다음 5개의 보고서를 참고해서 서울 리전 기준 최종 FinOps 종합 보고서를 작성해줘. Markdown 형식으로 ${REPORT_DIR}/final_finops_summary.md 에 저장해줘. 그 외 파일은 만들지 마.

 참고 보고서:
1. ${REPORT_DIR}/01_waste-analysis.md
2. ${REPORT_DIR}/02_anomaly-detection.md
3. ${REPORT_DIR}/03_cost-trend-forecast.md
4. ${REPORT_DIR}/04_saving-strategies.md
5. ${REPORT_DIR}/05_tag-allocation.md

 보고서 목적:
- 실행 가능한 비용 최적화 인사이트 도출
- 절감 우선순위와 예상 절감액 포함
- 서비스/팀별 책임 분리
- 다음 달 예상 지출 리스크 포함
- 핵심 Action Items 정리 (예: 어떤 EC2를 중지, 어떤 팀에게 조치 권고)

 형식:
- 핵심 요약
- 절감 우선순위 TOP 5
- 이상지출 원인과 대응 방안
- 태그 기반 책임 분배 분석
- 다음달 위험 항목 예측
- 조치 권장안(Action Plan)
" >> "$LOG_FILE"

#  4. 완료 대기
wait

#  5. 최종 FinOps 종합 보고서  PDF 변환 및 템플릿 적용
q chat --no-interactive --trust-all-tools "
final_finops_summary.md를 pondac, xelatex, eisvogel(FinOps 비즈니스 템플릿)를 이용해 PDF로 변환하고, 실제 회사 Finops 보고서처럼 작성해줘. 템플릿은 /home/lch/finops-report/finops-template.tex을 참고해줘." 