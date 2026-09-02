part of 'flip_book.dart';

// ── Index / TOC ───────────────────────────────────────────────────────────────

class _IndexPage extends StatefulWidget {
  const _IndexPage({
    required this.pages,
    required this.currentPage,
    required this.contents,
    required this.footer,
    required this.onSelect,
    required this.onClose,
    this.header,
    this.headerAction,
    this.onExport,
  });

  final List<FlipBookPage> pages;
  final int currentPage;
  final FlipBookContents contents;
  final FlipBookFooter footer;
  final FlipBookHeader? header;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;
  final Widget? headerAction;

  /// Opens the export chooser. Null when the book has no `contents.export`,
  /// and then no button is drawn.
  final VoidCallback? onExport;

  @override
  State<_IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<_IndexPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final export = widget.contents.export;
    final filtered = [
      for (int i = 0; i < widget.pages.length; i++)
        if (widget.pages[i].title != null &&
            widget.pages[i].title!.toLowerCase().contains(_query.toLowerCase()))
          (index: i, title: widget.pages[i].title!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FlipBookHeader(
          closeIcon: widget.header?.closeIcon ?? Icons.close,
          closeIconColor: widget.header?.closeColor ?? Colors.black54,
          closeLabel: widget.header?.closeLabel ?? 'Close',
          onClose: widget.onClose,
          headerAction: widget.headerAction,
          closeAtEnd: widget.header?.closeAtEnd ?? false,
        ),

        // ── Content ───────────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The heading shares its line with Export. The contents
                // page is the one screen showing the whole book at once, so
                // "which pages" is a question the reader is already here to
                // answer.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.contents.heading,
                        style: widget.contents.headingStyle,
                      ),
                    ),
                    if (widget.onExport != null && export != null)
                      _FooterControl(
                        semanticLabel: export.label,
                        onTap: widget.onExport!,
                        child: export.child ??
                            Icon(
                              export.icon ?? Icons.ios_share,
                              size: widget.footer.iconSize,
                              color: widget.contents.currentIconColor,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: widget.contents.searchStyle,
                  decoration: InputDecoration(
                    hintText: widget.contents.searchHint,
                    hintStyle: widget.contents.searchHintStyle,
                    prefixIcon: Icon(
                      widget.contents.searchIcon,
                      size: 16,
                      color: widget.contents.searchIconColor,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    filled: true,
                    fillColor: widget.contents.searchFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: widget.contents.searchFocusBorder,
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Divider(color: widget.contents.dividerColor),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: widget.contents.dividerColor, height: 1),
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      final isCurrent = item.index == widget.currentPage;
                      return InkWell(
                        onTap: () => widget.onSelect(item.index),
                        splashColor: widget.contents.splashColor,
                        highlightColor: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '${item.index + 1}',
                                  style: widget.contents.numberStyle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: isCurrent
                                      ? widget.contents.currentStyle
                                      : widget.contents.titleStyle,
                                ),
                              ),
                              if (isCurrent)
                                Icon(
                                  widget.contents.currentIcon,
                                  size: 14,
                                  color: widget.contents.currentIconColor,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The chevron that points the way a page actually travels.
///
/// A `Row` reverses its children under RTL, so the previous button moves to
/// the right — but its glyph does not turn with it, which showed an Arabic
/// reader `> <` where the arrows should read `< >`. Only the two package
/// defaults are mirrored; an icon the caller chose is returned untouched,
/// because flipping someone else's artwork would be a guess.
IconData _navIcon(IconData icon, {required bool back, required bool rtl}) {
  if (!rtl || (icon != Icons.chevron_left && icon != Icons.chevron_right)) {
    return icon;
  }
  return back ? Icons.chevron_right : Icons.chevron_left;
}
