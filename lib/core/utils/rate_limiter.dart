import 'dart:async';
import 'dart:math';

/// Token bucket rate limiter with jitter to prevent YouTube blocking.
///
/// Implements adaptive throttling with:
/// - Configurable requests per minute
/// - Randomized jitter (±300ms) to avoid burst patterns
/// - Exponential backoff on errors (429, socket reset)
class RateLimiter {
  final int maxRequestsPerMinute;
  final Duration jitterRange;

  final List<DateTime> _requestTimestamps = [];
  final Random _random = Random();

  int _backoffMultiplier = 1;
  static const int _maxBackoffMultiplier = 8;
  static const Duration _baseBackoff = Duration(seconds: 2);

  bool _isBackingOff = false;
  DateTime? _backoffUntil;

  RateLimiter({
    this.maxRequestsPerMinute = 30,
    this.jitterRange = const Duration(milliseconds: 300),
  });

  /// Schedule a request with rate limiting and jitter.
  /// Returns the result of the callback.
  Future<T> schedule<T>(Future<T> Function() callback) async {
    await _waitForSlot();
    await _applyJitter();

    try {
      final result = await callback();
      _onSuccess();
      return result;
    } catch (e) {
      _onError(e);
      rethrow;
    }
  }

  /// Wait until a request slot is available.
  Future<void> _waitForSlot() async {
    // Check if we're in backoff period
    if (_isBackingOff && _backoffUntil != null) {
      final now = DateTime.now();
      if (now.isBefore(_backoffUntil!)) {
        await Future.delayed(_backoffUntil!.difference(now));
      }
      _isBackingOff = false;
    }

    // Clean old timestamps (older than 1 minute)
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    _requestTimestamps.removeWhere((ts) => ts.isBefore(cutoff));

    // Wait if at capacity
    while (_requestTimestamps.length >= maxRequestsPerMinute) {
      final oldestRequest = _requestTimestamps.first;
      final waitUntil = oldestRequest.add(const Duration(minutes: 1));
      final waitDuration = waitUntil.difference(DateTime.now());

      if (waitDuration.isNegative) {
        _requestTimestamps.removeAt(0);
      } else {
        await Future.delayed(waitDuration + const Duration(milliseconds: 50));
        _requestTimestamps.removeWhere((ts) => ts.isBefore(cutoff));
      }
    }

    _requestTimestamps.add(DateTime.now());
  }

  /// Apply random jitter to avoid burst patterns.
  Future<void> _applyJitter() async {
    final jitterMs = _random.nextInt(jitterRange.inMilliseconds * 2) -
                     jitterRange.inMilliseconds;
    if (jitterMs > 0) {
      await Future.delayed(Duration(milliseconds: jitterMs));
    }
  }

  /// Reset backoff on successful request.
  void _onSuccess() {
    _backoffMultiplier = 1;
  }

  /// Apply exponential backoff on rate limit or network errors.
  void _onError(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    // Check for rate limiting indicators
    if (errorStr.contains('429') ||
        errorStr.contains('too many requests') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection reset')) {

      _isBackingOff = true;
      final backoffDuration = _baseBackoff * _backoffMultiplier;
      _backoffUntil = DateTime.now().add(backoffDuration);

      // Increase multiplier for next error (exponential backoff)
      _backoffMultiplier = min(_backoffMultiplier * 2, _maxBackoffMultiplier);
    }
  }

  /// Get current rate limit status.
  RateLimitStatus get status {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    _requestTimestamps.removeWhere((ts) => ts.isBefore(cutoff));

    return RateLimitStatus(
      requestsInWindow: _requestTimestamps.length,
      maxRequests: maxRequestsPerMinute,
      isBackingOff: _isBackingOff,
      backoffUntil: _backoffUntil,
    );
  }

  /// Reset the rate limiter state.
  void reset() {
    _requestTimestamps.clear();
    _backoffMultiplier = 1;
    _isBackingOff = false;
    _backoffUntil = null;
  }
}

/// Status information for the rate limiter.
class RateLimitStatus {
  final int requestsInWindow;
  final int maxRequests;
  final bool isBackingOff;
  final DateTime? backoffUntil;

  RateLimitStatus({
    required this.requestsInWindow,
    required this.maxRequests,
    required this.isBackingOff,
    this.backoffUntil,
  });

  double get utilizationPercent => (requestsInWindow / maxRequests) * 100;
  int get remainingRequests => maxRequests - requestsInWindow;
}
