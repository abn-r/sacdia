class UserClub {
  final String userClubId;
  final String userId;
  final int clubId;
  final int? clubAdvId;
  final int? clubPathfId;
  final int? clubMgId;
  final String clubName;

  UserClub({
    required this.userClubId,
    required this.userId,
    required this.clubId,
    this.clubAdvId,
    this.clubPathfId,
    this.clubMgId,
    required this.clubName,
  });

  factory UserClub.fromJson(Map<String, dynamic> json) {
    return UserClub(
      userClubId: json['user_club_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      clubId: json['club_id'] as int? ?? 0,
      clubAdvId: json['club_adv_id'] as int?,
      clubPathfId: json['club_pathf_id'] as int?,
      clubMgId: json['club_mg_id'] as int?,
      clubName: json['club_name'] as String? ?? 'Sin nombre',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_club_id': userClubId,
      'user_id': userId,
      'club_id': clubId,
      'club_adv_id': clubAdvId,
      'club_pathf_id': clubPathfId,
      'club_mg_id': clubMgId,
      'club_name': clubName,
    };
  }

  // Método estático para procesar una lista de clubes de la respuesta API
  static List<UserClub> fromJsonList(dynamic json) {
    List<UserClub> clubs = [];
    
    try {
      // Caso 1: La respuesta es un objeto con propiedad 'data' que contiene una lista
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        if (json['data'] is List) {
          final List clubsList = json['data'];
          clubs = clubsList
              .map((club) => UserClub.fromJson(club))
              .toList();
        }
      } 
      // Caso 2: La respuesta es directamente una lista
      else if (json is List) {
        clubs = json
            .map((club) => UserClub.fromJson(club))
            .toList();
      }
    } catch (e) {
      print('❌ Error al procesar lista de clubes: $e');
    }
    
    return clubs;
  }
} 