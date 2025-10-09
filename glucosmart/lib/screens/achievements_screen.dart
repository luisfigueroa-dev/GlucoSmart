import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/gamification.dart';

/// Pantalla de logros y progreso de gamificación.
/// Muestra estadísticas, logros completados y disponibles.
/// Compatible con WCAG 2.2 AA para accesibilidad.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);

    if (authProvider.user != null) {
      await gamificationProvider.initializeGamification(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros y Progreso'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Progreso', icon: Icon(Icons.trending_up)),
            Tab(text: 'Logros', icon: Icon(Icons.emoji_events)),
            Tab(text: 'Estadísticas', icon: Icon(Icons.bar_chart)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Consumer<GamificationProvider>(
        builder: (context, gamificationProvider, child) {
          if (gamificationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gamificationProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${gamificationProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildProgressTab(gamificationProvider),
              _buildAchievementsTab(gamificationProvider),
              _buildStatsTab(gamificationProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressTab(GamificationProvider provider) {
    final userStats = provider.userStats;

    if (userStats == null) {
      return const Center(
        child: Text('Cargando estadísticas...'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nivel y puntos
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grade,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nivel ${userStats.level}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${userStats.totalPoints} puntos totales',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Barra de progreso del nivel
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progreso del Nivel',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: userStats.levelProgress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userStats.currentLevelPoints} / ${userStats.currentLevelPoints + userStats.pointsToNextLevel} puntos',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Racha actual
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    color: provider.isInCurrentStreak ? Colors.orange : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Racha Actual',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${userStats.currentStreak} días consecutivos',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        if (userStats.longestStreak > userStats.currentStreak)
                          Text(
                            'Récord: ${userStats.longestStreak} días',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Progreso general
          Text(
            'Progreso General',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    value: provider.totalProgress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(provider.totalProgress * 100).toInt()}% completado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${provider.completedAchievements.length} de ${provider.userAchievements.length} logros',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(GamificationProvider provider) {
    final completed = provider.completedAchievements;
    final available = provider.availableAchievements;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Completados'),
              Tab(text: 'Disponibles'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAchievementsList(completed, true),
                _buildAchievementsList(available, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(List<Achievement> achievements, bool isCompleted) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.emoji_events : Icons.lock,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted
                  ? 'Aún no has completado ningún logro'
                  : 'No hay logros disponibles en este momento',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index], isCompleted);
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isCompleted) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Ícono del logro
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                _getIconData(achievement.iconName),
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Información del logro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),

                  // Barra de progreso o estado
                  if (!isCompleted) ...[
                    LinearProgressIndicator(
                      value: achievement.progressPercentage,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${achievement.currentValue} / ${achievement.targetValue}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          achievement.isClaimed ? Icons.check_circle : Icons.star,
                          color: achievement.isClaimed ? Colors.green : Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          achievement.isClaimed
                              ? 'Reclamado (+${achievement.points} pts)'
                              : 'Completado (+${achievement.points} pts)',
                          style: TextStyle(
                            color: achievement.isClaimed ? Colors.green : Colors.amber,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Botón de reclamar si aplica
            if (isCompleted && !achievement.isClaimed) ...[
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _claimReward(achievement),
                child: const Text('Reclamar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsTab(GamificationProvider provider) {
    final userStats = provider.userStats;

    if (userStats == null) {
      return const Center(child: Text('No hay estadísticas disponibles'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas Detalladas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Estadísticas principales
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Puntos Totales',
                userStats.totalPoints.toString(),
                Icons.stars,
                Colors.amber,
              ),
              _buildStatCard(
                'Nivel Actual',
                userStats.level.toString(),
                Icons.grade,
                Colors.blue,
              ),
              _buildStatCard(
                'Racha Actual',
                '${userStats.currentStreak} días',
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildStatCard(
                'Racha Máxima',
                '${userStats.longestStreak} días',
                Icons.whatshot,
                Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logros por categoría
          Text(
            'Logros por Categoría',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          ...AchievementCategory.values.map((category) {
            final categoryAchievements = provider.getAchievementsByCategory(category);
            final completedCount = categoryAchievements.where((a) => a.isCompleted).length;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                leading: Icon(_getCategoryIcon(category), color: _getCategoryColor(category)),
                title: Text(_getCategoryName(category)),
                subtitle: Text('$completedCount de ${categoryAchievements.length} completados'),
                trailing: CircularProgressIndicator(
                  value: categoryAchievements.isEmpty ? 0 : completedCount / categoryAchievements.length,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(category)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimReward(Achievement achievement) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gamificationProvider = Provider.of<GamificationProvider>(context, listen: false);

    if (authProvider.user != null) {
      await gamificationProvider.claimAchievementReward(
        achievement.id,
        authProvider.user!.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Reclamaste ${achievement.points} puntos!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'bloodtype':
        return Icons.bloodtype;
      case 'timeline':
        return Icons.timeline;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'restaurant':
        return Icons.restaurant;
      case 'school':
        return Icons.school;
      case 'medication':
        return Icons.medication;
      case 'share':
        return Icons.share;
      case 'grade':
        return Icons.grade;
      default:
        return Icons.emoji_events;
    }
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.health:
        return Icons.favorite;
      case AchievementCategory.knowledge:
        return Icons.lightbulb;
      case AchievementCategory.community:
        return Icons.people;
      case AchievementCategory.special:
        return Icons.star;
    }
  }

  Color _getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.health:
        return Colors.red;
      case AchievementCategory.knowledge:
        return Colors.blue;
      case AchievementCategory.community:
        return Colors.green;
      case AchievementCategory.special:
        return Colors.purple;
    }
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.health:
        return 'Salud';
      case AchievementCategory.knowledge:
        return 'Conocimiento';
      case AchievementCategory.community:
        return 'Comunidad';
      case AchievementCategory.special:
        return 'Especial';
    }
  }
}