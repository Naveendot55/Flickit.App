/// Represents which foot performed the toe tap.
enum FootSide {
  left,
  right;

  String get displayName => this == FootSide.left ? 'LEFT' : 'RIGHT';
}
