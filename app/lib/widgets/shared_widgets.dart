import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';

// ─── AppButton ───────────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool outline;
  final bool danger;
  final bool full;
  final bool small;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = true,
    this.outline = false,
    this.danger = false,
    this.full = false,
    this.small = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    Color bg, fg;
    Border? border;

    if (danger) {
      bg = AppColors.danger;
      fg = Colors.white;
    } else if (outline) {
      bg = Colors.transparent;
      fg = ext.fg;
      border = Border.all(color: ext.border);
    } else {
      bg = AppColors.accentDk;
      fg = Colors.white;
    }

    return SizedBox(
      width: full ? double.infinity : null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.rPill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.rPill),
          onTap: onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 14 : 20,
              vertical: small ? 8 : 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.rPill),
              border: border,
            ),
            child: Row(
              mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 6)],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontSize: small ? 12 : 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── AppInput ────────────────────────────────────────────────────
class AppInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final int? maxLength;

  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ext.fgMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: onChanged,
            maxLength: maxLength,
            style: TextStyle(fontSize: 15, color: ext.fg),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ext.fgMuted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: ext.surface2,
              counterText: '',
              prefixIcon: prefix,
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.rSm),
                borderSide: BorderSide(color: ext.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.rSm),
                borderSide: BorderSide(color: ext.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.rSm),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AppDropdown ─────────────────────────────────────────────────
class AppDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;

  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.sourceCodePro(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: ext.fgMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: ext.surface2,
              borderRadius: BorderRadius.circular(AppTheme.rSm),
              border: Border.all(color: ext.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: ext.surface,
                style: TextStyle(fontSize: 15, color: ext.fg),
                hint: Text('Select', style: TextStyle(color: ext.fgMuted)),
                items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AppBadge ────────────────────────────────────────────────────
enum BadgeVariant { green, warn, red, blue }

class AppBadge extends StatelessWidget {
  final String label;
  final BadgeVariant variant;

  const AppBadge({super.key, required this.label, this.variant = BadgeVariant.green});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (variant) {
      case BadgeVariant.green:
        bg = AppColors.accent.withValues(alpha: 0.15);
        fg = AppColors.accent;
        break;
      case BadgeVariant.warn:
        bg = AppColors.warn.withValues(alpha: 0.15);
        fg = AppColors.warn;
        break;
      case BadgeVariant.red:
        bg = AppColors.danger.withValues(alpha: 0.15);
        fg = AppColors.danger;
        break;
      case BadgeVariant.blue:
        bg = AppColors.blue.withValues(alpha: 0.15);
        fg = AppColors.blue;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.rPill),
      ),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── AppSearchBar ────────────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({super.key, this.hint = 'Search...', this.controller, this.trailing, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: ext.surface2,
        borderRadius: BorderRadius.circular(AppTheme.rPill),
        border: Border.all(color: ext.border),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: ext.fgMuted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontSize: 14, color: ext.fg),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: ext.fgMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── ChipRow ─────────────────────────────────────────────────────
class ChipRow extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onSelected;

  const ChipRow({super.key, required this.labels, this.selected = 0, this.onSelected});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: labels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final active = i == selected;
            return GestureDetector(
              onTap: () => onSelected?.call(i),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: active ? AppColors.accentDk : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.rPill),
                  border: Border.all(color: active ? AppColors.accentDk : ext.border),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: active ? Colors.white : ext.fgMuted,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── AlertBanner ─────────────────────────────────────────────────
enum AlertVariant { warn, red, green }

class AlertBanner extends StatelessWidget {
  final String text;
  final AlertVariant variant;
  final Widget? leading;

  const AlertBanner({super.key, required this.text, this.variant = AlertVariant.warn, this.leading});

  @override
  Widget build(BuildContext context) {
    Color bg, borderColor, fg;
    switch (variant) {
      case AlertVariant.warn:
        bg = AppColors.warn.withValues(alpha: 0.12);
        borderColor = AppColors.warn.withValues(alpha: 0.3);
        fg = AppColors.warn;
        break;
      case AlertVariant.red:
        bg = AppColors.danger.withValues(alpha: 0.12);
        borderColor = AppColors.danger.withValues(alpha: 0.3);
        fg = AppColors.danger;
        break;
      case AlertVariant.green:
        bg = AppColors.accent.withValues(alpha: 0.10);
        borderColor = AppColors.accent.withValues(alpha: 0.25);
        fg = AppColors.accent;
        break;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          leading ?? Icon(Icons.warning_amber_rounded, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: fg))),
        ],
      ),
    );
  }
}

// ─── StatCard ────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String? delta;
  final Color? deltaColor;

  const StatCard({super.key, required this.value, required this.label, this.delta, this.deltaColor});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ext.surface,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        border: Border.all(color: ext.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: ext.fg), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.sourceCodePro(
              fontSize: 10,
              color: ext.fgMuted,
              letterSpacing: 0.5,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(delta!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: deltaColor ?? AppColors.accent), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

// ─── QtyStepperWidget ────────────────────────────────────────────
class QtyStepperWidget extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final double scale;

  const QtyStepperWidget({super.key, required this.value, this.onChanged, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Transform.scale(
      scale: scale,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.rSm),
          border: Border.all(color: ext.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn('−', () => onChanged?.call((value - 1).clamp(0, 999)), ext),
            Container(
              width: 40,
              alignment: Alignment.center,
              color: ext.surface,
              child: Text('$value', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ext.fg)),
            ),
            _btn('+', () => onChanged?.call((value + 1).clamp(0, 999)), ext),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, AppThemeExtension ext) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        color: ext.surface2,
        child: Text(label, style: TextStyle(fontSize: 18, color: ext.fg)),
      ),
    );
  }
}

// ─── ToggleSwitch ────────────────────────────────────────────────
class ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ToggleSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value ? AppColors.accentDk : ext.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? AppColors.accentDk : ext.border),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SectionLabel ────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text.toUpperCase(),
            style: GoogleFonts.sourceCodePro(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: ext.fgMuted,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─── BillLine ────────────────────────────────────────────────────
class BillLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  const BillLine({super.key, required this.label, required this.value, this.isTotal = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTotal ? 12 : 8),
      decoration: BoxDecoration(
        border: isTotal
            ? Border(top: BorderSide(color: ext.border))
            : Border(bottom: BorderSide(color: ext.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: isTotal ? ext.fg : ext.fgMuted,
          )),
          Text(value, style: TextStyle(
            fontSize: isTotal ? 17 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: valueColor ?? (isTotal ? AppColors.accent : ext.fg),
          )),
        ],
      ),
    );
  }
}

// ─── Timeline Widget ─────────────────────────────────────────────
class TimelineItem {
  final String label;
  final String time;
  final bool done;
  const TimelineItem({required this.label, required this.time, this.done = false});
}

class TimelineWidget extends StatelessWidget {
  final List<TimelineItem> items;
  const TimelineWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final ext = context.appTheme;
    return Column(
      children: items.asMap().entries.map((e) {
        final item = e.value;
        final isLast = e.key == items.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.done ? AppColors.accent : ext.surface2,
                        border: Border.all(color: item.done ? AppColors.accent : ext.border, width: 2),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 2, color: ext.border),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: ext.fg)),
                      const SizedBox(height: 2),
                      Text(item.time, style: TextStyle(fontSize: 11, color: ext.fgMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
