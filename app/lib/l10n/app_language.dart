/// 界面语言。
library;

import 'dart:ui';

enum AppLanguage {
  zhHans('zh-Hans', '简体中文', Locale('zh', 'CN')),
  zhHant('zh-Hant', '繁體中文', Locale('zh', 'TW')),
  en('en', 'English', Locale('en'));

  const AppLanguage(this.code, this.nativeName, this.locale);

  /// 持久化与发给后端用的代号。
  final String code;

  /// 用该语言自己的写法显示的名称(语言切换器里永远用母语显示)。
  final String nativeName;
  final Locale locale;

  bool get isChinese => this != AppLanguage.en;

  static AppLanguage fromCode(String? code) =>
      AppLanguage.values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.zhHans);

  /// 按系统语言猜一个默认值:繁体地区 → 繁体;其他中文 → 简体;否则英文。
  static AppLanguage fromSystem(Locale locale) {
    if (locale.languageCode == 'zh') {
      final tw = locale.scriptCode == 'Hant' || const {'TW', 'HK', 'MO'}.contains(locale.countryCode);
      return tw ? AppLanguage.zhHant : AppLanguage.zhHans;
    }
    return AppLanguage.en;
  }
}
