import '../../domain/models/capture_item.dart';

class PendingCaptureGroup {
  final List<CaptureItem> items;

  const PendingCaptureGroup(this.items);

  CaptureItem get primary => items.first;
  bool get hasMultiple => items.length > 1;
}

List<PendingCaptureGroup> groupPendingCaptures(List<CaptureItem> items) {
  final groups = <List<CaptureItem>>[];

  for (final item in items) {
    List<CaptureItem>? duplicateGroup;
    for (final group in groups) {
      if ((item.isPossibleDuplicate ||
              group.any((existing) => existing.isPossibleDuplicate)) &&
          _sameLikelyTransaction(item, group.first)) {
        duplicateGroup = group;
        break;
      }
    }

    if (duplicateGroup == null) {
      groups.add([item]);
    } else {
      duplicateGroup.add(item);
    }
  }

  return groups.map(PendingCaptureGroup.new).toList();
}

bool _sameLikelyTransaction(CaptureItem first, CaptureItem second) {
  if (first.amountCents != second.amountCents ||
      first.type != second.type ||
      first.occurredAt.difference(second.occurredAt).abs() >
          const Duration(hours: 24)) {
    return false;
  }

  if (first.reference != null || second.reference != null) {
    return first.reference != null && first.reference == second.reference;
  }
  if (first.accountLast4 != null &&
      second.accountLast4 != null &&
      first.accountLast4 != second.accountLast4) {
    return false;
  }
  if (first.counterparty != null &&
      second.counterparty != null &&
      first.counterparty!.trim().toLowerCase() !=
          second.counterparty!.trim().toLowerCase()) {
    return false;
  }
  if (first.accountLast4 != null &&
      first.accountLast4 == second.accountLast4 &&
      first.counterparty != null &&
      first.counterparty!.trim().isNotEmpty &&
      first.counterparty!.trim().toLowerCase() ==
          second.counterparty?.trim().toLowerCase()) {
    return true;
  }

  return first.sender == second.sender &&
      first.occurredAt.difference(second.occurredAt).abs() <=
          const Duration(minutes: 10);
}
