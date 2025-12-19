const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:3000/api';

// Obtener token del localStorage
const getToken = () => {
  return localStorage.getItem('token') || '';
};

// Función genérica para hacer peticiones
async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();
  
  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { Authorization: `Bearer ${token}` }),
      ...options.headers,
    },
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({ message: 'Error desconocido' }));
    throw new Error(`Error (${response.status}): ${errorData.message || errorData.error || 'Error desconocido'}`);
  }

  const data = await response.json();
  return data.data || data;
}

// API de Inventario
export const inventoryAPI = {
  // Obtener todos los items
  getItems: () => apiRequest<any[]>('/inventario/items'),
  
  // Obtener un item por ID
  getItem: (id: number) => apiRequest<any>(`/inventario/items/${id}`),
  
  // Crear un nuevo item
  createItem: (item: {
    nombre: string;
    categoria: string;
    unidad: string;
    cantidadActual: number;
    stockMinimo: number;
    costoUnitario?: number | null;
    activo?: boolean;
  }) => apiRequest<any>('/inventario/items', {
    method: 'POST',
    body: JSON.stringify(item),
  }),
  
  // Actualizar un item
  updateItem: (id: number, item: {
    nombre?: string;
    categoria?: string;
    unidad?: string;
    cantidadActual?: number;
    stockMinimo?: number;
    costoUnitario?: number | null;
    activo?: boolean;
  }) => apiRequest<any>(`/inventario/items/${id}`, {
    method: 'PUT',
    body: JSON.stringify(item),
  }),
  
  // Eliminar un item
  deleteItem: (id: number) => apiRequest<void>(`/inventario/items/${id}`, {
    method: 'DELETE',
  }),
  
  // Obtener categorías únicas
  getCategories: () => apiRequest<string[]>('/inventario/categorias'),
};

// API de Tickets
export const ticketsAPI = {
  // Obtener todos los tickets
  getTickets: () => apiRequest<any[]>('/tickets'),
  
  // Imprimir un ticket
  printTicket: (data: {
    ordenId: number;
    ordenIds?: number[];
    incluirCodigoBarras?: boolean;
  }) => apiRequest<any>('/tickets/imprimir', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
};

