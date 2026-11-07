import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_enums.dart';

class TimelineEntry {
  const TimelineEntry({required this.status, required this.actorName, required this.at, this.note = ''});

  final IncidentStatus status;
  final String actorName;
  final DateTime at;
  final String note;

  factory TimelineEntry.fromMap(Map<String, dynamic> map) => TimelineEntry(
        status: IncidentStatus.parse(map['status'] as String?),
        actorName: map['actorName'] as String? ?? '',
        at: (map['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        note: map['note'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'status': status.name,
        'actorName': actorName,
        'at': Timestamp.fromDate(at),
        'note': note,
      };
}

class IncidentDraft {
  const IncidentDraft({
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.severity,
    this.anonymous = false,
  });

  final String title;
  final String description;
  final String location;
  final IncidentCategory category;
  final IncidentSeverity severity;
  final bool anonymous;

  Map<String, dynamic> toMap() => {
        'title': title.trim(),
        'description': description.trim(),
        'location': location.trim(),
        'category': category.name,
        'severity': severity.name,
      };
}

class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.severity,
    required this.status,
    required this.reporterId,
    required this.createdAt,
    required this.updatedAt,
    this.reporterName,
    this.imageUrl,
    this.imagePath,
    this.affectedBy = const [],
    this.timeline = const [],
  });

  final String id;
  final String title;
  final String description;
  final String location;
  final IncidentCategory category;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String reporterId;
  final String? reporterName;
  final String? imageUrl;
  final String? imagePath;
  final List<String> affectedBy;
  final List<TimelineEntry> timeline;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAnonymous => reporterName == null;
  bool isOwnedBy(String? uid) => reporterId == uid;
  bool canEdit(String? uid) => isOwnedBy(uid) && status == IncidentStatus.submitted;

  factory Incident.fromMap(String id, Map<String, dynamic> map) {
    final createdAt = (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Incident(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      location: map['location'] as String? ?? '',
      category: IncidentCategory.parse(map['category'] as String?),
      severity: IncidentSeverity.parse(map['severity'] as String?),
      status: IncidentStatus.parse(map['status'] as String?),
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String?,
      imageUrl: map['imageUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      affectedBy: List<String>.from(map['affectedBy'] as List? ?? const []),
      timeline: (map['timeline'] as List? ?? const [])
          .map((entry) => TimelineEntry.fromMap(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      createdAt: createdAt,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? createdAt,
    );
  }
}
