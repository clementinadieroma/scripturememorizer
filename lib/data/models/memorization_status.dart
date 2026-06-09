enum MemorizationStatus {
  notStarted,
  inProgress,
  memorized;

  String get label {
    switch (this) {
      case MemorizationStatus.notStarted:
        return 'Not started';
      case MemorizationStatus.inProgress:
        return 'In progress';
      case MemorizationStatus.memorized:
        return 'Memorized';
    }
  }

  static MemorizationStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return MemorizationStatus.inProgress;
      case 'memorized':
        return MemorizationStatus.memorized;
      default:
        return MemorizationStatus.notStarted;
    }
  }

  String toStorageString() {
    switch (this) {
      case MemorizationStatus.notStarted:
        return 'not_started';
      case MemorizationStatus.inProgress:
        return 'in_progress';
      case MemorizationStatus.memorized:
        return 'memorized';
    }
  }
}
