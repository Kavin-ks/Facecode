import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facecode/services/stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Note: These are unit tests that don't actually connect to Firebase.
  // For real Firebase testing, you'd need to set up Firebase Test Lab or use mocks.
  
  group('StatsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
    test('increment games and wins', () async {
      const testUid = 'test_user_123';
      
      // Reset stats first
      await StatsService.resetStats(testUid);
      
      // Initially should be 0
      final initialGames = await StatsService.getGamesPlayed(testUid);
      final initialWins = await StatsService.getWins(testUid);
      expect(initialGames, 0);
      expect(initialWins, 0);
      
      // Increment games
      await StatsService.incrementGames(testUid);
      await StatsService.incrementGames(testUid);
      final gamesAfter = await StatsService.getGamesPlayed(testUid);
      expect(gamesAfter, 2);
      
      // Increment wins
      await StatsService.incrementWins(testUid);
      final winsAfter = await StatsService.getWins(testUid);
      expect(winsAfter, 1);
      
      // Clean up
      await StatsService.resetStats(testUid);
    });
    
    test('resetStats clears data', () async {
      const testUid = 'test_reset_user';
      
      // Add some stats
      await StatsService.incrementGames(testUid);
      await StatsService.incrementWins(testUid);
      
      // Reset
      await StatsService.resetStats(testUid);
      
      // Should be 0 again
      final games = await StatsService.getGamesPlayed(testUid);
      final wins = await StatsService.getWins(testUid);
      expect(games, 0);
      expect(wins, 0);
    });
    
    test('stats are isolated per user', () async {
      const user1 = 'user_1';
      const user2 = 'user_2';
      
      await StatsService.resetStats(user1);
      await StatsService.resetStats(user2);
      
      // User 1 plays 3 games, wins 1
      await StatsService.incrementGames(user1);
      await StatsService.incrementGames(user1);
      await StatsService.incrementGames(user1);
      await StatsService.incrementWins(user1);
      
      // User 2 plays 1 game, wins 1
      await StatsService.incrementGames(user2);
      await StatsService.incrementWins(user2);
      
      // Verify isolation
      final user1Games = await StatsService.getGamesPlayed(user1);
      final user1Wins = await StatsService.getWins(user1);
      final user2Games = await StatsService.getGamesPlayed(user2);
      final user2Wins = await StatsService.getWins(user2);
      
      expect(user1Games, 3);
      expect(user1Wins, 1);
      expect(user2Games, 1);
      expect(user2Wins, 1);
      
      // Clean up
      await StatsService.resetStats(user1);
      await StatsService.resetStats(user2);
    });
  });
  
  // Note: For AuthProvider tests, you would typically use mockito or firebase_auth_mocks
  // to mock Firebase Authentication without connecting to real Firebase.
  // Example structure (requires mocking setup):
  /*
  group('AuthProvider', () {
    test('initial state is not signed in', () {
      final provider = AuthProvider();
      expect(provider.isSignedIn, false);
      expect(provider.user, null);
      expect(provider.isBusy, false);
    });
    
    test('register creates new user', () async {
      // Would need mock FirebaseAuth
      final provider = AuthProvider();
      await provider.register('Test User', 'test@example.com', 'password123');
      expect(provider.isSignedIn, true);
      expect(provider.user?.email, 'test@example.com');
    });
  });
  */
}
