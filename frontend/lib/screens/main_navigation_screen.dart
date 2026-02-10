import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ticket_list_screen.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';
import 'article_categories_screen.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/ticket/ticket_bloc.dart';
import '../blocs/ticket/ticket_event.dart';
import '../blocs/ticket/ticket_state.dart';
import '../models/ticket_model.dart';
import '../widgets/stat_card.dart';
import '../widgets/error_display.dart';
import '../utils/biometric_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Lazy load screens untuk mengurangi memory usage
  late final List<Widget> _screens = [
    const DashboardScreenContent(),
    const TicketListScreen(),
    const ArticleCategoriesScreen(),
    const ProfileScreenContent(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Tickets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article_outlined),
              activeIcon: Icon(Icons.article),
              label: 'Articles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper untuk Dashboard yang bisa digunakan tanpa AppBar
class DashboardScreenContent extends StatefulWidget {
  const DashboardScreenContent({super.key});

  @override
  State<DashboardScreenContent> createState() => _DashboardScreenContentState();
}

class _DashboardScreenContentState extends State<DashboardScreenContent> {
  List<Ticket> _tickets = [];
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load tickets once on init
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
                  content: Text(ticketState.message),
                  backgroundColor: Colors.red,
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
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (ticketState is TicketError && _tickets.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: const Text('Dashboard')),
                body: ErrorDisplay(
                  message: 'Error: ${ticketState.message}',
                  onRetry: () {
                    if (userEmail != null) {
                      _hasLoaded = false;
                      _loadTickets(force: true);
                    }
                  },
                ),
              );
            }

            final stats = _getStatistics(_tickets);
            final recentTickets = _getRecentTickets(_tickets);

            return Scaffold(
              appBar: AppBar(
                title: Text('Welcome${userName != null ? ', $userName' : ''}'),
              ),
              body: RefreshIndicator(
                onRefresh: () async {
                  if (userEmail != null) {
                    _hasLoaded = false;
                    _loadTickets(force: true);
                  }
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Page header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const CreateTicketScreen(),
                                    ),
                                  )
                                  .then((_) {
                                    // Reload tickets after creating
                                    if (userEmail != null) {
                                      _hasLoaded = false;
                                      _loadTickets(force: true);
                                    }
                                  });
                            },
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Create Ticket'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Statistics Cards
                      _buildStatisticsCards(context, stats),
                      const SizedBox(height: 24),

                      // Chart Section
                      _buildChartSection(context, stats),
                      const SizedBox(height: 24),

                      // Recent Tickets
                      _buildRecentTicketsSection(context, recentTickets),
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

  // Calculate statistics
  Map<String, int> _getStatistics(List<Ticket> tickets) {
    final int total = tickets.length;
    final int open = tickets
        .where(
          (t) =>
              t.status?.toLowerCase() == 'open' ||
              t.status?.toLowerCase() == 'pending',
        )
        .length;
    final int inProgress = tickets
        .where(
          (t) =>
              t.status?.toLowerCase() == 'in progress' ||
              t.status?.toLowerCase() == 'in_progress',
        )
        .length;
    final int resolved = tickets
        .where((t) => t.status?.toLowerCase() == 'resolved')
        .length;
    final int closed = tickets
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
  List<Ticket> _getRecentTickets(List<Ticket> tickets) {
    final sorted = List<Ticket>.from(tickets);
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

  Widget _buildStatisticsCards(BuildContext context, Map<String, int> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        StatCard(
          title: 'Total Tickets',
          value: stats['total']!.toString(),
          icon: Icons.receipt_long,
          color: Theme.of(context).colorScheme.primary,
        ),
        StatCard(
          title: 'Open',
          value: stats['open']!.toString(),
          icon: Icons.lock_open,
          color: Colors.orange,
        ),
        StatCard(
          title: 'In Progress',
          value: stats['inProgress']!.toString(),
          icon: Icons.sync,
          color: Colors.blue,
        ),
        StatCard(
          title: 'Resolved',
          value: stats['resolved']!.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context, Map<String, int> stats) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ticket Status Distribution',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (stats['open']! > 0)
                      PieChartSectionData(
                        value: stats['open']!.toDouble(),
                        title: '${stats['open']}',
                        color: Colors.orange,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    if (stats['inProgress']! > 0)
                      PieChartSectionData(
                        value: stats['inProgress']!.toDouble(),
                        title: '${stats['inProgress']}',
                        color: Colors.blue,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    if (stats['resolved']! > 0)
                      PieChartSectionData(
                        value: stats['resolved']!.toDouble(),
                        title: '${stats['resolved']}',
                        color: Colors.green,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    if (stats['closed']! > 0)
                      PieChartSectionData(
                        value: stats['closed']!.toDouble(),
                        title: '${stats['closed']}',
                        color: Colors.grey,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (stats['open']! > 0)
                  _buildLegendItem(theme, 'Open', Colors.orange),
                if (stats['inProgress']! > 0)
                  _buildLegendItem(theme, 'In Progress', Colors.blue),
                if (stats['resolved']! > 0)
                  _buildLegendItem(theme, 'Resolved', Colors.green),
                if (stats['closed']! > 0)
                  _buildLegendItem(theme, 'Closed', Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
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
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                // Switch to Tickets tab - using a callback would be better
                // For now, we'll just navigate to ticket list screen
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TicketListScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTickets.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tickets yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentTickets.map(
            (ticket) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  if (ticket.id != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TicketDetailScreen(ticketId: ticket.id.toString()),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  ticket.prettyId ?? '#${ticket.id}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      ticket.status,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        ticket.status,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    ticket.status ?? 'Unknown',
                                    style: TextStyle(
                                      color: _getStatusColor(ticket.status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(ticket.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Profile Screen
class ProfileScreenContent extends StatefulWidget {
  const ProfileScreenContent({super.key});

  @override
  State<ProfileScreenContent> createState() => _ProfileScreenContentState();
}

class _ProfileScreenContentState extends State<ProfileScreenContent> {
  bool _biometricEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final enabled = await BiometricPreferences.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      await BiometricPreferences.enableBiometric();
    } else {
      await BiometricPreferences.disableBiometric();
    }
    if (!mounted) return;
    setState(() {
      _biometricEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'User';
        String userEmail = '';
        String userLastName = '';

        if (state is AuthAuthenticated) {
          userName = state.userName ?? 'User';
          userEmail = state.userEmail ?? '';
          // Get lastname from auth response
          userLastName = state.authResponse.lastname;
        }

        final fullName = userLastName.isNotEmpty
            ? '$userName $userLastName'
            : userName;

        return Scaffold(
          appBar: AppBar(title: const Text('Profile')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            fullName.isNotEmpty
                                ? fullName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (userEmail.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            userEmail,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Account Information
                Text(
                  'Account Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Name'),
                        subtitle: Text(fullName),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(
                          userEmail.isNotEmpty ? userEmail : 'N/A',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Security Settings
                if (Platform.isAndroid) ...[
                  Text(
                    'Security Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.fingerprint),
                          title: const Text('Login dengan Sidik Jari'),
                          subtitle: const Text(
                            'Gunakan sidik jari untuk login cepat',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: Switch(
                            value: _biometricEnabled,
                            onChanged: _toggleBiometric,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Actions
                Text(
                  'Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final authBloc = context.read<AuthBloc>();
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && mounted) {
                            authBloc.add(const AuthLogout());
                            // Navigation handled by AuthWrapper
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
