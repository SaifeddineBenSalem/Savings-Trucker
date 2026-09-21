enum UnitStatus {
  pending,
  done;

  String get label => this == UnitStatus.pending ? 'Pending' : 'Done';
}

enum UnitFilter {
  all,
  pending,
  done;

  String get label {
    switch (this) {
      case UnitFilter.all:
        return 'ALL';
      case UnitFilter.pending:
        return 'PENDING';
      case UnitFilter.done:
        return 'DONE';
    }
  }
}
