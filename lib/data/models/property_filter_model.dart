import 'dart:convert';

class PropertyFilterState {
  final String selectedCity;
  final String selectedIntent; // 'Buy' | 'Rent' | 'Commercial'
  final List<String> selectedLocalities;
  final List<String> selectedBhk;
  final List<String> selectedPropertyTypes;
  final List<String> selectedDevelopers;
  final List<String> selectedListedBy;
  final List<String> selectedConstructionStatus;
  final double minBudget; // in Lakhs/Cr representation
  final double maxBudget; // in Lakhs/Cr representation

  const PropertyFilterState({
    required this.selectedCity,
    required this.selectedIntent,
    required this.selectedLocalities,
    required this.selectedBhk,
    required this.selectedPropertyTypes,
    required this.selectedDevelopers,
    required this.selectedListedBy,
    required this.selectedConstructionStatus,
    required this.minBudget,
    required this.maxBudget,
  });

  factory PropertyFilterState.initial() {
    return const PropertyFilterState(
      selectedCity: '',
      selectedIntent: '', // '' = no intent filter; show all types
      selectedLocalities: [],
      selectedBhk: [],
      selectedPropertyTypes: [],
      selectedDevelopers: [],
      selectedListedBy: [],
      selectedConstructionStatus: [],
      minBudget: 0.0,
      maxBudget: 20.0, // Capped at 20.0 Cr+
    );
  }

  PropertyFilterState copyWith({
    String? selectedCity,
    String? selectedIntent,
    List<String>? selectedLocalities,
    List<String>? selectedBhk,
    List<String>? selectedPropertyTypes,
    List<String>? selectedDevelopers,
    List<String>? selectedListedBy,
    List<String>? selectedConstructionStatus,
    double? minBudget,
    double? maxBudget,
  }) {
    return PropertyFilterState(
      selectedCity: selectedCity ?? this.selectedCity,
      selectedIntent: selectedIntent ?? this.selectedIntent,
      selectedLocalities: selectedLocalities ?? this.selectedLocalities,
      selectedBhk: selectedBhk ?? this.selectedBhk,
      selectedPropertyTypes: selectedPropertyTypes ?? this.selectedPropertyTypes,
      selectedDevelopers: selectedDevelopers ?? this.selectedDevelopers,
      selectedListedBy: selectedListedBy ?? this.selectedListedBy,
      selectedConstructionStatus: selectedConstructionStatus ?? this.selectedConstructionStatus,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedCity': selectedCity,
      'selectedIntent': selectedIntent,
      'selectedLocalities': selectedLocalities,
      'selectedBhk': selectedBhk,
      'selectedPropertyTypes': selectedPropertyTypes,
      'selectedDevelopers': selectedDevelopers,
      'selectedListedBy': selectedListedBy,
      'selectedConstructionStatus': selectedConstructionStatus,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
    };
  }

  factory PropertyFilterState.fromMap(Map<String, dynamic> map) {
    return PropertyFilterState(
      selectedCity: map['selectedCity'] ?? '',
      selectedIntent: map['selectedIntent'] ?? '',
      selectedLocalities: List<String>.from(map['selectedLocalities'] ?? const []),
      selectedBhk: List<String>.from(map['selectedBhk'] ?? const []),
      selectedPropertyTypes: List<String>.from(map['selectedPropertyTypes'] ?? const []),
      selectedDevelopers: List<String>.from(map['selectedDevelopers'] ?? const []),
      selectedListedBy: List<String>.from(map['selectedListedBy'] ?? const []),
      selectedConstructionStatus: List<String>.from(map['selectedConstructionStatus'] ?? const []),
      minBudget: (map['minBudget'] as num?)?.toDouble() ?? 0.0,
      maxBudget: (map['maxBudget'] as num?)?.toDouble() ?? 20.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory PropertyFilterState.fromJson(String source) =>
      PropertyFilterState.fromMap(json.decode(source));
}
