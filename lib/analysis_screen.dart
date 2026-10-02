import 'package:eplace/profile_service.dart';
import 'package:eplace/session_manager.dart';
import 'package:flutter/material.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final userId = await SessionManager.getUserId();
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final data = await ProfileService.fetchUserAnalytics(userId);

    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }
  }

  /// Helper to pick bar colors based on performance percentages
  Color _getBarColor(int percentage) {
    if (percentage >= 80) return Colors.greenAccent;
    if (percentage >= 60) return Colors.blueAccent;
    if (percentage >= 40) return Colors.amberAccent;
    if (percentage >= 20) return Colors.purpleAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          title: const Text('Analysis', style: TextStyle(color: Colors.white)),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    // Dynamic Calculations with Fallbacks
    final int createdCount = _analyticsData?['createdLeagues'] ?? 0;
    final int maxCreated = _analyticsData?['maxCreatedLeagues'] ?? 50;
    final int playedCount = _analyticsData?['leaguesPlayed'] ?? 0;
    final int wonCount = _analyticsData?['leaguesWon'] ?? 0;
    final int neverWonCount = (playedCount - wonCount).clamp(0, playedCount);

    final double winRate = playedCount > 0 ? (wonCount / playedCount) * 100 : 0.0;
    final double lossRate = playedCount > 0 ? 100.0 - winRate : 0.0;

    final List rawRecent = _analyticsData?['recentPerformances'] ?? [0, 0, 0, 0, 0];
    final List<int> recentPerformances = rawRecent.map((e) => (e as num).toInt()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            Icon(Icons.bar_chart, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              'Analysis',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAnalytics,
          color: Colors.blueAccent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LEAGUE OVERVIEW METRICS
                _buildMetricRow('Created leagues', '$createdCount / $maxCreated'),
                const SizedBox(height: 10),
                _buildMetricRow('Leagues played', '$playedCount'),
                const SizedBox(height: 10),
                _buildMetricRow('Won', '$wonCount', valueColor: Colors.greenAccent),
                const SizedBox(height: 10),
                _buildMetricRow('Never won', '$neverWonCount', valueColor: Colors.redAccent),

                const SizedBox(height: 28),
                const Divider(color: Colors.white24),
                const SizedBox(height: 20),

                // 2. PROGRESS SECTION
                const Text(
                  'Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Last 5 leagues performance',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),

                // 3. BAR CHART DISPLAY
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: recentPerformances.map((pct) {
                      final Color barColor = _getBarColor(pct);
                      final double barHeight = (pct / 100) * 130;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 32,
                            height: barHeight < 4 ? 4 : barHeight, // Minimum visible height
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(color: Colors.white24),
                const SizedBox(height: 20),

                // 4. WIN / LOSS PROBABILITIES
                _buildMetricRow(
                  'Possibility to win',
                  '${winRate.toStringAsFixed(0)}%',
                  valueColor: Colors.greenAccent,
                ),
                const SizedBox(height: 10),
                _buildMetricRow(
                  'Possibility not to win',
                  '${lossRate.toStringAsFixed(0)}%',
                  valueColor: Colors.orangeAccent,
                ),

                const SizedBox(height: 80),

                // 5. FOOTER LOGO BRANDING
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/eplace.png',
                        height: 60,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.sports_soccer,
                          color: Colors.blueAccent,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ePlace Football\nEvolution',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String title, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}