enum CaptureStatus {
  pending,
  confirmed,
  dismissed;

  bool get isPending => this == CaptureStatus.pending;
  bool get isConfirmed => this == CaptureStatus.confirmed;
  bool get isDismissed => this == CaptureStatus.dismissed;
}

enum CaptureMode {
  reviewFirst,
  addAutomatically;

  bool get isReviewFirst => this == CaptureMode.reviewFirst;
  bool get isAddAutomatically => this == CaptureMode.addAutomatically;
}
