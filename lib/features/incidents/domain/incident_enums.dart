enum IncidentCategory {
  facilities('Facilities', 'Doors, roofs, lifts, classrooms'),
  water('Water', 'Shortages, leaks, taps'),
  electricity('Electricity', 'Outages, sockets, lighting'),
  furniture('Furniture', 'Broken chairs, desks, beds'),
  sanitation('Sanitation', 'Toilets, waste, cleanliness'),
  safety('Safety', 'Hazards, security concerns'),
  other('Other', 'Anything else on campus');

  const IncidentCategory(this.label, this.hint);

  final String label;
  final String hint;

  static IncidentCategory parse(String? value) =>
      values.firstWhere((item) => item.name == value, orElse: () => other);
}

enum IncidentSeverity {
  low('Low'),
  medium('Medium'),
  high('Urgent');

  const IncidentSeverity(this.label);

  final String label;

  static IncidentSeverity parse(String? value) =>
      values.firstWhere((item) => item.name == value, orElse: () => medium);
}

enum IncidentStatus {
  submitted('Submitted'),
  inReview('In review'),
  inProgress('In progress'),
  resolved('Resolved'),
  dismissed('Dismissed');

  const IncidentStatus(this.label);

  final String label;

  static const stages = [submitted, inReview, inProgress, resolved];

  bool get isOpen => this != resolved && this != dismissed;

  List<IncidentStatus> get nextOptions => switch (this) {
        submitted => const [inReview, inProgress, resolved, dismissed],
        inReview => const [inProgress, resolved, dismissed],
        inProgress => const [resolved, dismissed],
        resolved => const [inProgress],
        dismissed => const [inReview],
      };

  static IncidentStatus parse(String? value) =>
      values.firstWhere((item) => item.name == value, orElse: () => submitted);
}
