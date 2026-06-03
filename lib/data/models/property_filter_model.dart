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
  final List<String> selectedFurnishing;
  final bool verifiedOnly;
  final bool imagesOnly;
  final double minArea;
  final double maxArea;
  final List<String> selectedLeaseTypes;
  final List<String> selectedBathrooms;
  final List<String> selectedAge;
  final List<String> selectedAdded;
  final List<String> selectedAvailable;
  final List<String> selectedPowerBackup;
  final List<String> selectedAmenities;

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
    required this.selectedFurnishing,
    required this.verifiedOnly,
    required this.imagesOnly,
    required this.minArea,
    required this.maxArea,
    required this.selectedLeaseTypes,
    required this.selectedBathrooms,
    required this.selectedAge,
    required this.selectedAdded,
    required this.selectedAvailable,
    required this.selectedPowerBackup,
    required this.selectedAmenities,
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
      selectedFurnishing: [],
      verifiedOnly: false,
      imagesOnly: false,
      minArea: 0.0,
      maxArea: 5000.0,
      selectedLeaseTypes: [],
      selectedBathrooms: [],
      selectedAge: [],
      selectedAdded: [],
      selectedAvailable: [],
      selectedPowerBackup: [],
      selectedAmenities: [],
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
    List<String>? selectedFurnishing,
    bool? verifiedOnly,
    bool? imagesOnly,
    double? minArea,
    double? maxArea,
    List<String>? selectedLeaseTypes,
    List<String>? selectedBathrooms,
    List<String>? selectedAge,
    List<String>? selectedAdded,
    List<String>? selectedAvailable,
    List<String>? selectedPowerBackup,
    List<String>? selectedAmenities,
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
      selectedFurnishing: selectedFurnishing ?? this.selectedFurnishing,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      imagesOnly: imagesOnly ?? this.imagesOnly,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      selectedLeaseTypes: selectedLeaseTypes ?? this.selectedLeaseTypes,
      selectedBathrooms: selectedBathrooms ?? this.selectedBathrooms,
      selectedAge: selectedAge ?? this.selectedAge,
      selectedAdded: selectedAdded ?? this.selectedAdded,
      selectedAvailable: selectedAvailable ?? this.selectedAvailable,
      selectedPowerBackup: selectedPowerBackup ?? this.selectedPowerBackup,
      selectedAmenities: selectedAmenities ?? this.selectedAmenities,
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
      'selectedFurnishing': selectedFurnishing,
      'verifiedOnly': verifiedOnly,
      'imagesOnly': imagesOnly,
      'minArea': minArea,
      'maxArea': maxArea,
      'selectedLeaseTypes': selectedLeaseTypes,
      'selectedBathrooms': selectedBathrooms,
      'selectedAge': selectedAge,
      'selectedAdded': selectedAdded,
      'selectedAvailable': selectedAvailable,
      'selectedPowerBackup': selectedPowerBackup,
      'selectedAmenities': selectedAmenities,
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
      selectedFurnishing: List<String>.from(map['selectedFurnishing'] ?? const []),
      verifiedOnly: map['verifiedOnly'] as bool? ?? false,
      imagesOnly: map['imagesOnly'] as bool? ?? false,
      minArea: (map['minArea'] as num?)?.toDouble() ?? 0.0,
      maxArea: (map['maxArea'] as num?)?.toDouble() ?? 5000.0,
      selectedLeaseTypes: List<String>.from(map['selectedLeaseTypes'] ?? const []),
      selectedBathrooms: List<String>.from(map['selectedBathrooms'] ?? const []),
      selectedAge: List<String>.from(map['selectedAge'] ?? const []),
      selectedAdded: List<String>.from(map['selectedAdded'] ?? const []),
      selectedAvailable: List<String>.from(map['selectedAvailable'] ?? const []),
      selectedPowerBackup: List<String>.from(map['selectedPowerBackup'] ?? const []),
      selectedAmenities: List<String>.from(map['selectedAmenities'] ?? const []),
    );
  }

  String toJson() => json.encode(toMap());

  factory PropertyFilterState.fromJson(String source) =>
      PropertyFilterState.fromMap(json.decode(source));
}
