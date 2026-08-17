import 'package:flutter/material.dart';

/// Every icon `FlipBook` draws, overridable — the package gives a skeleton,
/// decoration is the user's. Replace any of them with any [IconData]:
///
/// ```dart
/// FlipBook(
///   icons: const FlipBookIcons(
///     next: Icons.arrow_forward_ios,
///     previous: Icons.arrow_back_ios,
///     volumeOn: Icons.music_note,
///   ),
///   ...
/// )
/// ```
///
/// The voice controls (PLAY, PAUSE, …) are text buttons, not icons — their
/// content is customized through `FlipBookVoiceChips`.
///
/// The [previous]/[next] pair is mirrored automatically under RTL so the
/// arrows keep pointing the way the page travels.
@immutable
class FlipBookIcons {
  /// Creates a set of icons; every field has a Material default.
  const FlipBookIcons({
    this.close = Icons.close,
    this.previous = Icons.chevron_left,
    this.next = Icons.chevron_right,
    this.volumeOn = Icons.volume_up,
    this.volumeOff = Icons.volume_off,
    this.search = Icons.search,
    this.bookmark = Icons.bookmark,
    this.size = 16,
  });

  /// The × button in the header.
  final IconData close;

  /// Chevron beside the PREV label.
  final IconData previous;

  /// Chevron beside the NEXT label.
  final IconData next;

  /// Speaker while the flip sound is on.
  final IconData volumeOn;

  /// Speaker while the flip sound is muted.
  final IconData volumeOff;

  /// Prefix icon of the table-of-contents search field.
  final IconData search;

  /// Marker on the table of contents' current row.
  final IconData bookmark;

  /// Size of the footer icons (the PREV/NEXT chevrons and the speaker).
  final double size;

  /// Returns a copy of this icon set with the given fields replaced.
  FlipBookIcons copyWith({
    IconData? close,
    IconData? previous,
    IconData? next,
    IconData? volumeOn,
    IconData? volumeOff,
    IconData? search,
    IconData? bookmark,
    double? size,
  }) {
    return FlipBookIcons(
      close: close ?? this.close,
      previous: previous ?? this.previous,
      next: next ?? this.next,
      volumeOn: volumeOn ?? this.volumeOn,
      volumeOff: volumeOff ?? this.volumeOff,
      search: search ?? this.search,
      bookmark: bookmark ?? this.bookmark,
      size: size ?? this.size,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FlipBookIcons &&
      other.close == close &&
      other.previous == previous &&
      other.next == next &&
      other.volumeOn == volumeOn &&
      other.volumeOff == volumeOff &&
      other.search == search &&
      other.bookmark == bookmark &&
      other.size == size;

  @override
  int get hashCode => Object.hash(
      close, previous, next, volumeOn, volumeOff, search, bookmark, size);
}
