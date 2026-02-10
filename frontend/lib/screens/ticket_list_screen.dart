import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/ticket/ticket_bloc.dart';
import '../blocs/ticket/ticket_event.dart';
import '../blocs/ticket/ticket_state.dart';
import '../models/ticket_model.dart';
import '../widgets/error_display.dart';
import 'ticket_detail_screen.dart';
import 'create_ticket_screen.dart';
import 'package:intl/intl.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  bool _hasLoaded = false;
  List<Ticket> _tickets = [];

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
        TicketLoadList(
          creatorId: userEmail,
          page: 1,
          limit: 10,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(
            PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const CreateTicketScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
            ),
          )
              .then((_) {
            _hasLoaded = false;
            _loadTickets(force: true);
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final userEmail = authState is AuthAuthenticated 
              ? authState.userEmail 
              : null;

          return BlocConsumer<TicketBloc, TicketState>(
            listener: (context, ticketState) {
              if (ticketState is TicketListLoaded) {
                // Update cache list hanya ketika list baru dimuat
                setState(() {
                  _tickets = ticketState.response.data;
                });
              } else if (ticketState is TicketError) {
                // Tampilkan error via SnackBar tapi jangan hapus list yang sudah ada
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ticketState.message,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            builder: (context, ticketState) {
              final isLoading = ticketState is TicketLoading && _tickets.isEmpty;

              if (isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Loading tickets...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Jika error tapi masih punya data sebelumnya, tetap tampilkan list
              if (ticketState is TicketError && _tickets.isEmpty) {
                return ErrorDisplay(
                  message: ticketState.message,
                  onRetry: () {
                    if (userEmail != null) {
                      context.read<TicketBloc>().add(
                        TicketLoadList(
                          creatorId: userEmail,
                          page: 1,
                          limit: 10,
                        ),
                      );
                    }
                  },
                );
              }

              final tickets = _tickets;

              return Column(
                children: [
                  // Header section with gradient
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Tickets',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${tickets.length} ${tickets.length == 1 ? 'ticket' : 'tickets'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _hasLoaded = false;
                        _loadTickets(force: true);
                      },
                      child: tickets.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No tickets yet',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create your first ticket to get started',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
                              itemCount: tickets.length,
                              itemBuilder: (context, index) {
                                final ticket = tickets[index];
                                return TweenAnimationBuilder<double>(
                                  duration: Duration(milliseconds: 300 + (index * 50)),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - value)),
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
                                          Navigator.of(context)
                                              .push(
                                            PageRouteBuilder<void>(
                                              pageBuilder: (context, animation, secondaryAnimation) =>
                                                  TicketDetailScreen(
                                                    ticketId: ticket.id.toString(),
                                                  ),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                );
                                              },
                                            ),
                                          )
                                              .then((_) {
                                            if (userEmail != null) {
                                              _hasLoaded = false;
                                              _loadTickets(force: true);
                                            }
                                          });
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                                              color: _getStatusColor(ticket.status)
                                                                  .withValues(alpha: 0.15),
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
                                                          Icon(
                                                            Icons.tag,
                                                            size: 14,
                                                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            ticket.prettyId ?? '#${ticket.id}',
                                                            style: theme.textTheme.bodySmall?.copyWith(
                                                              color: theme.colorScheme.primary,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (ticket.description.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  ticket.description.length > 120
                                                      ? '${ticket.description.substring(0, 120)}...'
                                                      : ticket.description,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time_rounded,
                                                  size: 16,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  _formatTimestamp(ticket.createdAt),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Icon(
                                                  Icons.chevron_right_rounded,
                                                  size: 20,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
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
                            ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
      case 'closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
