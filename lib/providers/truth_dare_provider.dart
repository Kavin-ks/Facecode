import 'package:flutter/foundation.dart';
import 'package:facecode/models/player.dart';
import 'package:facecode/models/truth_dare_models.dart';
import 'package:facecode/services/truth_dare_service.dart';

class TruthDareProvider extends ChangeNotifier {
  final TruthDareService _service = TruthDareService();
  
  TruthDareMode? _mode;
  List<Player> _players = [];
  int _currentPlayerIndex = -1;
  
  TdAgeGroup _selectedAgeGroup = TdAgeGroup.teens;
  TdCategory _selectedCategory = TdCategory.trending;
  TdDifficulty _selectedDifficulty = TdDifficulty.medium;
  bool _safeMode = true;
  
  TdQuestion? _currentQuestion;
  bool _isLoading = false;
  String? _errorMessage;
  bool _useAIFallback = true;
  
  // Track used questions to avoid repeats within a session
  final Set<String> _sessionUsedQuestionIds = {};
  
  // Bookmarked questions
  final Set<String> _bookmarkedQuestionIds = {};

  TruthDareMode? get mode => _mode;
  List<Player> get players => _players;
  Player? get currentPlayer => _currentPlayerIndex != -1 ? _players[_currentPlayerIndex] : null;
  TdAgeGroup get selectedAgeGroup => _selectedAgeGroup;
  TdCategory get selectedCategory => _selectedCategory;
  TdDifficulty get selectedDifficulty => _selectedDifficulty;
  bool get safeMode => _safeMode;
  TdQuestion? get currentQuestion => _currentQuestion;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get useAIFallback => _useAIFallback;
  Set<String> get bookmarkedQuestions => _bookmarkedQuestionIds;

  void setMode(TruthDareMode mode) {
    _mode = mode;
    if (mode == TruthDareMode.withQuestions) {
      _service.seedDatabase(); // Fire and forget seeding if empty
    }
    notifyListeners();
  }

  bool addPlayer(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (_players.any((p) => p.name.toLowerCase() == trimmed.toLowerCase())) return false;
    _players.add(Player(id: DateTime.now().millisecondsSinceEpoch.toString(), name: trimmed));
    notifyListeners();
    return true;
  }

  bool addPlayerObject(Player player) {
    if (_players.any((p) => p.name.toLowerCase() == player.name.toLowerCase())) return false;
    _players.add(player);
    notifyListeners();
    return true;
  }

  void removePlayer(String id) {
    _players.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void setAgeGroup(TdAgeGroup group) {
    _selectedAgeGroup = group;
    notifyListeners();
  }

  void setCategory(TdCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDifficulty(TdDifficulty difficulty) {
    _selectedDifficulty = difficulty;
    notifyListeners();
  }

  void setSafeMode(bool value) {
    _safeMode = value;
    // Safe mode forces kids age group and clean categories
    if (value) {
      _selectedAgeGroup = TdAgeGroup.kids;
      if (_selectedCategory == TdCategory.spicy || _selectedCategory == TdCategory.crazy) {
        _selectedCategory = TdCategory.clean;
      }
    }
    notifyListeners();
  }

  void setUseAIFallback(bool value) {
    _useAIFallback = value;
    notifyListeners();
  }

  void setCurrentPlayer(int index) {
    _currentPlayerIndex = index;
    notifyListeners();
  }

  Future<void> fetchQuestion(TdType type) async {
    if (_mode != TruthDareMode.withQuestions) return;
    
    _isLoading = true;
    _currentQuestion = null;
    _errorMessage = null;
    notifyListeners();

    try {
      // Apply safe mode filtering
      final effectiveCategory = _safeMode && _selectedCategory == TdCategory.spicy 
          ? TdCategory.clean 
          : _selectedCategory;
      
      final questions = await _service.getQuestions(
        type: type,
        ageGroup: _selectedAgeGroup,
        category: effectiveCategory,
        difficulty: _selectedDifficulty,
        orderByTrending: _selectedCategory == TdCategory.trending,
        orderByMostAsked: _selectedCategory == TdCategory.mostAsked,
      );

      if (questions.isNotEmpty) {
        // Filter out already used questions in this session
        var availableQuestions = questions.where((q) => !_sessionUsedQuestionIds.contains(q.id)).toList();
        
        // If all questions used, reset history so we can play again
        if (availableQuestions.isEmpty) {
          _sessionUsedQuestionIds.clear();
          availableQuestions = questions;
        }
        
        // Pick random from the available set
        _currentQuestion = availableQuestions[DateTime.now().millisecond % availableQuestions.length];
        
        // Mark as used
        _sessionUsedQuestionIds.add(_currentQuestion!.id);
        
        // Fire and forget view tracking
        _service.incrementView(_currentQuestion!.id);
      } else if (_useAIFallback) {
        // Try AI generation
        _currentQuestion = await _service.generateAIQuestion(
          type: type,
          ageGroup: _selectedAgeGroup,
          category: effectiveCategory,
          difficulty: _selectedDifficulty,
        );
        
        if (_currentQuestion != null) {
          _sessionUsedQuestionIds.add(_currentQuestion!.id);
        } else {
          _errorMessage = 'No questions found. Try changing your filters.';
        }
      } else {
        _errorMessage = 'No questions found. Try changing your filters or enable AI fallback.';
      }
    } catch (e) {
      _errorMessage = 'Failed to load questions. Check your connection.';

      // Final fallback - try AI even if disabled in desperate situation
      _currentQuestion ??= await _service.generateAIQuestion(
        type: type,
        ageGroup: _selectedAgeGroup,
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> rateQuestion(bool isLike) async {
    if (_currentQuestion == null) return;
    await _service.rateQuestion(_currentQuestion!.id, isLike);
  }

  Future<void> toggleBookmark() async {
    if (_currentQuestion == null) return;
    
    final isBookmarked = _bookmarkedQuestionIds.contains(_currentQuestion!.id);
    if (isBookmarked) {
      _bookmarkedQuestionIds.remove(_currentQuestion!.id);
    } else {
      _bookmarkedQuestionIds.add(_currentQuestion!.id);
    }
    
    await _service.toggleBookmark(_currentQuestion!.id, !isBookmarked);
    notifyListeners();
  }

  void completeTurn() {
    if (_currentQuestion != null) {
      _service.incrementUsage(_currentQuestion!.id);
    }
    _currentQuestion = null;
    notifyListeners();
  }

  void resetGame() {
    _mode = null;
    _players = [];
    _currentPlayerIndex = -1;
    _currentQuestion = null;
    _sessionUsedQuestionIds.clear();
    notifyListeners();
  }
}
