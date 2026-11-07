import 'incident.dart';
import 'incident_enums.dart';

class IncidentFilter {
  const IncidentFilter({this.query = '', this.status, this.category, this.mineOnly = false});

  final String query;
  final IncidentStatus? status;
  final IncidentCategory? category;
  final bool mineOnly;

  bool get isActive => query.isNotEmpty || status != null || category != null || mineOnly;

  IncidentFilter copyWith({
    String? query,
    IncidentStatus? Function()? status,
    IncidentCategory? Function()? category,
    bool? mineOnly,
  }) => IncidentFilter(
    query: query ?? this.query,
    status: status != null ? status() : this.status,
    category: category != null ? category() : this.category,
    mineOnly: mineOnly ?? this.mineOnly,
  );

  List<Incident> apply(List<Incident> incidents, String? uid) {
    final needle = query.trim().toLowerCase();
    return incidents.where((incident) {
      if (status != null && incident.status != status) return false;
      if (category != null && incident.category != category) return false;
      if (mineOnly && !incident.isOwnedBy(uid)) return false;
      if (needle.isEmpty) return true;
      return incident.title.toLowerCase().contains(needle) ||
          incident.description.toLowerCase().contains(needle) ||
          incident.location.toLowerCase().contains(needle);
    }).toList();
  }
}

List<Incident> staffQueue(List<Incident> incidents) {
  final queue = [...incidents];
  queue.sort((a, b) {
    final severity = b.severity.index.compareTo(a.severity.index);
    return severity != 0 ? severity : a.createdAt.compareTo(b.createdAt);
  });
  return queue;
}

List<Incident> similarOpenIncidents(List<Incident> incidents, IncidentCategory category, String location) {
  final place = location.trim().toLowerCase();
  if (place.length < 2) return const [];
  return incidents
      .where(
        (incident) =>
            incident.status.isOpen && incident.category == category && incident.location.toLowerCase().contains(place),
      )
      .toList();
}
