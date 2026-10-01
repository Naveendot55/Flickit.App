/// State machine phases for foot-to-ball interaction.
/// Designed with hysteresis to prevent noisy jitter across threshold boundaries.
enum TapState {
  /// Foot is comfortably separated from the ball (distance > releaseDistanceRatio).
  away,

  /// Foot is moving towards the ball with negative distance velocity.
  approaching,

  /// Foot has entered the contact zone (distance <= contactDistanceRatio).
  /// Tap count increments on entering this state from approaching/away.
  contact,

  /// Foot is moving away from the ball after contact, but hasn't reached the full away threshold.
  release;

  String get displayName {
    switch (this) {
      case TapState.away:
        return 'AWAY';
      case TapState.approaching:
        return 'APPROACHING';
      case TapState.contact:
        return 'CONTACT';
      case TapState.release:
        return 'RELEASE';
    }
  }
}
