class Disease {
  final int diseaseId;
  final String name;
  final String? description;

  Disease({
    required this.diseaseId,
    required this.name,
    this.description,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      diseaseId: json['disease_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disease_id': diseaseId,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() => name;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Disease && 
           other.diseaseId == diseaseId && 
           other.name == name;
  }
  
  @override
  int get hashCode => diseaseId.hashCode ^ name.hashCode;
}