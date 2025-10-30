import { useState, useMemo } from "react";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Badge } from "../ui/badge";
import { Checkbox } from "../ui/checkbox";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../ui/table";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "../ui/dropdown-menu";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "../ui/alert-dialog";
import { Card, CardContent } from "../ui/card";
import { Skeleton } from "../ui/skeleton";
import { 
  Search, 
  Plus, 
  MoreVertical, 
  Edit, 
  Key, 
  Trash2, 
  CheckCircle, 
  XCircle,
  Users,
  AlertCircle,
  Loader2,
} from "lucide-react";
import { mockUsers, User, UserRole } from "./users/mockUsers";
import { RoleBadge } from "./users/RoleBadge";
import { NewUserModal } from "./users/NewUserModal";
import { EditUserModal } from "./users/EditUserModal";
import { ChangePasswordModal } from "./users/ChangePasswordModal";
import { toast } from "sonner";

type FilterStatus = 'all' | 'Activo' | 'Inactivo';
type FilterRole = 'all' | UserRole;

export function UserManagement() {
  const [users, setUsers] = useState<User[]>(mockUsers);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterStatus, setFilterStatus] = useState<FilterStatus>('all');
  const [filterRole, setFilterRole] = useState<FilterRole>('all');
  const [selectedUserIds, setSelectedUserIds] = useState<Set<string>>(new Set());
  const [currentPage, setCurrentPage] = useState(1);
  const [isLoading, setIsLoading] = useState(false);
  const [showNewUserModal, setShowNewUserModal] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [changingPasswordUser, setChangingPasswordUser] = useState<User | null>(null);
  const [bulkActionDialog, setBulkActionDialog] = useState<{
    open: boolean;
    action: 'activate' | 'deactivate' | 'delete' | null;
  }>({ open: false, action: null });
  
  const itemsPerPage = 10;
  
  // Filtered users
  const filteredUsers = useMemo(() => {
    return users.filter(user => {
      const matchesSearch = 
        user.username.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.fullName.toLowerCase().includes(searchQuery.toLowerCase());
      
      const matchesStatus = filterStatus === 'all' || user.status === filterStatus;
      
      const matchesRole = filterRole === 'all' || user.roles.includes(filterRole);
      
      return matchesSearch && matchesStatus && matchesRole;
    });
  }, [users, searchQuery, filterStatus, filterRole]);
  
  // Paginated users
  const paginatedUsers = useMemo(() => {
    const startIndex = (currentPage - 1) * itemsPerPage;
    return filteredUsers.slice(startIndex, startIndex + itemsPerPage);
  }, [filteredUsers, currentPage]);
  
  const totalPages = Math.ceil(filteredUsers.length / itemsPerPage);
  
  const allPageIdsSelected = paginatedUsers.length > 0 && 
    paginatedUsers.every(user => selectedUserIds.has(user.id));
  
  const somePageIdsSelected = paginatedUsers.some(user => selectedUserIds.has(user.id));
  
  // Handlers
  const toggleSelectAll = () => {
    if (allPageIdsSelected) {
      const newSelected = new Set(selectedUserIds);
      paginatedUsers.forEach(user => newSelected.delete(user.id));
      setSelectedUserIds(newSelected);
    } else {
      const newSelected = new Set(selectedUserIds);
      paginatedUsers.forEach(user => newSelected.add(user.id));
      setSelectedUserIds(newSelected);
    }
  };
  
  const toggleSelectUser = (userId: string) => {
    const newSelected = new Set(selectedUserIds);
    if (newSelected.has(userId)) {
      newSelected.delete(userId);
    } else {
      newSelected.add(userId);
    }
    setSelectedUserIds(newSelected);
  };
  
  const handleBulkAction = (action: 'activate' | 'deactivate' | 'delete') => {
    setBulkActionDialog({ open: true, action });
  };
  
  const executeBulkAction = () => {
    const action = bulkActionDialog.action;
    if (!action) return;
    
    setIsLoading(true);
    
    setTimeout(() => {
      const selectedIds = Array.from(selectedUserIds);
      
      if (action === 'delete') {
        setUsers(prev => prev.filter(user => !selectedUserIds.has(user.id)));
        toast.success('Usuarios eliminados', {
          description: `Se eliminaron ${selectedIds.length} usuario(s) del sistema`,
        });
      } else {
        const newStatus = action === 'activate' ? 'Activo' : 'Inactivo';
        setUsers(prev => prev.map(user => 
          selectedUserIds.has(user.id)
            ? { ...user, status: newStatus, updatedAt: new Date().toISOString() }
            : user
        ));
        toast.success(`Usuarios ${action === 'activate' ? 'activados' : 'desactivados'}`, {
          description: `Se actualizó el estado de ${selectedIds.length} usuario(s)`,
        });
      }
      
      setSelectedUserIds(new Set());
      setBulkActionDialog({ open: false, action: null });
      setIsLoading(false);
    }, 600);
  };
  
  const handleUserCreated = (newUser: User) => {
    setUsers(prev => [newUser, ...prev]);
  };
  
  const handleUserUpdated = (updatedUser: User) => {
    setUsers(prev => prev.map(user => 
      user.id === updatedUser.id ? updatedUser : user
    ));
  };
  
  const handleUserDeleted = (userId: string) => {
    setUsers(prev => prev.filter(user => user.id !== userId));
    setEditingUser(null);
  };
  
  const existingEmails = users.map(u => u.email.toLowerCase());
  const existingUsernames = users.map(u => u.username.toLowerCase());
  
  // Empty state
  if (!isLoading && users.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[500px] p-8">
        <Users className="w-16 h-16 text-muted-foreground mb-4" />
        <h3 className="text-xl mb-2">No hay usuarios registrados</h3>
        <p className="text-muted-foreground mb-6 text-center max-w-md">
          Comienza agregando el primer usuario al sistema
        </p>
        <Button onClick={() => setShowNewUserModal(true)}>
          <Plus className="w-4 h-4 mr-2" />
          Nuevo Usuario
        </Button>
      </div>
    );
  }
  
  return (
    <div className="space-y-6 p-6">
      {/* Header */}
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 className="text-3xl">Gestión de Usuarios</h1>
          <p className="text-muted-foreground">
            Administra los usuarios y sus permisos en el sistema
          </p>
        </div>
        <Button onClick={() => setShowNewUserModal(true)}>
          <Plus className="w-4 h-4 mr-2" />
          Nuevo Usuario
        </Button>
      </div>
      
      {/* Filters Bar */}
      <Card>
        <CardContent className="p-4">
          <div className="flex flex-col gap-4 lg:flex-row lg:items-center">
            {/* Search */}
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por nombre o usuario..."
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setCurrentPage(1);
                }}
                className="pl-9"
              />
            </div>
            
            {/* Role Filter */}
            <Select
              value={filterRole}
              onValueChange={(value) => {
                setFilterRole(value as FilterRole);
                setCurrentPage(1);
              }}
            >
              <SelectTrigger className="w-full lg:w-[180px]">
                <SelectValue placeholder="Filtrar por rol" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todos los roles</SelectItem>
                <SelectItem value="Mesero">Mesero</SelectItem>
                <SelectItem value="Cocinero">Cocinero</SelectItem>
                <SelectItem value="Capitán">Capitán</SelectItem>
                <SelectItem value="Cajero">Cajero</SelectItem>
                <SelectItem value="Administrador">Administrador</SelectItem>
              </SelectContent>
            </Select>
            
            {/* Status Filter */}
            <Select
              value={filterStatus}
              onValueChange={(value) => {
                setFilterStatus(value as FilterStatus);
                setCurrentPage(1);
              }}
            >
              <SelectTrigger className="w-full lg:w-[180px]">
                <SelectValue placeholder="Filtrar por estado" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Todos los estados</SelectItem>
                <SelectItem value="Activo">Activo</SelectItem>
                <SelectItem value="Inactivo">Inactivo</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>
      
      {/* Bulk Actions */}
      {selectedUserIds.size > 0 && (
        <Card className="border-blue-200 bg-blue-50">
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <p className="text-sm">
                {selectedUserIds.size} usuario(s) seleccionado(s)
              </p>
              <div className="flex gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction('activate')}
                >
                  <CheckCircle className="w-4 h-4 mr-2" />
                  Activar
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => handleBulkAction('deactivate')}
                >
                  <XCircle className="w-4 h-4 mr-2" />
                  Desactivar
                </Button>
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={() => handleBulkAction('delete')}
                >
                  <Trash2 className="w-4 h-4 mr-2" />
                  Eliminar
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
      
      {/* Table */}
      {isLoading ? (
        <Card>
          <CardContent className="p-6 space-y-4">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="flex gap-4 items-center">
                <Skeleton className="h-5 w-5" />
                <Skeleton className="h-5 flex-1" />
                <Skeleton className="h-5 w-32" />
                <Skeleton className="h-5 w-24" />
              </div>
            ))}
          </CardContent>
        </Card>
      ) : filteredUsers.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center justify-center p-12">
            <AlertCircle className="w-12 h-12 text-muted-foreground mb-4" />
            <h3 className="text-lg mb-2">No se encontraron resultados</h3>
            <p className="text-muted-foreground text-center">
              Intenta ajustar los filtros de búsqueda
            </p>
          </CardContent>
        </Card>
      ) : (
        <>
          {/* Desktop Table */}
          <Card className="hidden lg:block">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-12">
                    <Checkbox
                      checked={allPageIdsSelected}
                      indeterminate={somePageIdsSelected && !allPageIdsSelected}
                      onCheckedChange={toggleSelectAll}
                      aria-label="Seleccionar todos"
                    />
                  </TableHead>
                  <TableHead>Nombre completo</TableHead>
                  <TableHead>Usuario</TableHead>
                  <TableHead>Contraseña</TableHead>
                  <TableHead>Teléfono</TableHead>
                  <TableHead>Roles</TableHead>
                  <TableHead>Estado</TableHead>
                  <TableHead>Fecha de creación</TableHead>
                  <TableHead className="w-12"></TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {paginatedUsers.map((user) => (
                  <TableRow
                    key={user.id}
                    className={selectedUserIds.has(user.id) ? 'bg-muted/50' : ''}
                  >
                    <TableCell>
                      <Checkbox
                        checked={selectedUserIds.has(user.id)}
                        onCheckedChange={() => toggleSelectUser(user.id)}
                        aria-label={`Seleccionar ${user.fullName}`}
                      />
                    </TableCell>
                    <TableCell>{user.fullName}</TableCell>
                    <TableCell className="text-muted-foreground font-mono text-sm">{user.username}</TableCell>
                    <TableCell className="text-muted-foreground font-mono text-sm">
                      {user.password || '—'}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {user.phone || '—'}
                    </TableCell>
                    <TableCell>
                      <div className="flex flex-wrap gap-1">
                        {user.roles.map((role) => (
                          <RoleBadge key={role} role={role} />
                        ))}
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge
                        variant={user.status === 'Activo' ? 'default' : 'secondary'}
                        className={
                          user.status === 'Activo'
                            ? 'bg-green-100 text-green-700 hover:bg-green-100'
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-100'
                        }
                      >
                        {user.status}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {new Date(user.createdAt).toLocaleDateString('es-MX')}
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <MoreVertical className="w-4 h-4" />
                            <span className="sr-only">Acciones</span>
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem onClick={() => setEditingUser(user)}>
                            <Edit className="w-4 h-4 mr-2" />
                            Editar
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => setChangingPasswordUser(user)}>
                            <Key className="w-4 h-4 mr-2" />
                            Cambiar contraseña
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem
                            className="text-destructive"
                            onClick={() => {
                              setSelectedUserIds(new Set([user.id]));
                              handleBulkAction('delete');
                            }}
                          >
                            <Trash2 className="w-4 h-4 mr-2" />
                            Eliminar
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Card>
          
          {/* Mobile Cards */}
          <div className="lg:hidden space-y-4">
            {paginatedUsers.map((user) => (
              <Card key={user.id} className={selectedUserIds.has(user.id) ? 'border-blue-500' : ''}>
                <CardContent className="p-4 space-y-3">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3 flex-1">
                      <Checkbox
                        checked={selectedUserIds.has(user.id)}
                        onCheckedChange={() => toggleSelectUser(user.id)}
                        aria-label={`Seleccionar ${user.fullName}`}
                      />
                      <div className="flex-1 min-w-0">
                        <p className="font-medium">{user.fullName}</p>
                        <p className="text-sm text-muted-foreground truncate font-mono">@{user.username}</p>
                        {user.password && (
                          <p className="text-sm text-muted-foreground font-mono">🔑 {user.password}</p>
                        )}
                        {user.phone && (
                          <p className="text-sm text-muted-foreground">{user.phone}</p>
                        )}
                      </div>
                    </div>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm">
                          <MoreVertical className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => setEditingUser(user)}>
                          <Edit className="w-4 h-4 mr-2" />
                          Editar
                        </DropdownMenuItem>
                        <DropdownMenuItem onClick={() => setChangingPasswordUser(user)}>
                          <Key className="w-4 h-4 mr-2" />
                          Cambiar contraseña
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem
                          className="text-destructive"
                          onClick={() => {
                            setSelectedUserIds(new Set([user.id]));
                            handleBulkAction('delete');
                          }}
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Eliminar
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                  
                  <div className="flex flex-wrap gap-1">
                    {user.roles.map((role) => (
                      <RoleBadge key={role} role={role} />
                    ))}
                  </div>
                  
                  <div className="flex items-center justify-between text-sm">
                    <Badge
                      variant={user.status === 'Activo' ? 'default' : 'secondary'}
                      className={
                        user.status === 'Activo'
                          ? 'bg-green-100 text-green-700 hover:bg-green-100'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-100'
                      }
                    >
                      {user.status}
                    </Badge>
                    <span className="text-muted-foreground">
                      {new Date(user.createdAt).toLocaleDateString('es-MX')}
                    </span>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
          
          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between">
              <p className="text-sm text-muted-foreground">
                Mostrando {((currentPage - 1) * itemsPerPage) + 1} a{' '}
                {Math.min(currentPage * itemsPerPage, filteredUsers.length)} de{' '}
                {filteredUsers.length} resultados
              </p>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                  disabled={currentPage === 1}
                >
                  Anterior
                </Button>
                <div className="flex items-center gap-1">
                  {[...Array(totalPages)].map((_, i) => {
                    const page = i + 1;
                    if (
                      page === 1 ||
                      page === totalPages ||
                      (page >= currentPage - 1 && page <= currentPage + 1)
                    ) {
                      return (
                        <Button
                          key={page}
                          variant={currentPage === page ? 'default' : 'outline'}
                          size="sm"
                          onClick={() => setCurrentPage(page)}
                          className="w-10"
                        >
                          {page}
                        </Button>
                      );
                    } else if (page === currentPage - 2 || page === currentPage + 2) {
                      return <span key={page} className="px-2">...</span>;
                    }
                    return null;
                  })}
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                  disabled={currentPage === totalPages}
                >
                  Siguiente
                </Button>
              </div>
            </div>
          )}
        </>
      )}
      
      {/* Modals */}
      <NewUserModal
        open={showNewUserModal}
        onOpenChange={setShowNewUserModal}
        onUserCreated={handleUserCreated}
        existingEmails={existingEmails}
        existingUsernames={existingUsernames}
      />
      
      <EditUserModal
        open={!!editingUser}
        onOpenChange={(open) => !open && setEditingUser(null)}
        user={editingUser}
        onUserUpdated={handleUserUpdated}
        onUserDeleted={handleUserDeleted}
        existingEmails={existingEmails}
        existingUsernames={existingUsernames}
      />
      
      <ChangePasswordModal
        open={!!changingPasswordUser}
        onOpenChange={(open) => !open && setChangingPasswordUser(null)}
        user={changingPasswordUser}
        onPasswordChanged={() => {
          // Update user's updatedAt timestamp
          if (changingPasswordUser) {
            handleUserUpdated({
              ...changingPasswordUser,
              updatedAt: new Date().toISOString(),
              hasDefaultPassword: false,
            });
          }
        }}
      />
      
      {/* Bulk Action Confirmation */}
      <AlertDialog
        open={bulkActionDialog.open}
        onOpenChange={(open) => !open && setBulkActionDialog({ open: false, action: null })}
      >
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>
              {bulkActionDialog.action === 'delete' && '¿Eliminar usuarios?'}
              {bulkActionDialog.action === 'activate' && '¿Activar usuarios?'}
              {bulkActionDialog.action === 'deactivate' && '¿Desactivar usuarios?'}
            </AlertDialogTitle>
            <AlertDialogDescription>
              {bulkActionDialog.action === 'delete' && (
                <>
                  Esta acción no se puede deshacer. Se eliminarán permanentemente{' '}
                  <span className="font-medium text-foreground">{selectedUserIds.size}</span>{' '}
                  usuario(s) del sistema.
                </>
              )}
              {bulkActionDialog.action === 'activate' && (
                <>
                  Se activarán <span className="font-medium text-foreground">{selectedUserIds.size}</span>{' '}
                  usuario(s) y podrán acceder al sistema.
                </>
              )}
              {bulkActionDialog.action === 'deactivate' && (
                <>
                  Se desactivarán <span className="font-medium text-foreground">{selectedUserIds.size}</span>{' '}
                  usuario(s) y no podrán iniciar sesión.
                </>
              )}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isLoading}>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={executeBulkAction}
              disabled={isLoading}
              className={
                bulkActionDialog.action === 'delete'
                  ? 'bg-destructive text-destructive-foreground hover:bg-destructive/90'
                  : ''
              }
            >
              {isLoading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
              Confirmar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}