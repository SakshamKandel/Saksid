import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/song_model.dart';

/// Immutable queue state representing the single source of truth
/// for playlist and playback state.
///
/// All mutations return a new QueueState instance.
/// Player subscribes to this state - never mutates it directly.
class QueueState extends Equatable {
  final List<SongModel> tracks;
  final int currentIndex;
  final LoopMode repeatMode;
  final int? shuffleSeed;
  final List<int>? _shuffledIndices;

  const QueueState({
    this.tracks = const [],
    this.currentIndex = 0,
    this.repeatMode = LoopMode.off,
    this.shuffleSeed,
    List<int>? shuffledIndices,
  }) : _shuffledIndices = shuffledIndices;

  /// Empty queue state
  static const empty = QueueState();

  /// Whether shuffle mode is enabled
  bool get isShuffled => shuffleSeed != null;

  /// Current track or null if queue is empty
  SongModel? get currentTrack {
    if (tracks.isEmpty || currentIndex < 0 || currentIndex >= tracks.length) {
      return null;
    }
    return isShuffled && _shuffledIndices != null
        ? tracks[_shuffledIndices![currentIndex]]
        : tracks[currentIndex];
  }

  /// Next track or null if at end
  SongModel? get nextTrack {
    final nextIdx = _getNextIndex();
    if (nextIdx == null) return null;

    return isShuffled && _shuffledIndices != null
        ? tracks[_shuffledIndices![nextIdx]]
        : tracks[nextIdx];
  }

  /// Previous track or null if at start
  SongModel? get previousTrack {
    final prevIdx = _getPreviousIndex();
    if (prevIdx == null) return null;

    return isShuffled && _shuffledIndices != null
        ? tracks[_shuffledIndices![prevIdx]]
        : tracks[prevIdx];
  }

  /// Whether queue is empty
  bool get isEmpty => tracks.isEmpty;

  /// Whether queue has tracks
  bool get isNotEmpty => tracks.isNotEmpty;

  /// Total track count
  int get length => tracks.length;

  /// Whether there's a next track available
  bool get hasNext {
    if (tracks.isEmpty) return false;
    if (repeatMode == LoopMode.all || repeatMode == LoopMode.one) return true;
    return currentIndex < tracks.length - 1;
  }

  /// Whether there's a previous track available
  bool get hasPrevious {
    if (tracks.isEmpty) return false;
    if (repeatMode == LoopMode.all || repeatMode == LoopMode.one) return true;
    return currentIndex > 0;
  }

  /// Get track at index (respects shuffle if enabled)
  SongModel? trackAt(int index) {
    if (index < 0 || index >= tracks.length) return null;
    return isShuffled && _shuffledIndices != null
        ? tracks[_shuffledIndices![index]]
        : tracks[index];
  }

  /// Get the display order of tracks
  List<SongModel> get displayTracks {
    if (!isShuffled || _shuffledIndices == null) return tracks;
    return _shuffledIndices!.map((i) => tracks[i]).toList();
  }

  // === Mutation Methods (return new QueueState) ===

  /// Set a new playlist
  QueueState withTracks(List<SongModel> newTracks, {int startIndex = 0}) {
    if (newTracks.isEmpty) return QueueState.empty;

    final clampedIndex = startIndex.clamp(0, newTracks.length - 1);
    final newShuffledIndices = isShuffled
        ? _generateShuffledIndices(newTracks.length, shuffleSeed!)
        : null;

    return QueueState(
      tracks: List.unmodifiable(newTracks),
      currentIndex: clampedIndex,
      repeatMode: repeatMode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: newShuffledIndices,
    );
  }

  /// Move to next track
  QueueState toNext() {
    final nextIdx = _getNextIndex();
    if (nextIdx == null) return this;

    return QueueState(
      tracks: tracks,
      currentIndex: nextIdx,
      repeatMode: repeatMode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: _shuffledIndices,
    );
  }

  /// Move to previous track
  QueueState toPrevious() {
    final prevIdx = _getPreviousIndex();
    if (prevIdx == null) return this;

    return QueueState(
      tracks: tracks,
      currentIndex: prevIdx,
      repeatMode: repeatMode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: _shuffledIndices,
    );
  }

  /// Jump to specific index
  QueueState toIndex(int index) {
    if (index < 0 || index >= tracks.length) return this;

    return QueueState(
      tracks: tracks,
      currentIndex: index,
      repeatMode: repeatMode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: _shuffledIndices,
    );
  }

  /// Toggle repeat mode: off -> all -> one -> off
  QueueState withNextRepeatMode() {
    LoopMode newMode;
    switch (repeatMode) {
      case LoopMode.off:
        newMode = LoopMode.all;
        break;
      case LoopMode.all:
        newMode = LoopMode.one;
        break;
      case LoopMode.one:
        newMode = LoopMode.off;
        break;
    }

    return QueueState(
      tracks: tracks,
      currentIndex: currentIndex,
      repeatMode: newMode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: _shuffledIndices,
    );
  }

  /// Set specific repeat mode
  QueueState withRepeatMode(LoopMode mode) {
    return QueueState(
      tracks: tracks,
      currentIndex: currentIndex,
      repeatMode: mode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: _shuffledIndices,
    );
  }

  /// Toggle shuffle mode
  QueueState toggleShuffle() {
    if (isShuffled) {
      // Turn off shuffle - find current track's real index
      final currentTrackId = currentTrack?.id;
      int newIndex = currentIndex;
      if (currentTrackId != null) {
        newIndex = tracks.indexWhere((t) => t.id == currentTrackId);
        if (newIndex == -1) newIndex = 0;
      }

      return QueueState(
        tracks: tracks,
        currentIndex: newIndex,
        repeatMode: repeatMode,
        shuffleSeed: null,
        shuffledIndices: null,
      );
    } else {
      // Turn on shuffle
      final seed = DateTime.now().millisecondsSinceEpoch;
      final shuffledIndices = _generateShuffledIndices(tracks.length, seed);

      // Put current track first in shuffled order
      final currentTrackId = currentTrack?.id;
      if (currentTrackId != null) {
        final realIndex = tracks.indexWhere((t) => t.id == currentTrackId);
        if (realIndex != -1) {
          shuffledIndices.remove(realIndex);
          shuffledIndices.insert(0, realIndex);
        }
      }

      return QueueState(
        tracks: tracks,
        currentIndex: 0,
        repeatMode: repeatMode,
        shuffleSeed: seed,
        shuffledIndices: shuffledIndices,
      );
    }
  }

  /// Add track to queue
  QueueState withAddedTrack(SongModel track, {bool addNext = false}) {
    final newTracks = List<SongModel>.from(tracks);

    if (addNext && tracks.isNotEmpty) {
      newTracks.insert(currentIndex + 1, track);
    } else {
      newTracks.add(track);
    }

    List<int>? newShuffledIndices;
    if (isShuffled && _shuffledIndices != null) {
      newShuffledIndices = List<int>.from(_shuffledIndices!);
      if (addNext) {
        newShuffledIndices.insert(currentIndex + 1, newTracks.length - 1);
      } else {
        newShuffledIndices.add(newTracks.length - 1);
      }
    }

    return QueueState(
      tracks: List.unmodifiable(newTracks),
      currentIndex: currentIndex,
      repeatMode: repeatMode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: newShuffledIndices,
    );
  }

  /// Remove track from queue
  QueueState withRemovedTrack(int index) {
    if (index < 0 || index >= tracks.length) return this;

    final newTracks = List<SongModel>.from(tracks)..removeAt(index);

    if (newTracks.isEmpty) return QueueState.empty;

    int newCurrentIndex = currentIndex;
    if (index < currentIndex) {
      newCurrentIndex--;
    } else if (index == currentIndex) {
      newCurrentIndex = newCurrentIndex.clamp(0, newTracks.length - 1);
    }

    List<int>? newShuffledIndices;
    if (isShuffled && _shuffledIndices != null) {
      newShuffledIndices = _shuffledIndices!
          .where((i) => i != index)
          .map((i) => i > index ? i - 1 : i)
          .toList();
    }

    return QueueState(
      tracks: List.unmodifiable(newTracks),
      currentIndex: newCurrentIndex,
      repeatMode: repeatMode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: newShuffledIndices,
    );
  }

  /// Update a track in the queue (e.g., when stream URL is resolved)
  QueueState withUpdatedTrack(SongModel updatedTrack) {
    final index = tracks.indexWhere((t) => t.id == updatedTrack.id);
    if (index == -1) return this;

    final newTracks = List<SongModel>.from(tracks);
    newTracks[index] = updatedTrack;

    return QueueState(
      tracks: List.unmodifiable(newTracks),
      currentIndex: currentIndex,
      repeatMode: repeatMode,
      shuffleSeed: shuffleSeed,
      shuffledIndices: _shuffledIndices,
    );
  }

  /// Clear the queue
  QueueState clear() => QueueState.empty;

  // === Private Helpers ===

  int? _getNextIndex() {
    if (tracks.isEmpty) return null;

    if (repeatMode == LoopMode.one) {
      return currentIndex;
    }

    final nextIdx = currentIndex + 1;
    if (nextIdx >= tracks.length) {
      if (repeatMode == LoopMode.all) {
        return 0;
      }
      return null;
    }

    return nextIdx;
  }

  int? _getPreviousIndex() {
    if (tracks.isEmpty) return null;

    if (repeatMode == LoopMode.one) {
      return currentIndex;
    }

    final prevIdx = currentIndex - 1;
    if (prevIdx < 0) {
      if (repeatMode == LoopMode.all) {
        return tracks.length - 1;
      }
      return null;
    }

    return prevIdx;
  }

  static List<int> _generateShuffledIndices(int length, int seed) {
    final random = Random(seed);
    final indices = List<int>.generate(length, (i) => i);
    indices.shuffle(random);
    return indices;
  }

  @override
  List<Object?> get props => [
    tracks,
    currentIndex,
    repeatMode,
    shuffleSeed,
  ];

  @override
  String toString() {
    return 'QueueState(tracks: ${tracks.length}, currentIndex: $currentIndex, '
        'repeatMode: $repeatMode, shuffled: $isShuffled)';
  }
}
