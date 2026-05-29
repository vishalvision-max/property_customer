class SearchHistoryItem {
  final String id;
  final String searchText;
  final DateTime createdAt;

  const SearchHistoryItem({
    required this.id,
    required this.searchText,
    required this.createdAt,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: (json['id'] ?? '').toString(),
      searchText: (json['searchText'] ?? '').toString(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'searchText': searchText,
        'createdAt': createdAt.toIso8601String(),
      };
}
