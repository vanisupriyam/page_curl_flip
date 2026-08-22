import 'package:flutter/widgets.dart';

/// The reader's two ways of keeping a place.
///
/// Pass it and both buttons appear on the footer's first line; leave it out
/// and the book has neither. They do different jobs and are deliberately not
/// one control:
///
/// | Button | Holds | For |
/// |---|---|---|
/// | **Bookmark** | ONE page | "carry on from here next time" |
/// | **Save** | MANY page ids | "these are the pages I care about" |
///
/// Neither interrupts anything. Tapping the bookmark while the voice is
/// reading does not stop the voice, does not clear a mark, and does not turn
/// a page — it reports a number and nothing else.
///
/// # The package stores nothing
///
/// Same seam as marks: values come in through [bookmarkedPage] and [saved],
/// changes go out through [onBookmark] and [onSavedChanged]. Where they live
/// — Hive, a file, a server — is the app's business.
///
/// ```dart
/// bookmarks: FlipBookBookmarks(
///   bookmarkedPage: box.get('resumeAt') as int?,
///   onBookmark: (page) => box.put('resumeAt', page),
///   saved: box.get('savedPages', defaultValue: const <String>{}),
///   onSavedChanged: (ids) => box.put('savedPages', ids),
/// )
/// ```
///
/// Re-opening the book at the stored page is `FlipBookPages.initialPage` —
/// the book does not do it for you, because only the app knows whether this
/// is the same reader.
@immutable
class FlipBookBookmarks {
  /// Creates the two controls; every field is optional, and a null callback
  /// simply hides its button.
  const FlipBookBookmarks({
    this.bookmarkedPage,
    this.onBookmark,
    this.saved = const <String>{},
    this.onSavedChanged,
    this.bookmarkChild,
    this.bookmarkedChild,
    this.saveChild,
    this.savedChild,
    this.bookmarkIcon,
    this.bookmarkedIcon,
    this.saveIcon,
    this.savedIcon,
    this.bookmarkLabel = 'Carry on from here',
    this.bookmarkedLabel = 'This is where you carry on',
    this.saveLabel = 'Save this page',
    this.unsaveLabel = 'Remove this page',
    this.color,
    this.activeColor,
  });

  /// The page the reader chose to carry on from, if any. Used to light the
  /// bookmark button when they are standing on it.
  final int? bookmarkedPage;

  /// Fires with the **0-based** page index the reader was on. No button
  /// without it.
  final ValueChanged<int>? onBookmark;

  /// Ids of the pages the reader saved. A page with no `FlipBookPage.id`
  /// cannot be saved — it would have nothing to be remembered by.
  final Set<String> saved;

  /// Fires with the complete new set when a page is saved or unsaved. No
  /// button without it.
  final ValueChanged<Set<String>>? onSavedChanged;

  /// Widget for the bookmark button in its resting state.
  final Widget? bookmarkChild;

  /// Widget for the bookmark button when this page IS the bookmark.
  final Widget? bookmarkedChild;

  /// Widget for the save button when this page is not saved.
  final Widget? saveChild;

  /// Widget for the save button when this page is saved.
  final Widget? savedChild;

  /// Icon for the bookmark button when [bookmarkChild] is null.
  final IconData? bookmarkIcon;

  /// Icon shown when this page is the bookmark.
  final IconData? bookmarkedIcon;

  /// Icon for the save button when [saveChild] is null.
  final IconData? saveIcon;

  /// Icon shown when this page is saved.
  final IconData? savedIcon;

  /// Tap label and screen-reader wording, resting state.
  final String bookmarkLabel;

  /// Wording when this page already is the bookmark.
  final String bookmarkedLabel;

  /// Wording for saving this page.
  final String saveLabel;

  /// Wording for removing it again.
  final String unsaveLabel;

  /// Colour of both buttons at rest. Null takes the footer's icon colour.
  final Color? color;

  /// Colour once a button is ON — bookmarked, or saved. Null keeps [color],
  /// which is why an app that wants the state to READ should set this.
  final Color? activeColor;
}
