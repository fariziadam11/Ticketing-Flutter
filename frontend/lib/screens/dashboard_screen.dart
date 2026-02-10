import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/ticket/ticket_bloc.dart';
import '../blocs/ticket/ticket_event.dart';
import '../blocs/ticket/ticket_state.dart';
import '../models/ticket_model.dart';
import 'ticket_list_screen.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';
import '../widgets/error_display.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Ticket> _tickets = [];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTickets();
    });
  }

  void _loadTickets({bool force = false}) {
    if (_hasLoaded && !force) return;

    final authState = context.read<AuthBloc>().state;
    String? userEmail;
    if (authState is AuthAuthenticated) {
      userEmail = authState.userEmail;
    }

    if (userEmail != null) {
      _hasLoaded = true;
      context.read<TicketBloc>().add(
        TicketLoadList(creatorId: userEmail, page: 1, limit: 100),
      );
    }
  }

  // Calculate statistics
  Map<String, int> _getStatistics() {
    final int total = _tickets.length;
    final int open = _tickets
        .where(
          (t) =>
              t.status?.toLowerCase() == 'open' ||
              t.status?.toLowerCase() == 'pending',
        )
        .length;
    final int inProgress = _tickets
        .where(
          (t) =>
              t.status?.toLowerCase() == 'in progress' ||
              t.status?.toLowerCase() == 'in_progress',
        )
        .length;
    final int resolved = _tickets
        .where((t) => t.status?.toLowerCase() == 'resolved')
        .length;
    final int closed = _tickets
        .where((t) => t.status?.toLowerCase() == 'closed')
        .length;

    return {
      'total': total,
      'open': open,
      'inProgress': inProgress,
      'resolved': resolved,
      'closed': closed,
    };
  }

  // Get recent tickets (last 5)
  List<Ticket> _getRecentTickets() {
    final sorted = List<Ticket>.from(_tickets);
    sorted.sort((a, b) {
      final aTime = a.createdAt ?? 0;
      final bTime = b.createdAt ?? 0;
      return bTime.compareTo(aTime);
    });
    return sorted.take(5).toList();
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
      case 'pending':
        return Colors.orange;
      case 'in progress':
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final userName = authState is AuthAuthenticated
            ? authState.userName
            : null;
        final userEmail = authState is AuthAuthenticated
            ? authState.userEmail
            : null;

        return BlocConsumer<TicketBloc, TicketState>(
          listener: (context, ticketState) {
            if (ticketState is TicketListLoaded) {
              setState(() {
                _tickets = ticketState.response.data;
              });
            } else if (ticketState is TicketError && _tickets.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(ticketState.message)),
                    ],
                  ),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            }
          },
          builder: (context, ticketState) {
            final isLoading = ticketState is TicketLoading && _tickets.isEmpty;

            if (isLoading) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Welcome${userName != null ? ', $userName' : ''}',
                  ),
                  elevation: 0,
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (ticketState is TicketError && _tickets.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Dashboard'), elevation: 0),
                body: ErrorDisplay(
                  message: ticketState.message,
                  onRetry: () {
                    if (userEmail != null) {
                      _hasLoaded = false;
                      _loadTickets(force: true);
                    }
                  },
                ),
              );
            }

            final stats = _getStatistics();
            final recentTickets = _getRecentTickets();

            return Scaffold(
              appBar: AppBar(
                title: Text('Welcome${userName != null ? ', $userName' : ''}'),
                elevation: 0,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      if (userEmail != null) {
                        _hasLoaded = false;
                        _loadTickets(force: true);
                      }
                    },
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  if (userEmail != null) {
                    _hasLoaded = false;
                    _loadTickets(force: true);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Header with gradient
                      _buildWelcomeHeader(context, userName),
                      const SizedBox(height: 32),

                      // Statistics Cards with improved design
                      _buildStatisticsCards(context, stats),
                      const SizedBox(height: 28),

                      // Chart Section with modern design
                      _buildChartSection(context, stats),
                      const SizedBox(height: 28),

                      // Recent Tickets with improved design
                      _buildRecentTicketsSection(context, recentTickets),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String? userName) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Overview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName != null
                      ? 'Welcome back, $userName!'
                      : 'Welcome back!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(BuildContext context, Map<String, int> stats) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final navigator = Navigator.of(context);
                final authBloc = context.read<AuthBloc>();
                navigator
                    .push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateTicketScreen(),
                      ),
                    )
                    .then((_) {
                      if (!mounted) return;
                      final authState = authBloc.state;
                      if (authState is AuthAuthenticated) {
                        _hasLoaded = false;
                        _loadTickets(force: true);
                      }
                    });
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('New Ticket'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildModernStatCard(
              context,
              'Total Tickets',
              stats['total']!.toString(),
              Icons.receipt_long_rounded,
              [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            _buildModernStatCard(
              context,
              'Open',
              stats['open']!.toString(),
              Icons.lock_open_rounded,
              [Colors.orange, Colors.orange.shade300],
            ),
            _buildModernStatCard(
              context,
              'In Progress',
              stats['inProgress']!.toString(),
              Icons.sync_rounded,
              [Colors.blue, Colors.blue.shade300],
            ),
            _buildModernStatCard(
              context,
              'Resolved',
              stats['resolved']!.toString(),
              Icons.check_circle_rounded,
              [Colors.green, Colors.green.shade300],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
  ) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, animValue, child) {
        return Transform.scale(
          scale: 0.9 + (animValue * 0.1),
          child: Opacity(
            opacity: animValue,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartSection(BuildContext context, Map<String, int> stats) {
    final theme = Theme.of(context);
    final total = stats['total']!;
    if (total == 0) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No data to display',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status Distribution',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$total Total',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 240,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  sections: [
                    if (stats['open']! > 0)
                      PieChartSectionData(
                        value: stats['open']!.toDouble(),
                        title: '${stats['open']}',
                        color: Colors.orange,
                        radius: 75,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    if (stats['inProgress']! > 0)
                      PieChartSectionData(
                        value: stats['inProgress']!.toDouble(),
                        title: '${stats['inProgress']}',
                        color: Colors.blue,
                        radius: 75,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    if (stats['resolved']! > 0)
                      PieChartSectionData(
                        value: stats['resolved']!.toDouble(),
                        title: '${stats['resolved']}',
                        color: Colors.green,
                        radius: 75,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    if (stats['closed']! > 0)
                      PieChartSectionData(
                        value: stats['closed']!.toDouble(),
                        title: '${stats['closed']}',
                        color: Colors.grey,
                        radius: 75,
                        titleStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: [
                if (stats['open']! > 0)
                  _buildModernLegendItem(
                    theme,
                    'Open',
                    Colors.orange,
                    stats['open']!,
                  ),
                if (stats['inProgress']! > 0)
                  _buildModernLegendItem(
                    theme,
                    'In Progress',
                    Colors.blue,
                    stats['inProgress']!,
                  ),
                if (stats['resolved']! > 0)
                  _buildModernLegendItem(
                    theme,
                    'Resolved',
                    Colors.green,
                    stats['resolved']!,
                  ),
                if (stats['closed']! > 0)
                  _buildModernLegendItem(
                    theme,
                    'Closed',
                    Colors.grey,
                    stats['closed']!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernLegendItem(
    ThemeData theme,
    String label,
    Color color,
    int value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($value)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTicketsSection(
    BuildContext context,
    List<Ticket> recentTickets,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Tickets',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TicketListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTickets.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No tickets yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first ticket to get started',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentTickets.asMap().entries.map((entry) {
            final index = entry.key;
            final ticket = entry.value;
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, animValue, child) {
                return Opacity(
                  opacity: animValue,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - animValue)),
                    child: child,
                  ),
                );
              },
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    if (ticket.id != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TicketDetailScreen(
                            ticketId: ticket.id.toString(),
                          ),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        // Status indicator
                        Container(
                          width: 4,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _getStatusColor(ticket.status),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        ticket.status,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ticket.status ?? 'Unknown',
                                      style: TextStyle(
                                        color: _getStatusColor(ticket.status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    ticket.prettyId ?? '#${ticket.id}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimestamp(ticket.createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.3,
                          ),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
