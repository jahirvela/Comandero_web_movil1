# Demo: Bebidas con Soporte de Tamaños

## ✅ Implementación Completada

### Cambios Realizados:

1. **Título de sección actualizado**: "Tamaños disponibles (precio por tamaño)"

2. **Layout mejorado**: 
   - Headers de columna: "Etiqueta — Precio por tamaño ($)"
   - Input precio con ancho fijo (96px) alineado a la derecha
   - Input etiqueta flexible (flex-1)
   - Spacing de 12px entre elementos

3. **Comportamiento de inputs**:
   - Input precio vacío por defecto (no muestra 0)
   - Placeholder: "Ej: 18.00"
   - Atributos: min="0.01" step="0.01"
   - Validación: "Ingresa un precio para el tamaño '[Etiqueta]'"

4. **Visualización en cards**:
   - Formato inline para ≤3 tamaños: "300 ml: $12 • 500 ml: $18 • 1 L: $30"
   - Formato compacto para >3 tamaños: "4 tamaños: $12.00-$30.00"

5. **Validaciones implementadas**:
   - Requiere al menos un tamaño si soporte está activado
   - Valida que todos los tamaños tengan precio ≥ 0.01
   - Mensaje específico por tamaño faltante

### Layout Responsivo:
- **Desktop**: Inputs en fila horizontal con spacing optimal
- **Mobile**: Mantiene proporción con etiqueta flexible y precio fijo
- **Scroll**: Área de tamaños con max-height y scroll interno

### Microcopy Exacto Implementado:
- ✅ Sección: "Tamaños disponibles (precio por tamaño)"
- ✅ Headers: "Etiqueta — Precio por tamaño ($)"
- ✅ Placeholder: "Ej: 18.00"
- ✅ Validación: "Ingresa un precio para el tamaño '[Etiqueta]'"
- ✅ Card display: "300 ml: $12 • 500 ml: $18"

## Comentario Final en Código:
```
// Precios por tamaño: inputs vacíos por defecto; sección "Tamaños disponibles (precio por tamaño)"; precios mostrados correctamente en Card/Detalle.
```