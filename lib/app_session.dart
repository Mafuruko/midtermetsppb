class AppSession {
  static const String defaultTeamName = 'BCFC 2026';

  static String? currentTeamId;
  static String currentTeamName = defaultTeamName;

  static void selectTeam({required String id, required String name}) {
    currentTeamId = id;
    currentTeamName = name;
  }

  static void clearTeam() {
    currentTeamId = null;
    currentTeamName = defaultTeamName;
  }
}
