enum ModelStatus {
  idle,
  loading,
  ready,
  generating,
  error,
}

class ModelState {
  final ModelStatus status;
  final String? errorMessage;
  final bool hasMultimodal;
  final double progress;

  const ModelState({
    this.status = ModelStatus.idle,
    this.errorMessage,
    this.hasMultimodal = false,
    this.progress = 0.0,
  });

  ModelState copyWith({
    ModelStatus? status,
    String? errorMessage,
    bool? hasMultimodal,
    double? progress,
  }) => ModelState(
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    hasMultimodal: hasMultimodal ?? this.hasMultimodal,
    progress: progress ?? this.progress,
  );
}
