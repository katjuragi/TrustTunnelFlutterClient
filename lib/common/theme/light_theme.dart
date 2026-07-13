import 'package:flutter/material.dart';
import 'package:trusttunnel/common/assets/asset_icons.dart';
import 'package:trusttunnel/common/assets/font_families.dart';
import 'package:trusttunnel/common/extensions/theme_extensions.dart';
import 'package:trusttunnel/widgets/custom_icon.dart';

/// Colour palette that drives an [AppTheme]. Two instances exist: the light
/// palette (original TrustTunnel colours) and a dark palette.
class AppPalette {
  final Brightness brightness;
  final Color accent;
  final Color accentHover;
  final Color accentPressed;
  final Color accentDisabled;
  final Color accentAdditional;
  final Color blend;
  final Color blendHover;
  final Color blendPressed;
  final Color attention;
  final Color attentionHover;
  final Color attentionPressed;
  final Color attentionDisabled;
  final Color error;
  final Color errorHover;
  final Color errorPressed;
  final Color errorDisabled;
  final Color background;
  final Color backgroundHover;
  final Color backgroundPressed;
  final Color neutralBlend;
  final Color backgroundAdditional;
  final Color backgroundElevated;
  final Color backgroundSystem;
  final Color backgroundSystemHover;
  final Color backgroundSystemPressed;
  final Color neutralLight;
  final Color neutralLightHover;
  final Color neutralLightPressed;
  final Color neutralLightDisabled;
  final Color neutralDark;
  final Color neutralDarkHover;
  final Color neutralDarkPressed;
  final Color neutralDarkDisabled;
  final Color neutralBlack;
  final Color neutralBlackHover;
  final Color neutralBlackPressed;
  final Color neutralBlackDisabled;
  final Color specialStaticWhite;
  final Color specialStaticWhiteHover;
  final Color specialStaticWhitePressed;
  final Color specialStaticWhiteDisabled;
  final Color staticTransparent;
  final Color borderColor;
  final Color focusedBorderColor;

  const AppPalette({
    required this.brightness,
    required this.accent,
    required this.accentHover,
    required this.accentPressed,
    required this.accentDisabled,
    required this.accentAdditional,
    required this.blend,
    required this.blendHover,
    required this.blendPressed,
    required this.attention,
    required this.attentionHover,
    required this.attentionPressed,
    required this.attentionDisabled,
    required this.error,
    required this.errorHover,
    required this.errorPressed,
    required this.errorDisabled,
    required this.background,
    required this.backgroundHover,
    required this.backgroundPressed,
    required this.neutralBlend,
    required this.backgroundAdditional,
    required this.backgroundElevated,
    required this.backgroundSystem,
    required this.backgroundSystemHover,
    required this.backgroundSystemPressed,
    required this.neutralLight,
    required this.neutralLightHover,
    required this.neutralLightPressed,
    required this.neutralLightDisabled,
    required this.neutralDark,
    required this.neutralDarkHover,
    required this.neutralDarkPressed,
    required this.neutralDarkDisabled,
    required this.neutralBlack,
    required this.neutralBlackHover,
    required this.neutralBlackPressed,
    required this.neutralBlackDisabled,
    required this.specialStaticWhite,
    required this.specialStaticWhiteHover,
    required this.specialStaticWhitePressed,
    required this.specialStaticWhiteDisabled,
    required this.staticTransparent,
    required this.borderColor,
    required this.focusedBorderColor,
  });

  static const light = AppPalette(
    brightness: Brightness.light,
    accent: Color(0xFF3972AA),
    accentHover: Color(0xFF336699),
    accentPressed: Color(0xFF2D5986),
    accentDisabled: Color(0x664F8AC4),
    accentAdditional: Color(0xFF4F8AC4),
    blend: Color(0x334F8AC4),
    blendHover: Color(0x4D4F8AC4),
    blendPressed: Color(0x664F8AC4),
    attention: Color(0xFFF08400),
    attentionHover: Color(0xFFE07400),
    attentionPressed: Color(0xFFC76300),
    attentionDisabled: Color(0x80FFA424),
    error: Color(0xFFF44725),
    errorHover: Color(0xFFE7320D),
    errorPressed: Color(0xFFD02C0B),
    errorDisabled: Color(0x80F56447),
    background: Color(0xFFFFFFFF),
    backgroundHover: Color(0xFFF6F7F9),
    backgroundPressed: Color(0xFFE6EAEF),
    neutralBlend: Color(0x1A30353B),
    backgroundAdditional: Color(0xFFF6F7F9),
    backgroundElevated: Color(0xFFFFFFFF),
    backgroundSystem: Color(0xFFE6EAEF),
    backgroundSystemHover: Color(0xFFD1D8E0),
    backgroundSystemPressed: Color(0xFFBFC8D4),
    neutralLight: Color(0xFF9AA8B8),
    neutralLightHover: Color(0xFF8997A9),
    neutralLightPressed: Color(0xFF74869C),
    neutralLightDisabled: Color(0x3330353B),
    neutralDark: Color(0xFF74869C),
    neutralDarkHover: Color(0xFF5C6E84),
    neutralDarkPressed: Color(0xFF465567),
    neutralDarkDisabled: Color(0x4D30353B),
    neutralBlack: Color(0xFF333E4C),
    neutralBlackHover: Color(0xFF242D38),
    neutralBlackPressed: Color(0xFF1A2028),
    neutralBlackDisabled: Color(0x6630353B),
    specialStaticWhite: Color(0xFFFFFFFF),
    specialStaticWhiteHover: Color(0xFFF6F7F9),
    specialStaticWhitePressed: Color(0xFFE6EAEF),
    specialStaticWhiteDisabled: Color(0x80FFFFFF),
    staticTransparent: Colors.transparent,
    borderColor: Color(0xFF73859D),
    focusedBorderColor: Color(0xFF74869C),
  );

  // Dark palette: deep slate surfaces with the same accent family. "neutral*"
  // tokens are inverted so that text (neutralBlack) reads light on dark.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    accent: Color(0xFF4F8AC4),
    accentHover: Color(0xFF5E97CE),
    accentPressed: Color(0xFF6FA4D6),
    accentDisabled: Color(0x664F8AC4),
    accentAdditional: Color(0xFF6FA4D6),
    blend: Color(0x334F8AC4),
    blendHover: Color(0x4D4F8AC4),
    blendPressed: Color(0x664F8AC4),
    attention: Color(0xFFF9A825),
    attentionHover: Color(0xFFFFB74D),
    attentionPressed: Color(0xFFE59100),
    attentionDisabled: Color(0x80FFA424),
    error: Color(0xFFFF6E5A),
    errorHover: Color(0xFFFF8570),
    errorPressed: Color(0xFFE7320D),
    errorDisabled: Color(0x80F56447),
    background: Color(0xFF15191F),
    backgroundHover: Color(0xFF1E242C),
    backgroundPressed: Color(0xFF272E38),
    neutralBlend: Color(0x1AFFFFFF),
    backgroundAdditional: Color(0xFF1E242C),
    backgroundElevated: Color(0xFF222932),
    backgroundSystem: Color(0xFF0F1318),
    backgroundSystemHover: Color(0xFF1A2028),
    backgroundSystemPressed: Color(0xFF242D38),
    neutralLight: Color(0xFF5C6E84),
    neutralLightHover: Color(0xFF6B7D93),
    neutralLightPressed: Color(0xFF7A8CA2),
    neutralLightDisabled: Color(0x33FFFFFF),
    neutralDark: Color(0xFF8997A9),
    neutralDarkHover: Color(0xFF9AA8B8),
    neutralDarkPressed: Color(0xFFB0BCC9),
    neutralDarkDisabled: Color(0x4DFFFFFF),
    neutralBlack: Color(0xFFE6EAEF),
    neutralBlackHover: Color(0xFFF6F7F9),
    neutralBlackPressed: Color(0xFFFFFFFF),
    neutralBlackDisabled: Color(0x66FFFFFF),
    specialStaticWhite: Color(0xFFFFFFFF),
    specialStaticWhiteHover: Color(0xFFF6F7F9),
    specialStaticWhitePressed: Color(0xFFE6EAEF),
    specialStaticWhiteDisabled: Color(0x80FFFFFF),
    staticTransparent: Colors.transparent,
    borderColor: Color(0xFF5C6E84),
    focusedBorderColor: Color(0xFF6FA4D6),
  );
}

/// Builds a [ThemeData] from an [AppPalette]. [LightTheme] and [DarkTheme] are
/// thin wrappers selecting the palette.
class AppTheme {
  final AppPalette _p;

  AppTheme(this._p);

  late final Color _accent = _p.accent;
  late final Color _accentHover = _p.accentHover;
  late final Color _accentPressed = _p.accentPressed;
  late final Color _accentDisabled = _p.accentDisabled;
  late final Color _accentAdditional = _p.accentAdditional;
  late final Color _blend = _p.blend;
  late final Color _blendHover = _p.blendHover;
  late final Color _blendPressed = _p.blendPressed;
  late final Color _attention = _p.attention;
  late final Color _attentionHover = _p.attentionHover;
  late final Color _attentionPressed = _p.attentionPressed;
  late final Color _attentionDisabled = _p.attentionDisabled;
  late final Color _error = _p.error;
  late final Color _errorHover = _p.errorHover;
  late final Color _errorPressed = _p.errorPressed;
  late final Color _errorDisabled = _p.errorDisabled;
  late final Color _background = _p.background;
  late final Color _backgroundHover = _p.backgroundHover;
  late final Color _backgroundPressed = _p.backgroundPressed;
  late final Color _neutralBlend = _p.neutralBlend;
  late final Color _backgroundAdditional = _p.backgroundAdditional;
  late final Color _backgroundElevated = _p.backgroundElevated;
  late final Color _backgroundSystem = _p.backgroundSystem;
  late final Color _backgroundSystemHover = _p.backgroundSystemHover;
  late final Color _backgroundSystemPressed = _p.backgroundSystemPressed;
  late final Color _neutralLight = _p.neutralLight;
  late final Color _neutralLightHover = _p.neutralLightHover;
  late final Color _neutralLightPressed = _p.neutralLightPressed;
  late final Color _neutralLightDisabled = _p.neutralLightDisabled;
  late final Color _neutralDark = _p.neutralDark;
  late final Color _neutralDarkHover = _p.neutralDarkHover;
  late final Color _neutralDarkPressed = _p.neutralDarkPressed;
  late final Color _neutralDarkDisabled = _p.neutralDarkDisabled;
  late final Color _neutralBlack = _p.neutralBlack;
  late final Color _neutralBlackHover = _p.neutralBlackHover;
  late final Color _neutralBlackPressed = _p.neutralBlackPressed;
  late final Color _neutralBlackDisabled = _p.neutralBlackDisabled;
  late final Color _specialStaticWhite = _p.specialStaticWhite;
  late final Color _specialStaticWhiteHover = _p.specialStaticWhiteHover;
  late final Color _specialStaticWhitePressed = _p.specialStaticWhitePressed;
  late final Color _specialStaticWhiteDisabled = _p.specialStaticWhiteDisabled;
  late final Color _staticTransparent = _p.staticTransparent;
  late final Color _borderColor = _p.borderColor;
  late final Color _focusedBorderColor = _p.focusedBorderColor;

  late final _customColors = CustomColors(
    accent: _accent,
    accentHover: _accentHover,
    accentPressed: _accentPressed,
    accentDisabled: _accentDisabled,
    blend: _blend,
    blendHover: _blendHover,
    blendPressed: _blendPressed,
    attention: _attention,
    attentionHover: _attentionHover,
    attentionPressed: _attentionPressed,
    attentionDisabled: _attentionDisabled,
    error: _error,
    errorHover: _errorHover,
    errorPressed: _errorPressed,
    errorDisabled: _errorDisabled,
    background: _background,
    backgroundAdditional: _backgroundAdditional,
    backgroundElevated: _backgroundElevated,
    backgroundSystem: _backgroundSystem,
    backgroundSystemHover: _backgroundSystemHover,
    backgroundSystemPressed: _backgroundSystemPressed,
    neutralLight: _neutralLight,
    neutralLightHover: _neutralLightHover,
    neutralLightPressed: _neutralLightPressed,
    neutralLightDisabled: _neutralLightDisabled,
    neutralBlack: _neutralBlack,
    neutralBlackHover: _neutralBlackHover,
    neutralBlackPressed: _neutralBlackPressed,
    neutralBlackDisabled: _neutralBlackDisabled,
    neutralDark: _neutralDark,
    neutralDarkHover: _neutralDarkHover,
    neutralDarkPressed: _neutralDarkPressed,
    neutralDarkDisabled: _neutralDarkDisabled,
    specialStaticWhite: _specialStaticWhite,
    specialStaticWhiteHover: _specialStaticWhiteHover,
    specialStaticWhitePressed: _specialStaticWhitePressed,
    specialStaticWhiteDisabled: _specialStaticWhiteDisabled,
    staticTransparent: _staticTransparent,
  );

  late final _colorScheme = ColorScheme.fromSeed(
    seedColor: _accent,
    brightness: _p.brightness,
  );

  late final _checkboxThemeData = CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.selected) && !states.contains(WidgetState.disabled)) return _accent;
        if (states.contains(WidgetState.selected) && states.contains(WidgetState.disabled)) return _accentDisabled;

        return null;
      },
    ),
    checkColor: WidgetStateProperty.all(_specialStaticWhite),
    side: WidgetStateBorderSide.resolveWith(
      (states) {
        if (!states.contains(WidgetState.selected) && !states.contains(WidgetState.disabled)) {
          return BorderSide(width: 2, color: _neutralLight);
        }
        if (!states.contains(WidgetState.selected) && states.contains(WidgetState.disabled)) {
          return BorderSide(width: 2, color: _neutralLightDisabled);
        }

        return null;
      },
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.pressed)) return _accentPressed.withValues(alpha: 0.2);

        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return _backgroundSystem;

        return _staticTransparent;
      },
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2.0),
    ),
  );

  late final _iconButtonThemeData = IconButtonThemeData(
    style: ButtonStyle(
      shape: const WidgetStatePropertyAll(
        CircleBorder(),
      ),
      foregroundColor: WidgetStatePropertyAll(_specialStaticWhite),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.focused)) return _backgroundHover;
          if (states.contains(WidgetState.hovered)) return _backgroundPressed;

          return null;
        },
      ),
      mouseCursor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.disabled)) return SystemMouseCursors.basic;

          return null;
        },
      ),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(8)),
      iconSize: const WidgetStatePropertyAll(24),
    ),
  );

  late final _radioThemeData = RadioThemeData(
    fillColor: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.disabled)) return _neutralBlack.withValues(alpha: 0.38);
        if (states.contains(WidgetState.selected)) return _accent;

        return _neutralBlack;
      },
    ),
    overlayColor: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.pressed))
          return _backgroundSystem;

        return _staticTransparent;
      },
    ),
  );

  late final _floatingActionButtonThemeData = FloatingActionButtonThemeData(
    backgroundColor: _accent,
    extendedTextStyle: _textTheme.labelLarge?.copyWith(color: _specialStaticWhite),
    foregroundColor: _specialStaticWhite,
    iconSize: 24,
    extendedSizeConstraints: const BoxConstraints(minHeight: 56),
    smallSizeConstraints: const BoxConstraints(minHeight: 40, minWidth: 40),
    sizeConstraints: const BoxConstraints(minHeight: 56, minWidth: 56),
    largeSizeConstraints: const BoxConstraints(minHeight: 96, minWidth: 96),
    focusColor: _accentHover,
    hoverColor: _accentHover,
    splashColor: _accentPressed,
    hoverElevation: 4,
    elevation: 3,
    focusElevation: 3,
    disabledElevation: 3,
    highlightElevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  late final _switchThemeData = SwitchThemeData(
    trackColor: WidgetStateProperty.resolveWith(
      (states) {
        if (!states.contains(WidgetState.disabled) && states.contains(WidgetState.pressed)) return _accentPressed;
        if (!states.contains(WidgetState.selected)) return _backgroundSystem;

        return _accent;
      },
    ),
    thumbColor: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.selected)) return _specialStaticWhite;
        if (states.contains(WidgetState.disabled)) return _neutralDarkDisabled.withValues(alpha: 0.3);
        if (states.contains(WidgetState.pressed)) return _neutralDarkPressed;
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return _neutralDark;

        return _neutralBlack;
      },
    ),
    overlayColor: WidgetStatePropertyAll(_staticTransparent),
    trackOutlineWidth: WidgetStateProperty.resolveWith(
      (states) {
        if (!states.contains(WidgetState.selected)) return 2;

        return 0;
      },
    ),
    trackOutlineColor: WidgetStateProperty.resolveWith(
      (states) {
        if (states.contains(WidgetState.selected)) return null;

        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused) ||
            states.contains(WidgetState.disabled))
          return _neutralDark;

        return _neutralBlack;
      },
    ),
  );

  late final _snackBarThemeData = SnackBarThemeData(
    backgroundColor: _neutralBlack,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
    behavior: SnackBarBehavior.floating,
    elevation: 3,
    contentTextStyle: _textTheme.bodyMedium?.copyWith(color: _specialStaticWhite),
    actionTextColor: _accentAdditional,

    closeIconColor: _specialStaticWhite,
  );

  late final _badgeThemeData = BadgeThemeData(
    textColor: _specialStaticWhite,
    textStyle: _textTheme.labelSmall,
    backgroundColor: _error,
    smallSize: 6,
    largeSize: 16,
    padding: const EdgeInsets.symmetric(horizontal: 4),
  );

  late final _customFilledButtonTheme = CustomFilledButtonTheme(
    danger: FilledButtonThemeData(
      style: _filledButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) return _error.withValues(alpha: 0.5);

            return _error;
          },
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.pressed)) return _errorPressed;
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return _errorHover;

            return null;
          },
        ),
      ),
    ),
    attention: FilledButtonThemeData(
      style: _filledButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) return _attention.withValues(alpha: 0.5);

            return _attention;
          },
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.pressed)) return _attentionPressed;
            if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return _attentionHover;

            return null;
          },
        ),
      ),
    ),
    iconButton: FilledButtonThemeData(
      style: _filledButtonTheme.style?.copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 24),
        ),
      ),
    ),
  );

  late final _customElevatedButtonTheme = CustomElevatedButtonTheme(
    iconButton: ElevatedButtonThemeData(
      style: _filledButtonTheme.style?.copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 24),
        ),
      ),
    ),
  );

  late final _customOutlinedButtonTheme = CustomOutlinedButtonTheme(
    iconButton: OutlinedButtonThemeData(
      style: _outlinedButtonThemeData.style?.copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 24),
        ),
      ),
    ),
  );

  late final _customTextButtonTheme = CustomTextButtonTheme(
    danger: TextButtonThemeData(
      style: _textButtonThemeData.style?.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) return _errorDisabled.withValues(alpha: 0.5);

            return _error;
          },
        ),
      ),
    ),
    attention: TextButtonThemeData(
      style: _textButtonThemeData.style?.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) return _attentionDisabled.withValues(alpha: 0.5);

            return _attention;
          },
        ),
      ),
    ),
    success: TextButtonThemeData(
      style: _textButtonThemeData.style?.copyWith(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.disabled)) return _accentDisabled.withValues(alpha: 0.5);

            return _accent;
          },
        ),
      ),
    ),
    iconButton: _textButtonThemeData,
  );

  late final _elevatedButtonTheme = ElevatedButtonThemeData(
    style: _filledButtonTheme.style,
  );

  late final _filledButtonTheme = FilledButtonThemeData(
    style: ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.disabled)) return _accentDisabled.withValues(alpha: 0.4);

          return _accent;
        },
      ),
      foregroundColor: WidgetStatePropertyAll(_specialStaticWhite),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.pressed)) return _accentPressed;
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return _accentHover;

          return null;
        },
      ),
      textStyle: WidgetStatePropertyAll(_textTheme.labelLarge),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      ),
      iconSize: const WidgetStatePropertyAll(18),
      minimumSize: WidgetStatePropertyAll(
        Size(_buttonTheme.minWidth, _buttonTheme.height),
      ),
      visualDensity: VisualDensity.standard,
    ),
  );

  late final _outlinedButtonThemeData = OutlinedButtonThemeData(
    style: _filledButtonTheme.style?.copyWith(
      backgroundColor: WidgetStatePropertyAll(_staticTransparent),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.disabled)) return _neutralLight;

          return _neutralBlack;
        },
      ),
      shape: WidgetStateProperty.resolveWith(
        (states) {
          final Color borderColor;

          if (states.contains(WidgetState.disabled)) {
            borderColor = _neutralLight;
          } else {
            borderColor = _neutralBlack;
          }

          return StadiumBorder(
            side: BorderSide(
              color: borderColor,
            ),
          );
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.pressed)) return _backgroundPressed;
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return _backgroundHover;

          return null;
        },
      ),
    ),
  );

  late final _textButtonThemeData = TextButtonThemeData(
    style: _filledButtonTheme.style?.copyWith(
      backgroundColor: WidgetStatePropertyAll(_staticTransparent),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.disabled)) return _neutralLight;

          return _neutralBlack;
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.pressed)) return _backgroundPressed;
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.focused)) return _backgroundHover;

          return _staticTransparent;
        },
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      textStyle: WidgetStatePropertyAll(
        _textTheme.labelLarge,
      ),
    ),
  );

  late final _appBarTheme = AppBarTheme(
    backgroundColor: _staticTransparent,
    surfaceTintColor: _staticTransparent,
    shadowColor: _staticTransparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: _textTheme.titleLarge,
    centerTitle: true,
    foregroundColor: _neutralBlack,
  );

  late final _navigationBarThemeData = NavigationBarThemeData(
    backgroundColor: _backgroundSystem,
    indicatorColor: _blendHover,
  );

  late final _popupMenuThemeData = PopupMenuThemeData(
    color: _background,
    position: PopupMenuPosition.under,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4.0),
    ),
    surfaceTintColor: _background,

    elevation: 2,
    textStyle: _textTheme.bodyLarge?.copyWith(
      color: _neutralBlack,
    ),
  );

  late final _menuButtonThemeData = MenuButtonThemeData(
    style: _textButtonThemeData.style?.copyWith(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      textStyle: WidgetStatePropertyAll(_textTheme.bodyLarge),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) {
          if (states.contains(WidgetState.disabled)) return _staticTransparent;
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.selected))
            return _backgroundSystemHover;
          if (states.contains(WidgetState.pressed)) return _backgroundSystemPressed;

          return null;
        },
      ),
    ),
  );

  late final _menuBarThemeData = MenuBarThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(_background),
      surfaceTintColor: WidgetStatePropertyAll(_staticTransparent),
    ),
  );

  late final _dropdownMenuThemeData = DropdownMenuThemeData(
    textStyle: _textTheme.bodyLarge,
    inputDecorationTheme: _inputDecorationTheme,
    menuStyle: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(_background),
      surfaceTintColor: WidgetStatePropertyAll(_staticTransparent),
      visualDensity: VisualDensity.standard,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(vertical: 8),
      ),
    ),
  );

  late final _menuThemeData = MenuThemeData(
    style: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(_background),
      surfaceTintColor: WidgetStatePropertyAll(_staticTransparent),
    ),
  );

  late final _progressIndicatorThemeData = ProgressIndicatorThemeData(
    color: _accent,
    circularTrackColor: _blend.withValues(alpha: 0.2),
    linearTrackColor: _blend.withValues(alpha: 0.2),
    linearMinHeight: 4,
  );

  late final _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: _neutralDarkDisabled.withValues(
          alpha: 0.3,
        ),
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: _error),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: _focusedBorderColor,
        width: 3,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: _error, width: 3),
    ),
    outlineBorder: BorderSide(
      color: _borderColor,
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: _borderColor,
      ),
    ),
    floatingLabelStyle: WidgetStateTextStyle.resolveWith(
      (states) {
        if (states.contains(WidgetState.disabled)) {
          return _textTheme.bodySmall!.copyWith(color: _neutralBlackDisabled.withValues(alpha: 0.4));
        }

        if (states.contains(WidgetState.error)) {
          return _textTheme.bodySmall!.copyWith(color: _error);
        }

        return _textTheme.bodySmall!;
      },
    ),
    labelStyle: WidgetStateTextStyle.resolveWith(
      (states) {
        if (states.contains(WidgetState.disabled)) {
          return _textTheme.bodySmall!.copyWith(color: _neutralBlackDisabled.withValues(alpha: 0.3));
        }

        if (states.contains(WidgetState.error)) {
          return _textTheme.bodySmall!.copyWith(color: _error);
        }

        return _textTheme.bodySmall!;
      },
    ),
    alignLabelWithHint: true,
    hoverColor: _backgroundSystem,
    fillColor: _staticTransparent,
    iconColor: _neutralBlack,
    prefixIconColor: WidgetStateColor.resolveWith(
      (states) {
        if (states.contains(WidgetState.disabled)) {
          return _neutralBlackDisabled;
        }

        return _neutralBlack;
      },
    ),
    suffixIconColor: WidgetStateColor.resolveWith(
      (states) {
        if (states.contains(WidgetState.disabled)) {
          return _neutralBlackDisabled;
        }

        if (states.contains(WidgetState.error)) {
          return _error;
        }

        return _neutralBlack;
      },
    ),
    errorStyle: _textTheme.bodySmall?.copyWith(color: _error),
    hintStyle: WidgetStateTextStyle.resolveWith(
      (states) {
        final Color textColor;
        if (states.contains(WidgetState.disabled)) {
          textColor = _neutralDarkDisabled.withValues(alpha: 0.4);
        } else {
          textColor = _neutralDark;
        }

        return _textTheme.bodyLarge!.copyWith(color: textColor);
      },
    ),
    helperStyle: WidgetStateTextStyle.resolveWith(
      (states) {
        if (states.contains(WidgetState.disabled)) {
          return _textTheme.bodySmall!.copyWith(color: _neutralBlackDisabled.withValues(alpha: 0.3));
        }

        if (states.contains(WidgetState.error)) {
          return _textTheme.bodySmall!.copyWith(color: _error);
        }

        return _textTheme.bodySmall!;
      },
    ),
    counterStyle: WidgetStateTextStyle.resolveWith((states) => _textTheme.bodySmall!),
    contentPadding: const EdgeInsets.only(top: 16, bottom: 16, left: 16),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    focusColor: _staticTransparent,
  );

  late final _textSelectionTheme = TextSelectionThemeData(
    cursorColor: WidgetStateColor.resolveWith(
      (states) {
        if (states.contains(WidgetState.error)) {
          return _error;
        }

        return _neutralBlack;
      },
    ),
    selectionColor: _blend,
    selectionHandleColor: _accent,
  );

  late final _dividerThemeData = DividerThemeData(
    color: _neutralBlend,
    space: 1,
  );

  late final _iconThemeData = IconThemeData(
    size: 24,
    color: _neutralBlack,
  );

  late final _navigationRailThemeData = NavigationRailThemeData(
    indicatorColor: _blend.withValues(alpha: 0.2),
    unselectedLabelTextStyle: _textTheme.labelMedium,
    selectedLabelTextStyle: _textTheme.labelMedium,
    backgroundColor: _backgroundSystem,
  );

  late final _actionIconThemeData = ActionIconThemeData(
    closeButtonIconBuilder: (context) => CustomIcon.medium(
      icon: AssetIcons.close,
      color: _neutralBlack,
    ),
    backButtonIconBuilder: (context) => CustomIcon.medium(
      icon: AssetIcons.arrowBack,
      color: _neutralBlack,
    ),
  );

  late final _listTileThemeData = ListTileThemeData(
    contentPadding: const EdgeInsets.all(16),
    titleTextStyle: _textTheme.titleSmall,
    subtitleTextStyle: _textTheme.bodyMedium?.copyWith(color: _neutralLight),
  );

  late final _customDropdownMenuTheme = CustomDropdownMenuTheme(
    enabled: _dropdownMenuThemeData,
    disabled: _dropdownMenuThemeData.copyWith(
      textStyle: _dropdownMenuThemeData.textStyle?.copyWith(
        color: _neutralBlackDisabled.withValues(alpha: 0.4),
      ),
    ),
  );

  late final _tabBarTheme = TabBarThemeData(
    labelColor: _accent,
    unselectedLabelColor: _neutralBlack,
    indicatorColor: _accent,
    labelPadding: const EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 16,
    ),
    labelStyle: _textTheme.titleSmall,
  );

  late final _dialogTheme = DialogThemeData(
    backgroundColor: _background,
    surfaceTintColor: _staticTransparent,
    titleTextStyle: _textTheme.headlineSmall,
    contentTextStyle: _textTheme.bodyMedium,
    iconColor: _accent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(28.0),
      ),
    ),
  );

  late final _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 57,
      letterSpacing: -0.25,
      height: 1.12,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    displayMedium: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 45,
      height: 1.15,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    displaySmall: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 36,
      height: 1.22,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    headlineLarge: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 32,
      height: 1.25,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 28,
      height: 1.28,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    headlineSmall: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 24,
      height: 1.33,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 22,
      height: 1.27,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 16,
      letterSpacing: 0.15,
      height: 1.5,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    titleSmall: TextStyle(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 14,
      letterSpacing: 0.1,
      height: 1.42,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    labelLarge: TextStyle(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 14,
      letterSpacing: 0.1,
      height: 1.42,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    labelMedium: TextStyle(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 12,
      letterSpacing: 0.5,
      height: 1.33,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    labelSmall: TextStyle(
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 11,
      letterSpacing: 0.5,
      height: 1.45,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    bodyLarge: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 16,
      letterSpacing: 0.5,
      height: 1.5,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    bodyMedium: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 14,
      letterSpacing: 0.25,
      height: 1.42,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    bodySmall: TextStyle(
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.normal,
      color: _neutralBlack,
      fontSize: 12,
      letterSpacing: 0.4,
      height: 1.33,
      fontFamily: FontFamilies.roboto,
      leadingDistribution: TextLeadingDistribution.even,
    ),
  );

  final _buttonTheme = const ButtonThemeData(
    minWidth: 70,
    height: 40,
  );

  late final _customFilledIconButtonTheme = CustomFilledIconButtonTheme(
    iconButton: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(_specialStaticWhite),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return _accent;
            }

            return _neutralDark;
          },
        ),
      ),
    ),
    iconButtonInProgress: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(_specialStaticWhite),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) {
            if (states.contains(WidgetState.selected)) {
              return _accent;
            }

            return _neutralDark;
          },
        ),
      ),
    ),
  );

  late final _customMissSpelledTextTheme = CustomMissSpelledTextTheme(
    missSpelledStyle: TextStyle(
      decorationColor: _error,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.wavy,
      decorationThickness: 2,
    ),
  );

  ThemeData get data => ThemeData(
    // GENERAL CONFIGURATION
    useMaterial3: true,
    extensions: [
      _customColors,
      _customFilledButtonTheme,
      _customElevatedButtonTheme,
      _customOutlinedButtonTheme,
      _customTextButtonTheme,
      _customDropdownMenuTheme,
      _customFilledIconButtonTheme,
      _customMissSpelledTextTheme,
    ],

    // COLOR
    scaffoldBackgroundColor: _background,
    brightness: _p.brightness,
    primaryColor: _accent,
    colorScheme: _colorScheme,
    hoverColor: _staticTransparent,
    focusColor: _staticTransparent,

    // TYPOGRAPHY & ICONOGRAPHY
    textTheme: _textTheme,
    fontFamily: FontFamilies.roboto,
    iconTheme: _iconThemeData,
    textSelectionTheme: _textSelectionTheme,

    // COMPONENT THEMES
    checkboxTheme: _checkboxThemeData,
    iconButtonTheme: _iconButtonThemeData,
    radioTheme: _radioThemeData,
    floatingActionButtonTheme: _floatingActionButtonThemeData,
    switchTheme: _switchThemeData,
    snackBarTheme: _snackBarThemeData,
    badgeTheme: _badgeThemeData,
    elevatedButtonTheme: _elevatedButtonTheme,
    filledButtonTheme: _filledButtonTheme,
    outlinedButtonTheme: _outlinedButtonThemeData,
    textButtonTheme: _textButtonThemeData,
    dialogTheme: _dialogTheme,
    menuButtonTheme: _menuButtonThemeData,
    menuBarTheme: _menuBarThemeData,
    dropdownMenuTheme: _dropdownMenuThemeData,
    menuTheme: _menuThemeData,
    popupMenuTheme: _popupMenuThemeData,
    navigationBarTheme: _navigationBarThemeData,
    appBarTheme: _appBarTheme,
    progressIndicatorTheme: _progressIndicatorThemeData,
    inputDecorationTheme: _inputDecorationTheme,
    dividerTheme: _dividerThemeData,
    navigationRailTheme: _navigationRailThemeData,
    actionIconTheme: _actionIconThemeData,
    listTileTheme: _listTileThemeData,
    buttonTheme: _buttonTheme,
    tabBarTheme: _tabBarTheme,
  );
}

/// Light application theme.
class LightTheme extends AppTheme {
  LightTheme() : super(AppPalette.light);
}

/// Dark application theme.
class DarkTheme extends AppTheme {
  DarkTheme() : super(AppPalette.dark);
}
