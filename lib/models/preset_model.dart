class WindPreset {
  final String id;
  final String title;
  final String modifiedTime;
  final bool isSelected;
  final double defaultF1;
  final double defaultF2;
  final double defaultF3;
  final String description;

  const WindPreset({
    required this.id,
    required this.title,
    required this.modifiedTime,
    this.isSelected = false,
    this.defaultF1 = 0.5,
    this.defaultF2 = 0.5,
    this.defaultF3 = 0.5,
    this.description = 'Physical wind simulation preset configuration.',
  });

  WindPreset copyWith({
    String? id,
    String? title,
    String? modifiedTime,
    bool? isSelected,
    double? defaultF1,
    double? defaultF2,
    double? defaultF3,
    String? description,
  }) {
    return WindPreset(
      id: id ?? this.id,
      title: title ?? this.title,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      isSelected: isSelected ?? this.isSelected,
      defaultF1: defaultF1 ?? this.defaultF1,
      defaultF2: defaultF2 ?? this.defaultF2,
      defaultF3: defaultF3 ?? this.defaultF3,
      description: description ?? this.description,
    );
  }
}
