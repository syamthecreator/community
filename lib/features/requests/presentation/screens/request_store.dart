import 'package:community/features/home/models/request.dart';
import 'package:flutter/material.dart';

/// Simple in-memory list of the user's requests.
///
/// Home, Requests and Report an Issue all read from / write to this, so a
/// submitted report shows up everywhere straight away.
/// Replace with your repository / API + state management later.
class RequestStore extends ChangeNotifier {
  RequestStore._();

  static final RequestStore instance = RequestStore._();

  int _nextNumber = 1042;
  final List<Request> _requests = _seed();

  /// Newest first.
  List<Request> get requests => List.unmodifiable(_requests);

  /// Adds a new report (status: pending) and returns it.
  Request add({
    required String category,
    required String issue,
    required String unit,
    required String tower,
    required IconData icon,
    String note = '',
  }) {
    final request = Request(
      id: '#RPT-${_nextNumber++}',
      category: category,
      issue: issue,
      unit: unit,
      tower: tower,
      icon: icon,
      note: note,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );

    _requests.insert(0, request);
    notifyListeners();
    return request;
  }
}

List<Request> _seed() {
  final now = DateTime.now();

  return [
    Request(
      id: '#RPT-1041',
      category: 'Plumbing',
      issue: 'Leakage',
      unit: 'Flat 201',
      tower: 'Tower A',
      icon: Icons.plumbing_rounded,
      note: 'Water dripping from the kitchen sink pipe.',
      status: RequestStatus.inProgress,
      createdAt: now.subtract(const Duration(hours: 2)),
      assignedTo: 'Ravi (Plumber)',
    ),
    Request(
      id: '#RPT-1040',
      category: 'Electrical',
      issue: 'Power socket',
      unit: 'Flat 201',
      tower: 'Tower A',
      icon: Icons.bolt_rounded,
      status: RequestStatus.resolved,
      createdAt: now.subtract(const Duration(days: 1)),
      assignedTo: 'Suresh (Electrician)',
    ),
    Request(
      id: '#RPT-1039',
      category: 'Lift',
      issue: 'Not working',
      unit: 'Flat 201',
      tower: 'Tower A',
      icon: Icons.elevator_outlined,
      status: RequestStatus.assigned,
      createdAt: now.subtract(const Duration(days: 2)),
      assignedTo: 'Building caretaker',
    ),
    Request(
      id: '#RPT-1038',
      category: 'Cleaning',
      issue: 'Common area',
      unit: 'Flat 201',
      tower: 'Tower A',
      icon: Icons.cleaning_services_outlined,
      note: 'Corridor on the 2nd floor needs cleaning.',
      status: RequestStatus.resolved,
      createdAt: now.subtract(const Duration(days: 5)),
      assignedTo: 'Housekeeping',
    ),
  ];
}
