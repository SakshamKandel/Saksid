/// Listener badge/rank model
/// Tiers based on listening hours:
/// - Bronze (Newcomer): 0-10 hours
/// - Silver (Music Fan): 10-50 hours
/// - Gold (Enthusiast): 50-200 hours
/// - Platinum (Audiophile): 200-500 hours
/// - Diamond (Legend): 500+ hours

enum ListenerTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

class ListenerBadge {
  final ListenerTier tier;
  final String name;
  final String description;
  final int currentHours;
  final int nextTierHours;
  final double progress;

  const ListenerBadge({
    required this.tier,
    required this.name,
    required this.description,
    required this.currentHours,
    required this.nextTierHours,
    required this.progress,
  });

  factory ListenerBadge.fromListeningHours(int hours) {
    if (hours >= 500) {
      return ListenerBadge(
        tier: ListenerTier.diamond,
        name: 'Diamond Legend',
        description: 'You are a true music legend!',
        currentHours: hours,
        nextTierHours: 500,
        progress: 1.0,
      );
    } else if (hours >= 200) {
      return ListenerBadge(
        tier: ListenerTier.platinum,
        name: 'Platinum Audiophile',
        description: 'Your music taste is impeccable!',
        currentHours: hours,
        nextTierHours: 500,
        progress: (hours - 200) / 300,
      );
    } else if (hours >= 50) {
      return ListenerBadge(
        tier: ListenerTier.gold,
        name: 'Gold Enthusiast',
        description: 'Music is your passion!',
        currentHours: hours,
        nextTierHours: 200,
        progress: (hours - 50) / 150,
      );
    } else if (hours >= 10) {
      return ListenerBadge(
        tier: ListenerTier.silver,
        name: 'Silver Music Fan',
        description: 'You love your tunes!',
        currentHours: hours,
        nextTierHours: 50,
        progress: (hours - 10) / 40,
      );
    } else {
      return ListenerBadge(
        tier: ListenerTier.bronze,
        name: 'Bronze Newcomer',
        description: 'Welcome to the music journey!',
        currentHours: hours,
        nextTierHours: 10,
        progress: hours / 10,
      );
    }
  }

  int get hoursToNextTier => nextTierHours - currentHours;
  bool get isMaxTier => tier == ListenerTier.diamond;
}
