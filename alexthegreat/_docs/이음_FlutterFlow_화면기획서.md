# 이음 (Ieum) — FlutterFlow 화면 기획서

> **작성일:** 2026-05-06  
> **플랫폼:** FlutterFlow  
> **목적:** 취미 매치 앱 화면 설계 및 개발 의뢰용  
> **태그:** #이음 #FlutterFlow #화면기획 #취미매칭 #UI설계

---

## 📌 전체 화면 흐름 (User Flow)

```
[Screen 1] 로그인 화면
        ↓ Google 로그인 (등록된 이메일만 허용)
[Screen 2] 취향 조사 (온보딩 질문 리스트)
        ↓ 질문 완료
[Screen 3] 홈 피드 (맞춤 모임 공고)
        ↓ 카테고리 선택
[Screen 4] 카테고리 상세 (가요 / 뮤지컬 / 조향 / 러닝 등)
        ↓ 공고 선택
[Screen 5] 모임 상세 & 신청
```

---

## Screen 1 — 로그인 화면

### 개요
앱의 첫 진입 화면. **등록된 이메일을 가진 사용자만** Google 계정으로 로그인 가능.

### 화면 구성 요소

| 요소 | 타입 | 설명 |
|------|------|------|
| 앱 로고 | Image / Text | "이음" 로고 중앙 배치 |
| 앱 슬로건 | Text | "나의 취미를 이음" |
| Google 로그인 버튼 | Button (OAuth) | Google Sign-In 공식 스타일 적용 |
| 안내 문구 | Text | "초대받은 이메일로만 로그인 가능합니다" |

### FlutterFlow 설정 지침

```
1. Authentication 설정
   - Firebase Authentication 활성화
   - Google Sign-In Provider 활성화
   - Firestore에 'allowed_users' 컬렉션 생성
     └ 필드: email (String), created_at (Timestamp), is_active (Boolean)

2. 로그인 로직 (Action Flow)
   Step 1. Google Sign-In 실행
   Step 2. 로그인된 이메일을 Firestore 'allowed_users' 컬렉션에서 조회
   Step 3-A. 이메일 존재 & is_active = true → Screen 2 또는 Screen 3으로 이동
   Step 3-B. 이메일 없거나 is_active = false → 로그아웃 처리 후 안내 AlertDialog 표시
             AlertDialog 내용: "등록되지 않은 이메일입니다. 관리자에게 문의해주세요."

3. 온보딩 완료 여부 체크
   - Firestore 'users' 컬렉션에 onboarding_completed (Boolean) 필드
   - true이면 → Screen 3 (홈 피드)
   - false이면 → Screen 2 (취향 조사)
```

### 디자인 가이드

```
배경: 흰색 또는 연한 크림 (#FAFAF8)
로고 폰트: 세리프 계열 (Noto Serif KR 권장)
슬로건 폰트: 본고딕 / Noto Sans KR Light
Google 버튼: 공식 Google Sign-In 버튼 가이드라인 준수
  - 배경: 흰색, 테두리: #DADCE0, 텍스트: #3C4043
버튼 위치: 화면 하단 30% 지점
```

---

## Screen 2 — 취향 조사 (온보딩 질문)

### 개요
최초 로그인 사용자에게 표시되는 취향·성향 파악 설문.  
결과를 바탕으로 홈 피드의 모임 공고를 개인화 추천.

### 질문 구성 (총 10문항)

#### 파트 A — 라이프스타일 (3문항)

**Q1. 평소 여가 시간에 주로 무엇을 하시나요?**
```
선택지 (복수 선택 가능):
□ 음악 듣기 / 노래 부르기
□ 영화 · 공연 관람
□ 야외 활동 (걷기, 달리기 등)
□ 만들기 · 공예
□ 독서 · 글쓰기
□ 기타
```

**Q2. 선호하는 활동 시간대는?**
```
선택지 (단일 선택):
○ 평일 저녁 (7시 이후)
○ 주말 오전
○ 주말 오후
○ 시간 무관
```

**Q3. 취미에 투자 가능한 월 예산은?**
```
선택지 (단일 선택):
○ 5만원 이하
○ 5~15만원
○ 15~30만원
○ 30만원 이상
```

---

#### 파트 B — 성향 파악 (4문항)

**Q4. 새로운 것을 배울 때 나는?**
```
선택지:
○ 혼자 조용히 배우는 편 (독립형)
○ 선생님께 배우는 걸 좋아함 (교습형)
○ 친구·동료와 함께 배워야 신남 (그룹형)
```

**Q5. 취미를 통해 가장 원하는 것은?**
```
선택지 (복수 선택, 최대 2개):
□ 스트레스 해소 / 힐링
□ 새로운 사람들과의 만남
□ 특정 기술 습득 / 성취감
□ 무대 · 발표 경험
□ 건강 & 체력 향상
```

**Q6. 나의 활동 스타일은?**
```
슬라이더 또는 선택지:
○ 정적인 활동 선호 (앉아서, 집중해서)
○ 중간
○ 동적인 활동 선호 (몸을 움직이며)
```

**Q7. 취미 활동에서 '함께하는 사람'의 중요도는?**
```
별점 슬라이더: 1점(별로 중요하지 않음) ~ 5점(매우 중요함)
```

---

#### 파트 C — 관심 분야 (3문항)

**Q8. 관심 있는 취미 분야를 선택해주세요 (복수 선택)**
```
카드형 선택 UI:
□ 🎵 가요 (보컬, 작곡, 음악 감상)
□ 🎭 뮤지컬 (연기, 노래, 무대)
□ 🌸 조향 (향수 제작, 아로마테라피)
□ 🏃 러닝 (크루, 마라톤, 트레일)
□ 🎨 그림 · 드로잉
□ 📸 사진 · 영상
□ 🍳 요리 · 베이킹
□ 💃 댄스 (현대무용, K팝 댄스 등)
□ 기타 (직접 입력)
```

**Q9. 현재 해당 분야 경험이 있나요?**
```
선택지:
○ 완전 초보 (처음 시작)
○ 약간의 경험 있음
○ 꽤 해봤음 (중급 이상)
```

**Q10. 원하는 모임 형태는?**
```
선택지 (복수 선택):
□ 정기 클래스 (주 1~2회 정해진 수업)
□ 원데이 클래스 (1회성 체험)
□ 자율 모임 (멤버들끼리 자체 운영)
□ 온라인 모임
□ 오프라인 모임만
```

### FlutterFlow 설정 지침

```
1. 화면 구조
   - PageView 또는 Stepper 컴포넌트로 질문 1개씩 전환
   - 상단 Progress Bar (질문 진행률 표시)
   - 하단 "다음" 버튼 (마지막 질문에서는 "완료")

2. 데이터 저장
   - App State에 각 답변 임시 저장
   - 완료 시 Firestore 'users/{uid}/preferences' 문서에 저장
   - 저장 완료 후 onboarding_completed = true 업데이트

3. Firestore 'users' 문서 구조
   {
     uid: String,
     email: String,
     display_name: String,
     photo_url: String,
     onboarding_completed: Boolean,
     created_at: Timestamp,
     preferences: {
       leisure_activities: [String],   // Q1
       preferred_time: String,          // Q2
       monthly_budget: String,          // Q3
       learning_style: String,          // Q4
       hobby_goals: [String],           // Q5
       activity_style: String,          // Q6
       social_importance: Number,       // Q7 (1~5)
       interest_categories: [String],   // Q8
       experience_level: String,        // Q9
       meeting_type: [String]           // Q10
     }
   }
```

---

## Screen 3 — 홈 피드 (맞춤 모임 공고)

### 개요
취향 조사 결과를 바탕으로 **개인화된 모임 공고**를 피드 형태로 표시.

### 화면 구성 요소

| 영역 | 구성 |
|------|------|
| 상단 헤더 | 로고 + 알림 아이콘 + 프로필 아이콘 |
| 카테고리 탭 | 전체 / 가요 / 뮤지컬 / 조향 / 러닝 / + 더보기 |
| 추천 배너 | "OO님을 위한 추천 모임" 섹션 (수평 스크롤 카드) |
| 모임 공고 피드 | 세로 스크롤 카드 리스트 |
| 하단 네비게이션 | 홈 / 탐색 / 내 모임 / 프로필 |

### 모임 공고 카드 구성

```
┌────────────────────────────────┐
│ [카테고리 태그] 🎵 가요         │
│                                │
│ 제목: 홍대 보컬 크루 모집       │
│ 강사: 김보컬 (전 뮤지컬 배우)  │
│                                │
│ 📅 매주 화·목 저녁 7시         │
│ 📍 마포구 홍대입구역 근처      │
│ 👥 모집 인원: 6/10명          │
│ 💰 월 12만원                  │
│                    [신청하기 →] │
└────────────────────────────────┘
```

### Firestore 'meetings' 컬렉션 구조

```json
{
  "id": "meeting_001",
  "title": "홍대 보컬 크루 모집",
  "category": "가요",
  "subcategory": "보컬",
  "instructor": {
    "name": "김보컬",
    "bio": "전 뮤지컬 배우 출신",
    "photo_url": ""
  },
  "schedule": "매주 화·목 저녁 7시",
  "location": "마포구 홍대입구역 근처",
  "max_members": 10,
  "current_members": 6,
  "monthly_fee": 120000,
  "tags": ["초보환영", "정기모임", "오프라인"],
  "description": "상세 설명...",
  "is_active": true,
  "created_at": "Timestamp",
  "target_preferences": {
    "activity_style": ["정적", "중간"],
    "meeting_type": ["정기 클래스"],
    "budget_range": ["5~15만원", "15~30만원"]
  }
}
```

---

## 취미 카테고리 정의

### 🎵 가요 (K-POP & 보컬)

| 모임 유형 | 설명 |
|-----------|------|
| 보컬 트레이닝 | 발성·호흡·음정 교정 소규모 클래스 |
| 작곡·편곡 | 기초 이론부터 DAW 활용 |
| 버스킹 크루 | 정기 버스킹 공연 팀 |
| 가요 무대 서기 | 소규모 발표회·공연 무대 경험 |

**추천 대상 키워드:** 노래 좋아함, 무대 경험 원함, 정적 활동, 성취감

---

### 🎭 뮤지컬 (Musical)

| 모임 유형 | 설명 |
|-----------|------|
| 뮤지컬 워크숍 | 기초 연기·노래·안무 통합 수업 |
| 낭독 공연 | 대본 낭독 + 소품 공연 |
| 뮤지컬 무대 서기 | 소극장 무대 발표 프로젝트 |
| 뮤지컬 감상 모임 | 공연 관람 후 리뷰 토론 모임 |

**추천 대상 키워드:** 무대 경험, 사람과 함께, 그룹형, 동적 활동

---

### 🌸 조향 (Perfumery)

| 모임 유형 | 설명 |
|-----------|------|
| 원데이 조향 클래스 | 1회성 나만의 향수 만들기 |
| 조향 정규 과정 | 8~12주 과정, 조향 기초~중급 |
| 향수 감상 모임 | 매월 다른 테마의 향수 탐구 |
| 아로마테라피 | 생활 아로마·에센셜 오일 활용 |

**추천 대상 키워드:** 정적 활동, 혼자/소수, 만들기, 힐링

---

### 🏃 러닝 (Running)

| 모임 유형 | 설명 |
|-----------|------|
| 러닝 크루 | 정기 러닝 + 커뮤니티 |
| 마라톤 준비반 | 5K·10K·하프 대회 준비 |
| 트레일 러닝 | 산악 러닝 모임 |
| 러닝 + 브런치 | 런&소셜 가벼운 모임 |

**추천 대상 키워드:** 동적 활동, 건강, 사람과 함께, 야외

---

## FlutterFlow 개발 우선순위

### Phase 1 (MVP) — 필수 구현

- [x] Screen 1: Google 로그인 + 이메일 허용 목록 검증
- [x] Screen 2: 취향 조사 10문항 (PageView 방식)
- [x] Screen 3: 홈 피드 + 카테고리 탭
- [x] Firestore 연동 (users, meetings, allowed_users 컬렉션)

### Phase 2 — 추가 기능

- [ ] Screen 4: 카테고리 상세 페이지
- [ ] Screen 5: 모임 상세 + 신청 기능
- [ ] 알림 기능 (신규 모임 공고 Push)
- [ ] 내 모임 관리 페이지

### Phase 3 — AI 에이전트 연동

- [ ] 취향 분석 → GPT/Claude API 연동
- [ ] 자연어 취향 조사 (챗봇 형태로 진화)
- [ ] 실시간 모임 추천 재학습

---

## Firestore 컬렉션 구조 요약

```
Firestore
├── allowed_users/          # 로그인 허용 이메일 목록
│   └── {docId}
│       ├── email: String
│       ├── is_active: Boolean
│       └── created_at: Timestamp
│
├── users/                  # 사용자 정보 & 취향
│   └── {uid}
│       ├── email, display_name, photo_url
│       ├── onboarding_completed: Boolean
│       └── preferences: Map
│
├── meetings/               # 모임 공고
│   └── {meetingId}
│       ├── title, category, subcategory
│       ├── instructor: Map
│       ├── schedule, location
│       ├── max_members, current_members
│       ├── monthly_fee
│       ├── tags: [String]
│       ├── is_active: Boolean
│       └── target_preferences: Map
│
└── applications/           # 모임 신청 내역
    └── {applicationId}
        ├── user_uid: String
        ├── meeting_id: String
        ├── status: String (pending / approved / rejected)
        └── applied_at: Timestamp
```

---

## 디자인 시스템

### 컬러 팔레트

| 역할 | 색상 | HEX |
|------|------|-----|
| Primary | 딥 세이지 그린 | `#3D6B5A` |
| Secondary | 웜 크림 | `#F5F0E8` |
| Accent | 소프트 테라코타 | `#C87B5A` |
| Background | 오프화이트 | `#FAFAF8` |
| Text Primary | 차콜 | `#2C2C2C` |
| Text Secondary | 그레이 | `#888780` |

### 타이포그래피

| 용도 | 폰트 | 크기 |
|------|------|------|
| 앱 이름 (이음) | Noto Serif KR Bold | 32px |
| 헤딩 | Noto Sans KR Bold | 20px |
| 본문 | Noto Sans KR Regular | 14px |
| 캡션 | Noto Sans KR Light | 12px |

### 카테고리 컬러 코드

| 카테고리 | 컬러 | HEX |
|----------|------|-----|
| 🎵 가요 | 소프트 퍼플 | `#8B7BB5` |
| 🎭 뮤지컬 | 골드 | `#C9A84C` |
| 🌸 조향 | 로즈 핑크 | `#C47B8A` |
| 🏃 러닝 | 리프 그린 | `#5A9E6F` |

---

*이 문서는 FlutterFlow 개발 의뢰용 화면 기획서입니다.*  
*이음 (Ieum) · Eum — 나의 취미를 이음*
