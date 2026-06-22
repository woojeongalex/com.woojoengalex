import 'package:flutter/material.dart';

void main() {
  runApp(const IuemApp());
}

class IuemApp extends StatelessWidget {
  const IuemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IUEM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF18181B),
          brightness: Brightness.light,
        ),
      ),
      // 시스템 글씨 크기 설정이 "크게"여도 레이아웃이 깨지지 않도록 상한 고정
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.2,
            ),
          ),
          child: child!,
        );
      },
      home: const IntroScreen(),
    );
  }
}

const _bg = Color(0xFFFAFAFA);
const _fg = Color(0xFF09090B);
const _muted = Color(0xFFF4F4F5);
const _mutedFg = Color(0xFF71717A);
const _border = Color(0xFFE4E4E7);
const _card = Color(0xFFFFFFFF);

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroSection(),
              const Divider(color: _border, height: 1, thickness: 1),
              const _FeatureSection(),
              const Divider(color: _border, height: 1, thickness: 1),
              const _CtaSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // 360dp 미만 소형 기기는 폰트 줄임
    final titleSize = width < 360 ? 24.0 : 28.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '노래를 고르고,\n부르면서 AI로\n음정과 박자를 분석하세요.',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: _fg,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // \n 제거 — Flutter가 화면 너비에 맞게 자동 줄바꿈
          const Text(
            '사용자가 선택한 가요나 뮤지컬 넘버를 AI가 분석하고, '
            '내장 마이크로 부른 결과를 바탕으로 음정과 박자 정확도, '
            '그리고 다음 연습을 위한 코칭 피드백까지 제공합니다. '
            '기타·피아노 튜닝과 스피치 코칭까지 '
            '하나의 IUEM 서비스로 연결됩니다.',
            style: TextStyle(fontSize: 14, color: _mutedFg, height: 1.7),
          ),
          const SizedBox(height: 24),
          const _VocalCard(),
          const SizedBox(height: 12),
          const _InstrumentCard(),
        ],
      ),
    );
  }
}

class _VocalCard extends StatelessWidget {
  const _VocalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _muted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.graphic_eq, size: 15, color: _mutedFg),
              SizedBox(width: 6),
              Text(
                '보컬 배너',
                style: TextStyle(fontSize: 12, color: _mutedFg, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '가요 + 뮤지컬',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _fg),
          ),
          const SizedBox(height: 8),
          const Text(
            '사용자가 선택한 가요와 뮤지컬 넘버를 기반으로 '
            '음정, 박자, 발성 안정성을 분석하고 AI 피드백까지 받을 수 있습니다.',
            style: TextStyle(fontSize: 13, color: _mutedFg, height: 1.6),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag('K-Pop Analysis', tagBg: _card),
              _Tag('Musical Number', tagBg: _card),
              _Tag('Vocal Feedback', tagBg: _card),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text(
                '보컬 상세 보기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _fg),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 15, color: _fg),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstrumentCard extends StatelessWidget {
  const _InstrumentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.music_note, size: 15, color: _mutedFg),
              SizedBox(width: 6),
              Text(
                '악기 배너',
                style: TextStyle(fontSize: 12, color: _mutedFg, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '기타 + 피아노',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _fg),
          ),
          const SizedBox(height: 8),
          const Text(
            '보컬 분석뿐 아니라 기타와 피아노 같은 악기의 '
            '음정 상태와 튜닝 정확도도 확인할 수 있도록 '
            '음정·튜닝 점수를 확인할 수 있습니다.',
            style: TextStyle(fontSize: 13, color: _mutedFg, height: 1.6),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Tag('Guitar Tuning', tagBg: _muted),
              _Tag('Piano Pitch Check', tagBg: _muted),
              _Tag('Instrument Support', tagBg: _muted),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text(
                '악기 상세 보기',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _fg),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 15, color: _fg),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color tagBg;

  const _Tag(this.label, {required this.tagBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tagBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: _mutedFg),
      ),
    );
  }
}

class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  static const _items = [
    (
      title: '음정 정확도 분석',
      description: '구간별 피치 안정성을 추적해 흔들리는 음, 밀리는 음, 지나치게 높은 음을 잡아냅니다.',
    ),
    (
      title: '박자 정밀도 분석',
      description: '원곡 BPM과 사용자의 발성을 비교해 박자가 빨라지는 구간과 늦어지는 구간을 알려줍니다.',
    ),
    (
      title: 'AI 코칭 피드백',
      description: '호흡, 발성, 강세, 프레이징을 함께 분석해 다음 연습 포인트를 자연어로 제안합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _muted,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI가 제공할 분석',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _mutedFg),
          ),
          const SizedBox(height: 6),
          const Text(
            '단순 점수만이 아니라, 왜 흔들렸는지까지 설명하는 보컬 피드백',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _fg,
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              '백엔드 연동 예정 기능',
              style: TextStyle(fontSize: 11, color: _mutedFg),
            ),
          ),
          const SizedBox(height: 20),
          for (final item in _items) ...[
            _FeatureCard(title: item.title, description: item.description),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;

  const _FeatureCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.graphic_eq, size: 20, color: _fg),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _fg),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: _mutedFg, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _fg,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '다음 단계',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0x80FAFAFA),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '선택한 노래, 사용자 음성, 분석 결과가 하나의 경험으로 이어지는 홈 화면',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFAFAFA),
                height: 1.35,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '추후 백엔드가 연결되면 가요와 뮤지컬 넘버를 아우르는 곡 선택 API, '
              '마이크 입력 업로드, 음정/박자 정확도 분석, 그리고 자연어 피드백 결과를 '
              '이 홈 화면에서 바로 보여줄 수 있도록 설계했습니다.',
              style: TextStyle(fontSize: 13, color: Color(0xB3FAFAFA), height: 1.7),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      '기능 시나리오 확인',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _fg),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 15, color: _fg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
