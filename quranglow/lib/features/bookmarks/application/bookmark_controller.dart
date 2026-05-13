// ignore_for_file: dangling_library_doc_comments
/// Bookmark management controller
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/models/bookmark_models.dart';

class BookmarkState {
  const BookmarkState({
    required this.bookmarks,
    required this.folders,
    required this.isLoading,
    this.error,
  });

  final List<Bookmark> bookmarks;
  final List<BookmarkFolder> folders;
  final bool isLoading;
  final String? error;

  BookmarkState copyWith({
    List<Bookmark>? bookmarks,
    List<BookmarkFolder>? folders,
    bool? isLoading,
    String? error,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      folders: folders ?? this.folders,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  BookmarkStats getStats() {
    final favoriteCount = bookmarks.where((b) => b.isFavorite).length;
    final tags = <String>{};
    for (final bookmark in bookmarks) {
      tags.addAll(bookmark.tags);
    }

    return BookmarkStats(
      totalBookmarks: bookmarks.length,
      totalFolders: folders.length,
      favoriteCount: favoriteCount,
      tagCount: tags.length,
    );
  }
}

class BookmarkController extends StateNotifier<BookmarkState> {
  BookmarkController()
      : super(
          const BookmarkState(
            bookmarks: [],
            folders: [],
            isLoading: false,
          ),
        );

  /// Add bookmark
  void addBookmark(Bookmark bookmark) {
    final bookmarks = [...state.bookmarks, bookmark];
    state = state.copyWith(bookmarks: bookmarks);
  }

  /// Remove bookmark
  void removeBookmark(String bookmarkId) {
    final bookmarks = state.bookmarks
        .where((b) => b.id != bookmarkId)
        .toList();
    state = state.copyWith(bookmarks: bookmarks);
  }

  /// Update bookmark
  void updateBookmark(Bookmark bookmark) {
    final bookmarks = state.bookmarks.map((b) {
      return b.id == bookmark.id ? bookmark : b;
    }).toList();
    state = state.copyWith(bookmarks: bookmarks);
  }

  /// Toggle favorite
  void toggleFavorite(String bookmarkId) {
    final bookmarks = state.bookmarks.map((b) {
      if (b.id == bookmarkId) {
        return b.copyWith(isFavorite: !b.isFavorite);
      }
      return b;
    }).toList();
    state = state.copyWith(bookmarks: bookmarks);
  }

  /// Add tag to bookmark
  void addTag(String bookmarkId, String tag) {
    final bookmarks = state.bookmarks.map((b) {
      if (b.id == bookmarkId && !b.tags.contains(tag)) {
        return b.copyWith(tags: [...b.tags, tag]);
      }
      return b;
    }).toList();
    state = state.copyWith(bookmarks: bookmarks);
  }

  /// Remove tag from bookmark
  void removeTag(String bookmarkId, String tag) {
    final bookmarks = state.bookmarks.map((b) {
      if (b.id == bookmarkId) {
        return b.copyWith(
          tags: b.tags.where((t) => t != tag).toList(),
        );
      }
      return b;
    }).toList();
    state = state.copyWith(bookmarks: bookmarks);
  }

  /// Create folder
  void createFolder(BookmarkFolder folder) {
    final folders = [...state.folders, folder];
    state = state.copyWith(folders: folders);
  }

  /// Delete folder
  void deleteFolder(String folderId) {
    final folders = state.folders
        .where((f) => f.id != folderId)
        .toList();
    state = state.copyWith(folders: folders);
  }

  /// Add bookmark to folder
  void addBookmarkToFolder(String folderId, Bookmark bookmark) {
    final folders = state.folders.map((f) {
      if (f.id == folderId) {
        return f.addBookmark(bookmark);
      }
      return f;
    }).toList();
    state = state.copyWith(folders: folders);
  }

  /// Remove bookmark from folder
  void removeBookmarkFromFolder(String folderId, String bookmarkId) {
    final folders = state.folders.map((f) {
      if (f.id == folderId) {
        return f.removeBookmark(bookmarkId);
      }
      return f;
    }).toList();
    state = state.copyWith(folders: folders);
  }

  /// Get bookmarks by Surah
  List<Bookmark> getBookmarksBySurah(int surahNumber) {
    return state.bookmarks
        .where((b) => b.surahNumber == surahNumber)
        .toList();
  }

  /// Get favorite bookmarks
  List<Bookmark> getFavorites() {
    return state.bookmarks.where((b) => b.isFavorite).toList();
  }

  /// Search bookmarks by tag
  List<Bookmark> searchByTag(String tag) {
    return state.bookmarks
        .where((b) => b.tags.contains(tag))
        .toList();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
