import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/mesero_controller.dart';
import '../../models/table_model.dart';
import '../../utils/app_colors.dart';

/// Vista para que el mesero pueda agregar, editar o renombrar mesas (sin eliminar).
class MeseroTablesManagementView extends StatelessWidget {
  const MeseroTablesManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Mesas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<MeseroController>(
        builder: (context, controller, _) {
          final tables = controller.tables;
          if (tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_restaurant, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No hay mesas. Agrega una con el botón +.',
                    style: TextStyle(fontSize: isTablet ? 18 : 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: 8,
                  ),
                  title: Text(
                    table.displayLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    '${table.section ?? "Sin área"} • ${table.seats} asientos',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => _showEditTableModal(
                      context,
                      table,
                      controller,
                      isTablet,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final controller = context.read<MeseroController>();
          _showAddTableModal(context, controller, isTablet);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Agregar mesa'),
      ),
    );
  }

  void _showAddTableModal(
    BuildContext context,
    MeseroController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameOrNumberController = TextEditingController();
    final seatsController = TextEditingController();
    final availableAreas = controller.tableAreas;
    String selectedSection = availableAreas.isNotEmpty
        ? availableAreas.first
        : 'Área Principal';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Agregar Mesa',
            style: TextStyle(fontSize: isTablet ? 20 : 18),
          ),
          contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
          content: SizedBox(
            width: isTablet ? 450 : double.infinity,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameOrNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o número de Mesa *',
                        hintText: 'Ej: 1, Terraza, VIP 1',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obligatorio';
                        }
                        if (controller.tableCodigoExists(value.trim())) {
                          return 'Ya existe una mesa con ese nombre o número';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: seatsController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Asientos *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final seats = int.tryParse(value);
                        if (seats == null || seats <= 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: const InputDecoration(
                        labelText: 'Área *',
                        hintText: 'Área de la mesa',
                        border: OutlineInputBorder(),
                      ),
                      items: availableAreas
                          .map(
                            (area) => DropdownMenuItem(
                              value: area,
                              child: Text(area),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedSection = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    final codigo = nameOrNumberController.text.trim();
                    final newTable = TableModel(
                      id: 0,
                      codigo: codigo,
                      number: int.tryParse(codigo) ?? 0,
                      status: TableStatus.libre,
                      seats: int.parse(seatsController.text),
                      section: selectedSection,
                      position: TablePosition(x: 1, y: 1),
                    );
                    await controller.addTable(newTable);
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mesa agregada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al agregar mesa: ${_extractErrorMessage(e)}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTableModal(
    BuildContext context,
    TableModel table,
    MeseroController controller,
    bool isTablet,
  ) {
    final formKey = GlobalKey<FormState>();
    final nameOrNumberController = TextEditingController(text: table.codigo);
    final seatsController = TextEditingController(text: table.seats.toString());
    final availableAreas = controller.tableAreas;
    String selectedSection = table.section ??
        (availableAreas.isNotEmpty ? availableAreas.first : 'Área Principal');
    if (!availableAreas.contains(selectedSection)) {
      selectedSection =
          availableAreas.isNotEmpty ? availableAreas.first : 'Área Principal';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Editar Mesa',
            style: TextStyle(fontSize: isTablet ? 20 : 18),
          ),
          contentPadding: EdgeInsets.all(isTablet ? 24 : 16),
          content: SizedBox(
            width: isTablet ? 450 : double.infinity,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameOrNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre o número de Mesa *',
                        hintText: 'Ej: 1, Terraza, VIP 1',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Campo obligatorio';
                        }
                        if (controller.tableCodigoExists(value.trim(),
                            excludeTableId: table.id)) {
                          return 'Ya existe una mesa con ese nombre o número';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: seatsController,
                      decoration: const InputDecoration(
                        labelText: 'Asientos *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obligatorio';
                        }
                        final seats = int.tryParse(value);
                        if (seats == null || seats <= 0) {
                          return 'Debe ser un número válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedSection,
                      decoration: const InputDecoration(
                        labelText: 'Área *',
                        hintText: 'Cambiar área de la mesa',
                        border: OutlineInputBorder(),
                      ),
                      items: availableAreas
                          .map(
                            (area) => DropdownMenuItem(
                              value: area,
                              child: Text(area),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedSection = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    final codigo = nameOrNumberController.text.trim();
                    final updatedTable = table.copyWith(
                      codigo: codigo,
                      number: int.tryParse(codigo) ?? 0,
                      seats: int.parse(seatsController.text),
                      section: selectedSection,
                    );
                    await controller.updateTable(updatedTable);
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mesa actualizada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) Navigator.of(context).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Error al actualizar mesa: ${_extractErrorMessage(e)}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  static String _extractErrorMessage(dynamic e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.replaceFirst('Exception: ', '');
    return s;
  }
}
