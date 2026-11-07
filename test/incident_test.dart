import 'package:campus_incident_reporting_app/features/incidents/domain/incident.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/incident_enums.dart';
import 'package:campus_incident_reporting_app/features/incidents/domain/incident_filter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Incident _incident({
  String id = '1',
  String title = 'Water shortage',
  String location = 'Student residence',
  IncidentCategory category = IncidentCategory.water,
  IncidentSeverity severity = IncidentSeverity.medium,
  IncidentStatus status = IncidentStatus.submitted,
  String reporterId = 'owner',
  DateTime? createdAt,
}) {
  final time = createdAt ?? DateTime(2026, 11, 1);
  return Incident(
    id: id,
    title: title,
    description: 'No water since the morning',
    location: location,
    category: category,
    severity: severity,
    status: status,
    reporterId: reporterId,
    createdAt: time,
    updatedAt: time,
  );
}

void main() {
  group('Incident.fromMap', () {
    test('reads a stored report', () {
      final incident = Incident.fromMap('abc', {
        'title': 'Broken door',
        'description': 'The lab door does not close',
        'location': 'Lab',
        'category': 'facilities',
        'severity': 'high',
        'status': 'inProgress',
        'reporterId': 'owner',
        'reporterName': 'Ada',
        'affectedBy': ['u1', 'u2'],
        'timeline': [
          {'status': 'submitted', 'actorName': 'Ada', 'at': Timestamp.fromDate(DateTime(2026)), 'note': ''},
        ],
        'createdAt': Timestamp.fromDate(DateTime(2026)),
      });

      expect(incident.category, IncidentCategory.facilities);
      expect(incident.severity, IncidentSeverity.high);
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.affectedBy, hasLength(2));
      expect(incident.timeline.single.status, IncidentStatus.submitted);
      expect(incident.updatedAt, DateTime(2026));
      expect(incident.isAnonymous, isFalse);
    });

    test('falls back safely on unknown or pending values', () {
      final incident = Incident.fromMap('abc', {'category': 'unknown', 'status': 'unknown'});

      expect(incident.category, IncidentCategory.other);
      expect(incident.status, IncidentStatus.submitted);
      expect(incident.isAnonymous, isTrue);
    });
  });

  test('only the owner can edit, and only before staff act', () {
    expect(_incident().canEdit('owner'), isTrue);
    expect(_incident().canEdit('someone'), isFalse);
    expect(_incident(status: IncidentStatus.inReview).canEdit('owner'), isFalse);
  });

  group('IncidentFilter', () {
    final items = [
      _incident(id: 'a', status: IncidentStatus.resolved),
      _incident(
        id: 'b',
        title: 'Power cut',
        location: 'Library',
        category: IncidentCategory.electricity,
        reporterId: 'me',
      ),
    ];

    List<String> ids(IncidentFilter filter) => filter.apply(items, 'me').map((item) => item.id).toList();

    test('searches title, description and location ignoring case', () {
      expect(ids(const IncidentFilter(query: 'POWER')), ['b']);
      expect(ids(const IncidentFilter(query: 'library')), ['b']);
      expect(ids(const IncidentFilter(query: 'morning')), ['a', 'b']);
    });

    test('combines status, category and ownership', () {
      expect(ids(const IncidentFilter(status: IncidentStatus.resolved)), ['a']);
      expect(ids(const IncidentFilter(category: IncidentCategory.electricity)), ['b']);
      expect(ids(const IncidentFilter(mineOnly: true)), ['b']);
      expect(ids(const IncidentFilter(mineOnly: true, status: IncidentStatus.resolved)), isEmpty);
    });

    test('copyWith can clear a selected status', () {
      const filter = IncidentFilter(status: IncidentStatus.resolved);
      expect(filter.copyWith(status: () => null).status, isNull);
      expect(filter.copyWith(query: 'x').status, IncidentStatus.resolved);
    });
  });

  test('staff queue puts urgent first, then oldest', () {
    final queue = staffQueue([
      _incident(id: 'new-low', severity: IncidentSeverity.low, createdAt: DateTime(2026, 2)),
      _incident(id: 'new-high', severity: IncidentSeverity.high, createdAt: DateTime(2026, 3)),
      _incident(id: 'old-high', severity: IncidentSeverity.high, createdAt: DateTime(2026, 1)),
    ]);

    expect(queue.map((item) => item.id), ['old-high', 'new-high', 'new-low']);
  });

  test('similar reports ignore closed items and other categories', () {
    final found = similarOpenIncidents(
      [
        _incident(id: 'open'),
        _incident(id: 'closed', status: IncidentStatus.resolved),
        _incident(id: 'other', category: IncidentCategory.safety),
      ],
      IncidentCategory.water,
      'residence',
    );

    expect(found.map((item) => item.id), ['open']);
  });

  test('status moves forward and closed reports can reopen', () {
    expect(IncidentStatus.submitted.nextOptions, contains(IncidentStatus.inReview));
    expect(IncidentStatus.resolved.nextOptions, [IncidentStatus.inProgress]);
    expect(IncidentStatus.resolved.isOpen, isFalse);
    expect(IncidentStatus.inReview.isOpen, isTrue);
  });
}
