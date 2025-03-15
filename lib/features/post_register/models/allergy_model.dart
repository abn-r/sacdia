class Allergy {
  final int allergyId;
  final String name;
  final String? description;

  Allergy({
    required this.allergyId,
    required this.name,
    this.description,
  });

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      allergyId: json['allergy_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergy_id': allergyId,
      'name': name,
      if (description != null) 'description': description,
    };
  }

  @override
  String toString() => name;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Allergy && 
          other.allergyId == allergyId && 
           other.name == name;
  }
  
  @override
  int get hashCode => allergyId.hashCode ^ name.hashCode;
}