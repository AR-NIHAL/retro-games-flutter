enum GamePhase { ready, shooting, result, gameOver }

enum ShotResult { goal, saved, missed }

const int totalRounds = 10;
const double keeperReach = 40.0;
const int keeperReactionMinMs = 150;
const int keeperReactionMaxMs = 250;
