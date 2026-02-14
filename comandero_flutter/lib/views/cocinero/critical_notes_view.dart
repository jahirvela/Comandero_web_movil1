import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/cocinero_controller.dart';
import '../../utils/app_colors.dart';

class CriticalNotesView extends StatefulWidget {
  const CriticalNotesView({super.key});

  @override
  State<CriticalNotesView> createState() => _CriticalNotesViewState();
}

class _CriticalNotesViewState extends State<CriticalNotesView> {
  String selectedFilter = 'Todas';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> filters = [
    'Todas',
    'Pendientes',
    'En Proceso',
    'Completadas',
    'Urgentes',
  ];

  // Datos mock de notas críticas
  final List<Map<String, dynamic>> criticalNotes = [
    {
      'id': 'CN-001',
      'title': 'Falta Barbacoa de Res',
      'description':
          'Se agotó la barbacoa de res. Necesitamos preparar más para el servicio de la tarde.',
      'priority': 'Urgente',
      'status': 'Pendiente',
      'createdBy': 'Juan Martínez',
      'createdAt': '14:30',
      'assignedTo': 'Cocina Principal',
      'dueTime': '15:00',
      'color': AppColors.error,
    },
    {
      'id': 'CN-002',
      'title': 'Tortillas Agotadas',
      'description':
          'Se terminaron las tortillas de maíz. Solicitar más al proveedor.',
      'priority': 'Alta',
      'status': 'En Proceso',
      'createdBy': 'María García',
      'createdAt': '14:15',
      'assignedTo': 'Estación Tacos',
      'dueTime': '14:45',
      'color': AppColors.warning,
    },
    {
      'id': 'CN-003',
      'title': 'Consomé Listo',
      'description': 'El consomé de res está listo y puede servirse.',
      'priority': 'Normal',
      'status': 'Completada',
      'createdBy': 'Carlos López',
      'createdAt': '13:45',
      'assignedTo': 'Estación Consomes',
      'dueTime': '14:00',
      'color': AppColors.success,
    },
    {
      'id': 'CN-004',
      'title': 'Falta Cilantro',
      'description':
          'Se necesita más cilantro para los tacos. Verificar con el proveedor.',
      'priority': 'Alta',
      'status': 'Pendiente',
      'createdBy': 'Ana Martínez',
      'createdAt': '14:00',
      'assignedTo': 'Estación Tacos',
      'dueTime': '14:30',
      'color': AppColors.warning,
    },
    {
      'id': 'CN-005',
      'title': 'Horno Calentado',
      'description': 'El horno está listo para cocinar la barbacoa.',
      'priority': 'Normal',
      'status': 'Completada',
      'createdBy': 'Roberto Silva',
      'createdAt': '13:30',
      'assignedTo': 'Cocina Principal',
      'dueTime': '14:00',
      'color': AppColors.success,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredNotes {
    List<Map<String, dynamic>> notes = criticalNotes;

    // Filtrar por estado
    if (selectedFilter != 'Todas') {
      notes = notes.where((note) => note['status'] == selectedFilter).toList();
    }

    // Filtrar por búsqueda solo cuando hay texto
    final q = searchQuery.trim();
    if (q.isNotEmpty) {
      notes = notes.where((note) {
        return note['title'].toLowerCase().contains(q.toLowerCase()) ||
            note['description'].toLowerCase().contains(q.toLowerCase()) ||
            note['createdBy'].toLowerCase().contains(q.toLowerCase());
      }).toList();
    }

    return notes;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Header
              _buildHeader(context, isTablet),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra de búsqueda
                      _buildSearchBar(isTablet),
                      const SizedBox(height: 16),

                      // Filtros
                      _buildFilters(isTablet),
                      const SizedBox(height: 16),

                      // Estadísticas rápidas
                      _buildQuickStats(isTablet),
                      const SizedBox(height: 24),

                      // Lista de notas críticas
                      _buildNotesList(isTablet),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Botón flotante para agregar nota
          floatingActionButton: _buildAddNoteButton(isTablet),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Row(
            children: [
              // Botón de regreso
              IconButton(
                onPressed: () {
                  context.read<CocineroController>().setCurrentView('main');
                },
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              const SizedBox(width: 16),

              // Título
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas Críticas',
                      style: TextStyle(
                        fontSize: isTablet ? 24.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Juan Martínez • Cocinero',
                      style: TextStyle(
                        fontSize: isTablet ? 16.0 : 14.0,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de configuración
              IconButton(
                onPressed: () {
                  _showSettingsDialog(context);
                },
                icon: const Icon(Icons.settings, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: "Buscar nota crítica",
          helperText: "Los resultados se filtran al escribir",
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: isTablet ? 16.0 : 14.0,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: isTablet ? 24.0 : 20.0,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20.0 : 16.0,
            vertical: isTablet ? 16.0 : 12.0,
          ),
        ),
        style: TextStyle(
          fontSize: isTablet ? 16.0 : 14.0,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildFilters(bool isTablet) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filter,
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              backgroundColor: AppColors.secondary,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStats(bool isTablet) {
    final pendingCount = criticalNotes
        .where((note) => note['status'] == 'Pendiente')
        .length;
    final inProgressCount = criticalNotes
        .where((note) => note['status'] == 'En Proceso')
        .length;
    final completedCount = criticalNotes
        .where((note) => note['status'] == 'Completada')
        .length;
    final urgentCount = criticalNotes
        .where((note) => note['priority'] == 'Urgente')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pendientes',
            pendingCount,
            AppColors.warning,
            isTablet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'En Proceso',
            inProgressCount,
            AppColors.info,
            isTablet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Completadas',
            completedCount,
            AppColors.success,
            isTablet,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Urgentes',
            urgentCount,
            AppColors.error,
            isTablet,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color, bool isTablet) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 12.0 : 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: isTablet ? 20.0 : 18.0,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: isTablet ? 10.0 : 8.0, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesList(bool isTablet) {
    final notes = filteredNotes;

    if (notes.isEmpty) {
      return _buildEmptyState(isTablet, sourceEmpty: criticalNotes.isEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notas Críticas (${notes.length})',
          style: TextStyle(
            fontSize: isTablet ? 20.0 : 18.0,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...notes.map((note) => _buildNoteCard(note, isTablet)),
      ],
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, bool isTablet) {
    final statusColor = note['color'] as Color;
    final priorityIcon = _getPriorityIcon(note['priority']);
    final statusIcon = _getStatusIcon(note['status']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: statusColor.withValues(alpha: 0.05),
        ),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la nota
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              priorityIcon,
                              style: TextStyle(
                                fontSize: isTablet ? 16.0 : 14.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                note['title'],
                                style: TextStyle(
                                  fontSize: isTablet ? 18.0 : 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note['id'],
                          style: TextStyle(
                            fontSize: isTablet ? 14.0 : 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              statusIcon,
                              style: TextStyle(
                                fontSize: isTablet ? 12.0 : 10.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              note['status'],
                              style: TextStyle(
                                fontSize: isTablet ? 12.0 : 10.0,
                                fontWeight: FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          note['priority'],
                          style: TextStyle(
                            fontSize: isTablet ? 10.0 : 8.0,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Descripción
              Text(
                note['description'],
                style: TextStyle(
                  fontSize: isTablet ? 14.0 : 12.0,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Información adicional
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Creado por: ${note['createdBy']}',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${note['createdAt']}',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.assignment_ind,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Asignado a: ${note['assignedTo']}',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: isTablet ? 16.0 : 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Vence: ${note['dueTime']}',
                    style: TextStyle(
                      fontSize: isTablet ? 12.0 : 10.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Botones de acción
              _buildActionButtons(note, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> note, bool isTablet) {
    return Row(
      children: [
        if (note['status'] == 'Pendiente') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _updateNoteStatus(note['id'], 'En Proceso');
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(
                'Comenzar',
                style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (note['status'] == 'En Proceso') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _updateNoteStatus(note['id'], 'Completada');
              },
              icon: const Icon(Icons.check),
              label: Text(
                'Completar',
                style: TextStyle(fontSize: isTablet ? 14.0 : 12.0),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        OutlinedButton.icon(
          onPressed: () {
            _showNoteDetails(note);
          },
          icon: const Icon(Icons.visibility),
          label: Text(
            'Ver Detalles',
            style: TextStyle(fontSize: isTablet ? 12.0 : 10.0),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isTablet, {bool sourceEmpty = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 60.0 : 40.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.note_add,
            size: isTablet ? 64.0 : 48.0,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            sourceEmpty
                ? 'No hay notas críticas'
                : 'Sin coincidencias para la búsqueda',
            style: TextStyle(
              fontSize: isTablet ? 18.0 : 16.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            sourceEmpty
                ? 'Las notas críticas aparecerán aquí cuando se creen'
                : 'Intenta cambiar los filtros o la búsqueda',
            style: TextStyle(
              fontSize: isTablet ? 14.0 : 12.0,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddNoteButton(bool isTablet) {
    return Container(
      margin: EdgeInsets.all(isTablet ? 24.0 : 16.0),
      child: FloatingActionButton.extended(
        onPressed: () {
          _showAddNoteDialog(context);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          isTablet ? 'Agregar Nota' : 'Agregar',
          style: TextStyle(fontSize: isTablet ? 16.0 : 14.0),
        ),
      ),
    );
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'Urgente':
        return '🚨';
      case 'Alta':
        return '⚠️';
      case 'Normal':
        return 'ℹ️';
      default:
        return '📝';
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'Pendiente':
        return '⏳';
      case 'En Proceso':
        return '🔄';
      case 'Completada':
        return '✅';
      default:
        return '📝';
    }
  }

  void _updateNoteStatus(String noteId, String newStatus) {
    setState(() {
      final noteIndex = criticalNotes.indexWhere(
        (note) => note['id'] == noteId,
      );
      if (noteIndex != -1) {
        criticalNotes[noteIndex]['status'] = newStatus;
        // Actualizar color según el nuevo estado
        switch (newStatus) {
          case 'Pendiente':
            criticalNotes[noteIndex]['color'] = AppColors.warning;
            break;
          case 'En Proceso':
            criticalNotes[noteIndex]['color'] = AppColors.info;
            break;
          case 'Completada':
            criticalNotes[noteIndex]['color'] = AppColors.success;
            break;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nota $noteId actualizada a $newStatus'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _showNoteDetails(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(note['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${note['id']}'),
              Text('Prioridad: ${note['priority']}'),
              Text('Estado: ${note['status']}'),
              Text('Creado por: ${note['createdBy']}'),
              Text('Asignado a: ${note['assignedTo']}'),
              Text('Creado: ${note['createdAt']}'),
              Text('Vence: ${note['dueTime']}'),
              const SizedBox(height: 16),
              const Text(
                'Descripción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(note['description']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Nota Crítica'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: 'Título')),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextField(decoration: InputDecoration(labelText: 'Asignado a')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implementar agregar nota
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nota crítica agregada'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Configuraciones de notas críticas'),
            Text('• Notificaciones automáticas'),
            Text('• Tiempo de vencimiento'),
            Text('• Asignación automática'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
