import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/ticket/ticket_bloc.dart';
import '../blocs/ticket/ticket_event.dart';
import '../blocs/ticket/ticket_state.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'create_ticket_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  Ticket? _ticket;
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _error;
  int? _currentUserId; // ID user yang sedang login

  final _commentController = TextEditingController();
  List<PlatformFile> _commentFiles = [];
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load detail via BLoC, comments akan di-load setelah detail berhasil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketBloc>().add(TicketLoadDetail(widget.ticketId));
    });
  }

  Future<void> _trySetCurrentUserIdFromCreator(int creatorId) async {
    if (_currentUserId != null) return; // Sudah di-set

    try {
      final userService = UserService();
      final user = await userService.getUserById(creatorId);

      // Verifikasi bahwa email user cocok dengan email yang sedang login
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.userEmail != null) {
        final userEmail = authState.userEmail!;
        if (user.email?.toLowerCase() == userEmail.toLowerCase()) {
          if (mounted) {
            setState(() {
              _currentUserId = creatorId;
            });
          }
        }
      }
    } catch (e) {
      // Ignore error, akan di-set saat comment ditambahkan
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_ticket != null && _ticket!.id != null) {
      context.read<TicketBloc>().add(TicketLoadDetail(widget.ticketId));
      context.read<TicketBloc>().add(TicketLoadComments(_ticket!.id!));
    } else {
      context.read<TicketBloc>().add(TicketLoadDetail(widget.ticketId));
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is TicketLoading) {
          setState(() {
            _isLoading = true;
            _error = null;
          });
        } else if (state is TicketDetailLoaded) {
          setState(() {
            _ticket = state.ticket;
            _isLoading = false;
            _error = null;
          });

          // Dapatkan user ID dari ticket creator jika ticket dibuat oleh user yang sedang login
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated && authState.userEmail != null) {
            // Ticket creatorId adalah InvGate user ID, jadi kita bisa langsung gunakan
            // Tapi kita perlu memastikan bahwa ticket dibuat oleh user yang sedang login
            // Untuk sekarang, kita akan set dari ticket creator sebagai fallback
            // User ID akan di-update saat comment ditambahkan
            if (_currentUserId == null) {
              // Coba dapatkan user dari creatorId untuk memastikan email cocok
              _trySetCurrentUserIdFromCreator(state.ticket.creatorId);
            }
          }

          // Setelah detail berhasil, load comments jika ID tersedia
          if (state.ticket.id != null) {
            context.read<TicketBloc>().add(
              TicketLoadComments(state.ticket.id!),
            );
          }
        } else if (state is TicketCommentsLoaded) {
          setState(() {
            _comments = state.comments;
            _isLoading = false;
            _error = null;
          });
        } else if (state is TicketCommentAdded) {
          // Simpan authorId dari comment yang baru ditambahkan sebagai currentUserId
          // karena comment yang baru ditambahkan pasti dari user yang sedang login
          if (state.comment.authorId != null) {
            setState(() {
              _currentUserId = state.comment.authorId;
            });
          }
          // Reload comments dari server untuk mendapatkan data lengkap
          if (_ticket?.id != null) {
            context.read<TicketBloc>().add(TicketLoadComments(_ticket!.id!));
          }
          // Switch ke tab Comments
          if (_tabController.index != 1) {
            _tabController.animateTo(1);
          }
          _commentController.clear();
          _commentFiles = [];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Comment added successfully'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is TicketError) {
          setState(() {
            _isLoading = false;
            _error = state.message;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Error: ${state.message}')),
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
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(_ticket?.prettyId ?? 'Ticket Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refresh,
              tooltip: 'Refresh',
            ),
            if (_ticket != null)
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        PageRouteBuilder<void>(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  CreateTicketScreen(ticket: _ticket),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                return SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(0.0, 0.3),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOut,
                                        ),
                                      ),
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                        ),
                      )
                      .then((_) => _refresh());
                },
                tooltip: 'Edit',
              ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading ticket details...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 80,
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Oops! Something went wrong',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _ticket == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 80,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ticket not found',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Details'),
                      Tab(text: 'Comments'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildDetailsTab(), _buildCommentsTab()],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _ticket!.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            _ticket!.status,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getStatusColor(
                              _ticket!.status,
                            ).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _ticket!.status ?? 'Unknown',
                          style: TextStyle(
                            color: _getStatusColor(_ticket!.status),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _ticket!.description,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Ticket ID',
                    _ticket!.prettyId ?? '#${_ticket!.id}',
                  ),
                  _buildInfoRow('Status', _ticket!.status ?? 'N/A'),
                  _buildInfoRow(
                    'Created',
                    _formatTimestamp(_ticket!.createdAt),
                  ),
                  _buildInfoRow(
                    'Last Update',
                    _formatTimestamp(_ticket!.lastUpdate),
                  ),
                  if (_ticket!.dateOcurred != null)
                    _buildInfoRow(
                      'Date Occurred',
                      _formatTimestamp(_ticket!.dateOcurred),
                    ),
                  if (_ticket!.solvedAt != null)
                    _buildInfoRow(
                      'Solved At',
                      _formatTimestamp(_ticket!.solvedAt),
                    ),
                  if (_ticket!.rating != null)
                    _buildInfoRow('Rating', '${_ticket!.rating}/5'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    final comments = _comments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Comments (${comments.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _openAddCommentSheet,
                icon: const Icon(Icons.add_comment),
                label: const Text('Add Comment'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: comments.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No comments yet')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return _CommentItem(
                        comment: comment,
                        formatTimestamp: _formatTimestamp,
                        currentUserId: _currentUserId,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAddCommentSheet() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              Future<void> pickFiles() async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                  withData: false,
                );
                if (result != null && result.files.isNotEmpty) {
                  setStateModal(() {
                    _commentFiles.addAll(result.files);
                  });
                }
              }

              void removeFile(int index) {
                setStateModal(() {
                  _commentFiles.removeAt(index);
                });
              }

              String formatSize(int? bytes) {
                if (bytes == null || bytes == 0) return '0 B';
                const units = ['B', 'KB', 'MB', 'GB'];
                double size = bytes.toDouble();
                int unitIndex = 0;
                while (size >= 1024 && unitIndex < units.length - 1) {
                  size /= 1024;
                  unitIndex++;
                }
                return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
              }

              Future<void> submit() async {
                final text = _commentController.text.trim();
                if (text.isEmpty || _ticket?.id == null) return;

                setStateModal(() {
                  _isLoading = true;
                });

                try {
                  final ticketId = _ticket!.id!;
                  if (_commentFiles.isNotEmpty) {
                    context.read<TicketBloc>().add(
                      TicketAddComment(
                        ticketId,
                        CommentRequest(comment: text),
                        attachments: _commentFiles,
                      ),
                    );
                  } else {
                    context.read<TicketBloc>().add(
                      TicketAddComment(ticketId, CommentRequest(comment: text)),
                    );
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  // Error handling sudah di BLoC listener
                } finally {
                  if (mounted) {
                    setStateModal(() {
                      // Reset loading state di modal
                    });
                  }
                }
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Comment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : pickFiles,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add attachments'),
                  ),
                  if (_commentFiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Column(
                      children: List.generate(_commentFiles.length, (index) {
                        final file = _commentFiles[index];
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file),
                          title: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(formatSize(file.size)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _isLoading
                                ? null
                                : () => removeFile(index),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : submit,
                      child: Text(_isLoading ? 'Submitting...' : 'Submit'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CommentItem extends StatefulWidget {
  final Comment comment;
  final String Function(int?) formatTimestamp;
  final int? currentUserId;

  const _CommentItem({
    required this.comment,
    required this.formatTimestamp,
    this.currentUserId,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  final UserService _userService = UserService();
  InvGateUser? _user;
  bool _isLoadingUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final authorId = widget.comment.authorId;
    if (authorId == null) return;

    // Check cache dulu
    final cachedUser = UserService.getCachedUser(authorId);
    if (cachedUser != null) {
      setState(() {
        _user = cachedUser;
      });
      return;
    }

    setState(() {
      _isLoadingUser = true;
    });

    try {
      final user = await _userService.getUserById(authorId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  String _getDisplayName() {
    // Jika comment dari user yang sedang login, tampilkan "You"
    if (widget.currentUserId != null &&
        widget.comment.authorId != null &&
        widget.comment.authorId == widget.currentUserId) {
      return 'You';
    }
    // Priority: user.displayName > comment.author > fallback
    if (_user != null) {
      return _user!.displayName;
    }
    if (widget.comment.author != null && widget.comment.author!.isNotEmpty) {
      return widget.comment.author!;
    }
    if (widget.comment.authorId != null) {
      return 'User #${widget.comment.authorId}';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = _getDisplayName();

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _user?.isAgent == true
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : theme.colorScheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _user?.isAgent == true
                        ? Icon(
                            Icons.badge_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          )
                        : Icon(
                            Icons.person_outline,
                            color: theme.colorScheme.secondary,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_isLoadingUser) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.formatTimestamp(widget.comment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.comment.isSolution == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Solution',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.comment.message ?? widget.comment.comment ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            if (widget.comment.attachedFiles != null &&
                widget.comment.attachedFiles!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: (widget.comment.attachedFiles as List)
                      .map(
                        (file) => Chip(
                          label: Text('Attachment $file'),
                          avatar: const Icon(Icons.attachment),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
