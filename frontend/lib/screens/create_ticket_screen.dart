import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/ticket/ticket_bloc.dart';
import '../blocs/ticket/ticket_event.dart';
import '../blocs/ticket/ticket_state.dart';
import '../models/ticket_model.dart';
import '../widgets/loading_button.dart';
import '../utils/error_handler.dart';
import '../utils/validators.dart';
import '../constants/app_constants.dart';

class CreateTicketScreen extends StatefulWidget {
  final Ticket? ticket;

  const CreateTicketScreen({super.key, this.ticket});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<PlatformFile> _selectedFiles = [];

  int? _selectedSourceId;
  int? _selectedCategoryId;
  int? _selectedTypeId;
  int? _selectedPriorityId;
  int? _selectedCustomerId;
  int? _selectedCreatorId;

  DateTime? _selectedDate;

  // Cache meta and categories to prevent loss when state changes
  TicketMeta? _cachedMeta;
  List<Category> _cachedCategories = [];

  @override
  void initState() {
    super.initState();
    // Set source_id default ke 2 untuk new ticket
    if (widget.ticket == null) {
      _selectedSourceId = AppConstants.defaultSourceId;
      _selectedCreatorId = AppConstants.defaultCreatorId;
      _selectedCustomerId = AppConstants.defaultCustomerId;
    }

    // Load meta
    context.read<TicketBloc>().add(const TicketLoadMeta());

    if (widget.ticket != null) {
      _loadTicketData();
    }
  }

  void _loadTicketData() {
    final ticket = widget.ticket!;
    _titleController.text = ticket.title;
    _descriptionController.text = ticket.description;
    _selectedSourceId = ticket.sourceId;
    _selectedCategoryId = ticket.categoryId;
    _selectedTypeId = ticket.typeId;
    _selectedPriorityId = ticket.priorityId;
    _selectedCustomerId = ticket.customerId;
    _selectedCreatorId = ticket.creatorId;

    if (ticket.dateOcurred != null) {
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(
        ticket.dateOcurred! * 1000,
      );
    }
  }

  void _saveTicket() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // source_id sudah di-set default ke 2, tidak perlu dicek
    if (_selectedCategoryId == null ||
        _selectedTypeId == null ||
        _selectedPriorityId == null ||
        _selectedCustomerId == null ||
        _selectedCreatorId == null) {
      ErrorHandler.showError(context, 'Please fill in all required fields');
      return;
    }

    if (widget.ticket != null) {
      // Update existing ticket
      final updateRequest = TicketUpdateRequest(
        sourceId: _selectedSourceId,
        categoryId: _selectedCategoryId,
        typeId: _selectedTypeId,
        priorityId: _selectedPriorityId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateOcurred: _selectedDate != null
            ? _selectedDate!.millisecondsSinceEpoch ~/ 1000
            : null,
      );

      context.read<TicketBloc>().add(
        TicketUpdate(widget.ticket!.id!, updateRequest),
      );
    } else {
      // Create new ticket
      final request = TicketRequest(
        sourceId: AppConstants.defaultSourceId,
        creatorId: _selectedCreatorId!,
        customerId: _selectedCustomerId!,
        categoryId: _selectedCategoryId!,
        typeId: _selectedTypeId!,
        priorityId: _selectedPriorityId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dateOcurred: _selectedDate != null
            ? _selectedDate!.millisecondsSinceEpoch ~/ 1000
            : null,
      );

      context.read<TicketBloc>().add(
        TicketCreate(
          request,
          attachments: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  String _formatFileSize(int? bytes) {
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

  Widget _buildAttachmentsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attachments',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(optional)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _pickAttachments(),
          icon: const Icon(Icons.attach_file, size: 18),
          label: const Text('Choose files'),
        ),
        if (_selectedFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...List.generate(_selectedFiles.length, (index) {
            final file = _selectedFiles[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          _formatFileSize(file.size),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _removeAttachment(index),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            '${_selectedFiles.length} file(s) selected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<TicketBloc, TicketState>(
      listener: (context, state) {
        if (state is TicketError) {
          ErrorHandler.showError(context, state.message);
        } else if (state is TicketCreated || state is TicketUpdated) {
          // Success - pop screen
          Navigator.of(context).pop(true);
        }
      },
      child: BlocConsumer<TicketBloc, TicketState>(
        listener: (context, state) {
          if (state is TicketMetaLoaded) {
            setState(() {
              _cachedMeta = state.meta;
              _cachedCategories = state.categories;
            });

            // Set defaults if creating new ticket and meta just loaded
            if (widget.ticket == null && _selectedTypeId == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_cachedMeta != null) {
                  if (_cachedMeta!.types.isNotEmpty) {
                    final firstType =
                        _cachedMeta!.types[0] as Map<String, dynamic>;
                    setState(() {
                      _selectedTypeId = firstType['id'] as int?;
                    });
                  }
                  if (_cachedMeta!.priorities.isNotEmpty) {
                    final firstPriority =
                        _cachedMeta!.priorities[0] as Map<String, dynamic>;
                    setState(() {
                      _selectedPriorityId = firstPriority['id'] as int?;
                    });
                  }
                  if (_cachedCategories.isNotEmpty) {
                    setState(() {
                      _selectedCategoryId = _cachedCategories[0].id;
                    });
                  }
                }
              });
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is TicketLoading;
          final isLoadingMeta = state is TicketLoading && _cachedMeta == null;

          // Use cached meta and categories, or get from state if available
          final meta =
              _cachedMeta ?? (state is TicketMetaLoaded ? state.meta : null);
          final List<Category> categories = _cachedCategories.isNotEmpty
              ? _cachedCategories
              : (state is TicketMetaLoaded ? state.categories : <Category>[]);

          return Scaffold(
            appBar: AppBar(
              elevation: 0,
              title: Text(
                widget.ticket != null ? 'Edit Ticket' : 'Create New Ticket',
              ),
            ),
            body: isLoadingMeta
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Page header with icon
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      widget.ticket != null
                                          ? Icons.edit_rounded
                                          : Icons.add_circle_outline_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.ticket != null
                                              ? 'Edit Ticket'
                                              : 'Create New Ticket',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.5,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.ticket != null
                                              ? 'Update ticket information'
                                              : 'Fill in the details below',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Title field
                            TextFormField(
                              controller: _titleController,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Title',
                                hintText: 'Enter ticket title',
                                prefixIcon: Icon(
                                  Icons.title_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                filled: true,
                                fillColor: theme
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              validator: (value) => Validators.required(
                                value,
                                fieldName: 'title',
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Description field
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 5,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Enter ticket description',
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 60),
                                  child: Icon(
                                    Icons.description_outlined,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                filled: true,
                                fillColor: theme
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              validator: (value) => Validators.required(
                                value,
                                fieldName: 'description',
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (meta != null) ...[
                              DropdownButtonFormField<int>(
                                initialValue: _selectedCategoryId,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  hintText: 'Select a category',
                                ),
                                items: categories.isEmpty
                                    ? [
                                        const DropdownMenuItem<int>(
                                          value: null,
                                          enabled: false,
                                          child: Text(
                                            'No categories available',
                                          ),
                                        ),
                                      ]
                                    : categories
                                          .map(
                                            (category) => DropdownMenuItem<int>(
                                              value: category.id,
                                              child: Text(category.name),
                                            ),
                                          )
                                          .toList(),
                                onChanged: categories.isEmpty
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedCategoryId = value;
                                        });
                                      },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a category';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedTypeId,
                                decoration: const InputDecoration(
                                  labelText: 'Type *',
                                  hintText: 'Select a type',
                                ),
                                items: meta.types.map((type) {
                                  final typeMap = type as Map<String, dynamic>;
                                  return DropdownMenuItem<int>(
                                    value: typeMap['id'] as int?,
                                    child: Text(
                                      typeMap['name']?.toString() ?? 'Unknown',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedTypeId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a type';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              DropdownButtonFormField<int>(
                                initialValue: _selectedPriorityId,
                                decoration: const InputDecoration(
                                  labelText: 'Priority *',
                                  hintText: 'Select a priority',
                                ),
                                items: meta.priorities.map((priority) {
                                  final priorityMap =
                                      priority as Map<String, dynamic>;
                                  return DropdownMenuItem<int>(
                                    value: priorityMap['id'] as int?,
                                    child: Text(
                                      priorityMap['name']?.toString() ??
                                          'Unknown',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPriorityId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select a priority';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date Occurred *',
                                    hintText:
                                        'Select the date when the incident occurred',
                                    suffixIcon: Icon(Icons.calendar_today),
                                  ),
                                  child: Text(
                                    _selectedDate != null
                                        ? DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(_selectedDate!)
                                        : 'Select date',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Attachments section
                              _buildAttachmentsSection(),
                              const SizedBox(height: 32),
                            ],
                            // Form actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          Navigator.of(context).pop();
                                        },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 16),
                                LoadingButton(
                                  onPressed: _saveTicket,
                                  isLoading: isLoading,
                                  text: widget.ticket != null
                                      ? 'Update'
                                      : 'Create Ticket',
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
    );
  }
}
