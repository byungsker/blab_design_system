import 'dart:io';

import 'package:blab_design_system/blab_design_system.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _candidateSurfaceKey = ValueKey<String>('phase4-candidate-surface');
const _candidateContentKey = ValueKey<String>('phase4-candidate-content');
const _fontDirectory = 'test/assets/fonts';

/// Loads one pinned test fixture font under the family name explicitly
/// requested by current BLDS widgets.
///
/// Every caller runs in an isolated Flutter test process. The alias exists
/// only in that process; it is not Pretendard, is not a runtime asset, and
/// does not change the production font policy.
Future<void> loadPhase4FixtureFont(String filename) async {
  final fixtureText = FontLoader('Pretendard')
    ..addFont(_fontData('$_fontDirectory/$filename'));
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(_fontData('$_fontDirectory/MaterialIcons-Regular.otf'));
  final cupertinoIcons = FontLoader('packages/cupertino_icons/CupertinoIcons')
    ..addFont(_fontData('$_fontDirectory/CupertinoIcons.ttf'));
  await Future.wait<void>([
    fixtureText.load(),
    materialIcons.load(),
    cupertinoIcons.load(),
  ]);
}

void registerPhase4GoldenTests(
  List<Phase4GoldenScenario> scenarios, {
  bool includeExpansionInvariant = false,
}) {
  if (includeExpansionInvariant) {
    test('synthetic expansion fixture is deterministic and forty percent', () {
      const source = 'Deterministic expansion';
      final expanded = _expandFortyPercent(source);
      expect(source.runes.length, 23);
      expect(expanded.runes.length, 32);
      expect(
        (expanded.runes.length - source.runes.length) / source.runes.length,
        closeTo(0.4, 0.01),
      );
      expect(_expandFortyPercent(source), expanded);
    });
  }
  for (final scenario in scenarios) {
    testWidgets(
      'candidate golden ${scenario.id} frames all public families',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = scenario.size;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_GoldenApp(scenario: scenario));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 50));

        final contentContext = tester.element(find.byKey(_candidateContentKey));
        expect(Localizations.localeOf(contentContext), scenario.locale);
        expect(Directionality.of(contentContext), scenario.textDirection);

        _expectSnackbarScenarioEnvironment(tester, scenario);
        _expectAllPublicFamiliesFramed(tester, scenario.size);
        expect(
          find.byKey(_candidateSurfaceKey),
          matchesGoldenFile('goldens/candidates/phase4-${scenario.id}.png'),
        );
      },
      tags: const <String>['golden', 'phase4-candidate'],
    );
  }
}

void _expectSnackbarScenarioEnvironment(
  WidgetTester tester,
  Phase4GoldenScenario scenario,
) {
  final surfaceFinder = find.byKey(
    const ValueKey<String>('BLabSnackbar.surface'),
  );
  final surfaceContext = tester.element(surfaceFinder);
  final mediaQuery = MediaQuery.of(surfaceContext);
  expect(Theme.of(surfaceContext).brightness, scenario.brightness);
  expect(Localizations.localeOf(surfaceContext), scenario.locale);
  expect(Directionality.of(surfaceContext), scenario.textDirection);
  expect(mediaQuery.highContrast, scenario.highContrast);
  expect(mediaQuery.textScaler.scale(1), scenario.textScale);
  expect(mediaQuery.disableAnimations, scenario.reducedMotion);
  expect(mediaQuery.accessibleNavigation, scenario.reducedMotion);

  final surface = tester.widget<Material>(surfaceFinder);
  final surfaceShape = surface.shape! as RoundedRectangleBorder;
  expect(surfaceShape.side.width, scenario.highContrast ? 2 : 1);

  final badgeFinder = find.byKey(
    const ValueKey<String>('BLabSnackbar.badge.info'),
  );
  expect(tester.getSize(badgeFinder), const Size(32, 32));
  final badge = tester.widget<Container>(badgeFinder);
  final badgeDecoration = badge.decoration! as BoxDecoration;
  final badgeBorder = badgeDecoration.border;
  if (scenario.highContrast) {
    expect(badgeBorder, isA<Border>());
    expect((badgeBorder! as Border).top.width, 2);
  } else {
    expect(badgeBorder, isNull);
  }

  final messageFinder = find.byKey(
    const ValueKey<String>('BLabSnackbar.message'),
  );
  if (scenario.textDirection == TextDirection.rtl) {
    expect(
      tester.getCenter(badgeFinder).dx,
      greaterThan(tester.getCenter(messageFinder).dx),
      reason: 'RTL must mirror the Snackbar leading badge.',
    );
  } else {
    expect(
      tester.getCenter(badgeFinder).dx,
      lessThan(tester.getCenter(messageFinder).dx),
      reason: 'LTR must keep the Snackbar leading badge at the left.',
    );
  }

  if (scenario.textScale == 2) {
    final actionFinder = find.byKey(
      const ValueKey<String>('BLabSnackbar.action'),
    );
    expect(
      tester.getTopLeft(actionFinder).dy,
      greaterThan(tester.getBottomLeft(messageFinder).dy),
      reason: '2x text must stack Snackbar controls below the message.',
    );
    final actionSize = tester.getSize(actionFinder);
    expect(actionSize.width, greaterThanOrEqualTo(44));
    expect(actionSize.height, greaterThanOrEqualTo(44));
  }
}

Future<ByteData> _fontData(String path) async {
  final bytes = await File(path).readAsBytes();
  return ByteData.sublistView(Uint8List.fromList(bytes));
}

void _expectAllPublicFamiliesFramed(WidgetTester tester, Size size) {
  final frame = Offset.zero & size;
  final families = <String, Finder>{
    'button': find.byType(BLabButton).first,
    'text-field': find.byType(BLabTextField),
    'segmented-control': find.byType(BLabSegmentedControl<int>),
    'tab-bar': find.byType(BLabTabBar),
    'bottom-bar': find.byType(BLabBottomBar),
    'pressable-wrapper': find.byType(BLabPressableWrapper).first,
    'card': find.byType(BLabCard),
    'snackbar': find.byKey(const ValueKey<String>('BLabSnackbar.surface')),
    'keyboard-accessory-bar': find.byType(BLabKeyboardAccessoryBar),
  };
  for (final entry in families.entries) {
    expect(entry.value, findsWidgets, reason: '${entry.key} must be rendered');
    final rect = tester.getRect(entry.value.first);
    expect(
      frame.overlaps(rect) &&
          rect.left >= frame.left &&
          rect.top >= frame.top &&
          rect.right <= frame.right &&
          rect.bottom <= frame.bottom,
      isTrue,
      reason: '${entry.key} must be fully framed; got $rect in $frame',
    );
  }
}

class Phase4GoldenScenario {
  const Phase4GoldenScenario({
    required this.id,
    required this.brightness,
    required this.size,
    this.locale = const Locale('en', 'US'),
    this.copyKind = Phase4CopyKind.english,
    this.highContrast = false,
    this.textScale = 1,
    this.textDirection = TextDirection.ltr,
    this.reducedMotion = false,
  });

  final String id;
  final Brightness brightness;
  final Size size;
  final Locale locale;
  final Phase4CopyKind copyKind;
  final bool highContrast;
  final double textScale;
  final TextDirection textDirection;
  final bool reducedMotion;
}

enum Phase4CopyKind { english, korean, expanded, arabic }

class _GoldenApp extends StatelessWidget {
  const _GoldenApp({required this.scenario});

  final Phase4GoldenScenario scenario;

  @override
  Widget build(BuildContext context) {
    final baseTheme = scenario.brightness == Brightness.dark
        ? BLabTheme.dark
        : BLabTheme.light;
    return RepaintBoundary(
      key: _candidateSurfaceKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: baseTheme,
        locale: scenario.locale,
        supportedLocales: <Locale>[scenario.locale],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          _FixtureMaterialLocalizationsDelegate(),
          _FixtureWidgetsLocalizationsDelegate(),
          _FixtureCupertinoLocalizationsDelegate(),
        ],
        builder: (context, child) {
          final data = MediaQuery.of(context).copyWith(
            highContrast: scenario.highContrast,
            textScaler: TextScaler.linear(scenario.textScale),
            disableAnimations: scenario.reducedMotion,
            accessibleNavigation: scenario.reducedMotion,
          );
          return MediaQuery(
            data: data,
            child: Directionality(
              textDirection: scenario.textDirection,
              child: BLabFocusVisibilityScope(child: child!),
            ),
          );
        },
        home: _PersistentSnackbarFixture(
          scenario: scenario,
          copy: _GoldenCopy(scenario.copyKind),
        ),
      ),
    );
  }
}

class _FixtureMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FixtureMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
        const DefaultMaterialLocalizations(),
      );

  @override
  bool shouldReload(_FixtureMaterialLocalizationsDelegate old) => false;
}

class _FixtureWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _FixtureWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<WidgetsLocalizations>(
        const DefaultWidgetsLocalizations(),
      );

  @override
  bool shouldReload(_FixtureWidgetsLocalizationsDelegate old) => false;
}

class _FixtureCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FixtureCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const DefaultCupertinoLocalizations(),
      );

  @override
  bool shouldReload(_FixtureCupertinoLocalizationsDelegate old) => false;
}

class _PersistentSnackbarFixture extends StatefulWidget {
  const _PersistentSnackbarFixture({
    required this.scenario,
    required this.copy,
  });

  final Phase4GoldenScenario scenario;
  final _GoldenCopy copy;

  @override
  State<_PersistentSnackbarFixture> createState() =>
      _PersistentSnackbarFixtureState();
}

class _PersistentSnackbarFixtureState
    extends State<_PersistentSnackbarFixture> {
  BLabSnackbarController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _controller != null) return;
      _controller = BLabSnackbar.showManaged(
        context,
        message: widget.copy.snackbarMessage,
        type: BLabSnackbarType.info,
        persist: true,
        bottomOffset: 112,
        action: BLabSnackbarAction(
          label: widget.copy.snackbarAction,
          onPressed: () {},
        ),
        showDismissAction: true,
        dismissSemanticLabel: widget.copy.snackbarDismiss,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CandidateSurface(
      key: _candidateContentKey,
      scenario: widget.scenario,
      copy: widget.copy,
    );
  }
}

class _CandidateSurface extends StatefulWidget {
  const _CandidateSurface({
    super.key,
    required this.scenario,
    required this.copy,
  });

  final Phase4GoldenScenario scenario;
  final _GoldenCopy copy;

  @override
  State<_CandidateSurface> createState() => _CandidateSurfaceState();
}

class _CandidateSurfaceState extends State<_CandidateSurface>
    with TickerProviderStateMixin {
  late final TextEditingController _field;
  late final TabController _tabs;
  int _segment = 1;
  int _bottomIndex = 0;

  @override
  void initState() {
    super.initState();
    _field = TextEditingController(text: widget.copy.fieldValue);
    _tabs = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _field.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final copy = widget.copy;
    return Scaffold(
      appBar: AppBar(title: Text(copy.title), automaticallyImplyLeading: false),
      body: ListView(
        padding: EdgeInsets.all(BLabSpacing.md),
        children: [
          Text(copy.fixtureNote, style: BLabTypography.caption),
          SizedBox(height: BLabSpacing.md),
          Wrap(
            spacing: BLabSpacing.md,
            runSpacing: BLabSpacing.md,
            children: [
              SizedBox(
                width: 260,
                child: BLabButton(text: copy.primaryAction, onPressed: () {}),
              ),
              SizedBox(
                width: 260,
                child: BLabButton(
                  text: copy.disabledAction,
                  variant: BLabButtonVariant.secondary,
                ),
              ),
            ],
          ),
          SizedBox(height: BLabSpacing.md),
          BLabTextField(
            controller: _field,
            label: copy.fieldLabel,
            helperText: copy.fieldHelper,
          ),
          SizedBox(height: BLabSpacing.md),
          BLabSegmentedControl<int>(
            items: [
              BLabSegmentedItem<int>(value: 0, label: copy.segmentAll),
              BLabSegmentedItem<int>(value: 1, label: copy.segmentActive),
              BLabSegmentedItem<int>(
                value: 2,
                label: copy.segmentDisabled,
                enabled: false,
              ),
            ],
            selectedValue: _segment,
            onChanged: (value) => setState(() => _segment = value),
          ),
          SizedBox(height: BLabSpacing.md),
          BLabTabBar(
            controller: _tabs,
            tabs: [copy.tabOverview, copy.tabActivity, copy.tabSettings],
          ),
          SizedBox(height: BLabSpacing.md),
          BLabCard(
            semanticLabel: copy.cardSemanticLabel,
            onTap: () {},
            child: Text(copy.cardLabel),
          ),
          SizedBox(height: BLabSpacing.md),
          BLabPressableWrapper(
            semanticLabel: copy.pressableSemanticLabel,
            onTap: () {},
            borderRadius: BLabRadius.mdRect,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: BLabColors.surface(context),
                borderRadius: BLabRadius.mdRect,
                border: Border.all(color: BLabColors.borderSubtle(context)),
              ),
              child: Padding(
                padding: EdgeInsets.all(BLabSpacing.md),
                child: Text(copy.pressableLabel),
              ),
            ),
          ),
          SizedBox(height: BLabSpacing.md),
          SizedBox(
            width: double.infinity,
            child: BLabKeyboardAccessoryBar(
              isDark: dark,
              showNavigation: true,
              onUp: () {},
              onDown: () {},
              onUndo: () {},
              onRedo: () {},
              onDone: () {},
              canUndo: true,
              canRedo: true,
              upSemanticLabel: copy.previousField,
              downSemanticLabel: copy.nextField,
              undoSemanticLabel: copy.undo,
              redoSemanticLabel: copy.redo,
              doneSemanticLabel: copy.dismissKeyboard,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BLabBottomBar(
        tabs: [
          BLabBottomBarItem(
            icon: CupertinoIcons.cart,
            activeIcon: CupertinoIcons.cart_fill,
            label: copy.bottomCarts,
          ),
          BLabBottomBarItem(
            icon: CupertinoIcons.archivebox,
            activeIcon: CupertinoIcons.archivebox_fill,
            label: copy.bottomArchive,
          ),
          BLabBottomBarItem(
            icon: CupertinoIcons.person,
            activeIcon: CupertinoIcons.person_fill,
            label: copy.bottomProfile,
          ),
        ],
        selectedIndex: _bottomIndex,
        onTabSelected: (value) => setState(() => _bottomIndex = value),
        noMargin: true,
      ),
    );
  }
}

class _GoldenCopy {
  const _GoldenCopy(this.kind);

  final Phase4CopyKind kind;

  String _pick(String english, String korean, String arabic) {
    return switch (kind) {
      Phase4CopyKind.english => english,
      Phase4CopyKind.korean => korean,
      Phase4CopyKind.expanded => _expandFortyPercent(english),
      Phase4CopyKind.arabic => arabic,
    };
  }

  String get title => _pick(
    'Phase 4 candidate evidence',
    'Phase 4 후보 시각 증거',
    'دليل مرئي للمرحلة 4 — BLDS',
  );
  String get fixtureNote => _pick(
    'Deterministic expansion',
    '한국어 로케일과 실제 한글 문구',
    'عينة عربية من اليمين إلى اليسار — BLDS 2026',
  );
  String get primaryAction =>
      _pick('Primary action', '기본 작업', 'الإجراء الأساسي');
  String get disabledAction =>
      _pick('Disabled action', '비활성 작업', 'إجراء غير متاح');
  String get fieldLabel => _pick('Email', '이메일', 'البريد الإلكتروني');
  String get fieldHelper => _pick(
    'Deterministic local fixture',
    '결정적인 로컬 테스트 문구',
    'عينة محلية ثابتة — رقم ٢٠٢٦',
  );
  String get fieldValue =>
      _pick('fixed@example.com', '사용자@example.com', 'مستخدم@example.com');
  String get segmentAll => _pick('All', '전체', 'الكل');
  String get segmentActive => _pick('Active', '활성', 'نشط');
  String get segmentDisabled => _pick('Disabled', '비활성', 'غير متاح');
  String get tabOverview => _pick('Overview', '개요', 'نظرة عامة');
  String get tabActivity => _pick('Activity', '활동', 'النشاط');
  String get tabSettings => _pick('Settings', '설정', 'الإعدادات');
  String get cardSemanticLabel =>
      _pick('Open deterministic card', '결정적 카드 열기', 'فتح البطاقة الثابتة');
  String get cardLabel =>
      _pick('Actionable card', '작업 가능한 카드', 'بطاقة قابلة للتنفيذ');
  String get pressableSemanticLabel => _pick(
    'Open deterministic pressable',
    '결정적 누름 영역 열기',
    'فتح منطقة الضغط الثابتة',
  );
  String get pressableLabel =>
      _pick('Direct pressable wrapper', '직접 누름 래퍼', 'غلاف ضغط مباشر');
  String get previousField => _pick('Previous field', '이전 필드', 'الحقل السابق');
  String get nextField => _pick('Next field', '다음 필드', 'الحقل التالي');
  String get undo => _pick('Undo edit', '편집 취소', 'تراجع عن التعديل');
  String get redo => _pick('Redo edit', '편집 다시 실행', 'إعادة التعديل');
  String get dismissKeyboard =>
      _pick('Dismiss keyboard', '키보드 닫기', 'إغلاق لوحة المفاتيح');
  String get bottomCarts => _pick('Carts', '장바구니', 'السلال');
  String get bottomArchive => _pick('Archive', '보관함', 'الأرشيف');
  String get bottomProfile => _pick('Profile', '프로필', 'الملف الشخصي');
  String get snackbarMessage => _pick(
    'Persistent public-API fixture',
    '공개 API로 표시한 고정 스낵바',
    'إشعار ثابت عبر الواجهة العامة — BLDS',
  );
  String get snackbarAction => _pick('Review', '검토', 'مراجعة');
  String get snackbarDismiss =>
      _pick('Dismiss notice', '알림 닫기', 'إغلاق الإشعار');
}

String _expandFortyPercent(String source) {
  final addedLength = (source.runes.length * 0.4).round();
  return '$source${List<String>.filled(addedLength, '·').join()}';
}
