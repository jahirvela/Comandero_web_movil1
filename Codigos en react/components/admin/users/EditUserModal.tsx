import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "../../ui/dialog";
import { Button } from "../../ui/button";
import { Input } from "../../ui/input";
import { Label } from "../../ui/label";
import { Checkbox } from "../../ui/checkbox";
import { Switch } from "../../ui/switch";
import { Separator } from "../../ui/separator";
import { Alert, AlertDescription } from "../../ui/alert";
import { Loader2, Trash2, AlertCircle } from "lucide-react";
import { UserRole, User } from "./mockUsers";
import { toast } from "sonner";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "../../ui/alert-dialog";

interface EditUserModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  user: User | null;
  onUserUpdated: (user: User) => void;
  onUserDeleted: (userId: string) => void;
  existingEmails: string[];
  existingUsernames?: string[];
}

const availableRoles: UserRole[] = ['Mesero', 'Cocinero', 'Capitán', 'Cajero', 'Administrador'];

export function EditUserModal({
  open,
  onOpenChange,
  user,
  onUserUpdated,
  onUserDeleted,
  existingEmails,
  existingUsernames = [],
}: EditUserModalProps) {
  const [username, setUsername] = useState('');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [selectedRoles, setSelectedRoles] = useState<UserRole[]>([]);
  const [status, setStatus] = useState<'Activo' | 'Inactivo'>('Activo');
  const [isLoading, setIsLoading] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  
  const [errors, setErrors] = useState<{
    username?: string;
    fullName?: string;
    email?: string;
    roles?: string;
  }>({});
  
  useEffect(() => {
    if (user) {
      setUsername(user.username);
      setFullName(user.fullName);
      setEmail(user.email);
      setPhone(user.phone || '');
      setSelectedRoles(user.roles);
      setStatus(user.status);
    }
  }, [user]);
  
  const validateForm = (): boolean => {
    const newErrors: typeof errors = {};
    
    if (!username.trim()) {
      newErrors.username = 'El nombre de usuario es obligatorio';
    } else if (username.trim().length < 3 || username.trim().length > 20) {
      newErrors.username = 'El nombre de usuario debe tener entre 3 y 20 caracteres';
    } else if (!/^[a-z0-9_.]+$/.test(username.trim().toLowerCase())) {
      newErrors.username = 'Solo minúsculas, números, guion bajo (_) y punto (.)';
    } else if (
      username.toLowerCase().trim() !== user?.username.toLowerCase() &&
      existingUsernames.includes(username.toLowerCase().trim())
    ) {
      newErrors.username = 'Este nombre de usuario ya está en uso';
    }
    
    if (!fullName.trim()) {
      newErrors.fullName = 'El nombre completo es obligatorio';
    }
    
    if (!email.trim()) {
      newErrors.email = 'El email es obligatorio';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      newErrors.email = 'El formato del email no es válido';
    } else if (
      email.toLowerCase() !== user?.email.toLowerCase() &&
      existingEmails.includes(email.toLowerCase())
    ) {
      newErrors.email = 'Este email ya está registrado';
    }
    
    if (selectedRoles.length === 0) {
      newErrors.roles = 'Debe seleccionar al menos un rol';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!user || !validateForm()) {
      return;
    }
    
    setIsLoading(true);
    
    // Simulate API call
    setTimeout(() => {
      const updatedUser: User = {
        ...user,
        username: username.trim().toLowerCase(),
        fullName: fullName.trim(),
        email: email.toLowerCase().trim(),
        phone: phone.trim() || undefined,
        roles: selectedRoles,
        status,
        updatedAt: new Date().toISOString(),
      };
      
      onUserUpdated(updatedUser);
      toast.success('Usuario actualizado', {
        description: `Los cambios de ${updatedUser.fullName} han sido guardados`,
      });
      handleClose();
      setIsLoading(false);
    }, 800);
  };
  
  const handleDelete = () => {
    if (!user) return;
    
    setIsLoading(true);
    
    // Simulate API call
    setTimeout(() => {
      onUserDeleted(user.id);
      toast.success('Usuario eliminado', {
        description: `${user.fullName} ha sido eliminado del sistema`,
      });
      setShowDeleteDialog(false);
      handleClose();
      setIsLoading(false);
    }, 600);
  };
  
  const handleReset = () => {
    if (user) {
      setUsername(user.username);
      setFullName(user.fullName);
      setEmail(user.email);
      setPhone(user.phone || '');
      setSelectedRoles(user.roles);
      setStatus(user.status);
      setErrors({});
    }
  };
  
  const handleClose = () => {
    setErrors({});
    onOpenChange(false);
  };
  
  const toggleRole = (role: UserRole) => {
    setSelectedRoles(prev =>
      prev.includes(role)
        ? prev.filter(r => r !== role)
        : [...prev, role]
    );
    if (errors.roles) {
      setErrors(prev => ({ ...prev, roles: undefined }));
    }
  };
  
  if (!user) return null;
  
  return (
    <>
      <Dialog open={open} onOpenChange={handleClose}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Editar Usuario</DialogTitle>
            <DialogDescription>
              Actualiza la información del usuario en el sistema
            </DialogDescription>
          </DialogHeader>
          
          <form onSubmit={handleSubmit} className="space-y-6">
            <div className="space-y-4">
              {/* Username */}
              <div className="space-y-2">
                <Label htmlFor="edit-username">
                  Nombre de usuario <span className="text-red-500">*</span>
                </Label>
                <Input
                  id="edit-username"
                  value={username}
                  onChange={(e) => {
                    setUsername(e.target.value.toLowerCase());
                    if (errors.username) setErrors(prev => ({ ...prev, username: undefined }));
                  }}
                  className={errors.username ? 'border-red-500' : ''}
                  maxLength={20}
                />
                {errors.username && (
                  <p className="text-sm text-red-500">{errors.username}</p>
                )}
                {username !== user.username && (
                  <Alert className="bg-amber-50 border-amber-200">
                    <AlertCircle className="h-4 w-4 text-amber-600" />
                    <AlertDescription className="text-amber-900">
                      <strong>Advertencia:</strong> Cambiar el nombre de usuario afectará el inicio de sesión del usuario.
                    </AlertDescription>
                  </Alert>
                )}
                <p className="text-sm text-muted-foreground">
                  3–20 caracteres; minúsculas, números, guion bajo (_) o punto (.)
                </p>
              </div>
              
              {/* Full Name */}
              <div className="space-y-2">
                <Label htmlFor="edit-fullName">
                  Nombre completo <span className="text-red-500">*</span>
                </Label>
                <Input
                  id="edit-fullName"
                  value={fullName}
                  onChange={(e) => {
                    setFullName(e.target.value);
                    if (errors.fullName) setErrors(prev => ({ ...prev, fullName: undefined }));
                  }}
                  className={errors.fullName ? 'border-red-500' : ''}
                />
                {errors.fullName && (
                  <p className="text-sm text-red-500">{errors.fullName}</p>
                )}
              </div>
              
              {/* Email */}
              <div className="space-y-2">
                <Label htmlFor="edit-email">
                  Email <span className="text-red-500">*</span>
                </Label>
                <Input
                  id="edit-email"
                  type="email"
                  value={email}
                  onChange={(e) => {
                    setEmail(e.target.value);
                    if (errors.email) setErrors(prev => ({ ...prev, email: undefined }));
                  }}
                  className={errors.email ? 'border-red-500' : ''}
                />
                {errors.email && (
                  <p className="text-sm text-red-500">{errors.email}</p>
                )}
              </div>
              
              {/* Phone */}
              <div className="space-y-2">
                <Label htmlFor="edit-phone">Teléfono</Label>
                <Input
                  id="edit-phone"
                  type="tel"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="+52 55 1234 5678"
                />
              </div>
              
              {/* Roles */}
              <div className="space-y-3">
                <Label>
                  Roles <span className="text-red-500">*</span>
                </Label>
                <div className="grid grid-cols-2 gap-3">
                  {availableRoles.map((role) => (
                    <div key={role} className="flex items-center space-x-2">
                      <Checkbox
                        id={`edit-role-${role}`}
                        checked={selectedRoles.includes(role)}
                        onCheckedChange={() => toggleRole(role)}
                      />
                      <label
                        htmlFor={`edit-role-${role}`}
                        className="text-sm cursor-pointer select-none"
                      >
                        {role}
                      </label>
                    </div>
                  ))}
                </div>
                {errors.roles && (
                  <p className="text-sm text-red-500">{errors.roles}</p>
                )}
              </div>
              
              {/* Status */}
              <div className="flex items-center justify-between space-x-2">
                <div className="space-y-1">
                  <Label htmlFor="edit-status">Estado del usuario</Label>
                  <p className="text-sm text-muted-foreground">
                    {status === 'Activo' 
                      ? 'El usuario puede acceder al sistema' 
                      : 'El usuario no puede iniciar sesión'}
                  </p>
                </div>
                <Switch
                  id="edit-status"
                  checked={status === 'Activo'}
                  onCheckedChange={(checked) => setStatus(checked ? 'Activo' : 'Inactivo')}
                />
              </div>
            </div>
            
            <Separator />
            
            {/* Audit Info */}
            <div className="grid grid-cols-2 gap-4 p-4 bg-muted/50 rounded-lg">
              <div>
                <p className="text-sm text-muted-foreground">Fecha de creación</p>
                <p className="text-sm">
                  {new Date(user.createdAt).toLocaleDateString('es-MX', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                  })}
                </p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Última actualización</p>
                <p className="text-sm">
                  {new Date(user.updatedAt).toLocaleDateString('es-MX', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric',
                  })}
                </p>
              </div>
            </div>
            
            <DialogFooter className="flex-col sm:flex-row gap-2">
              <Button
                type="button"
                variant="destructive"
                onClick={() => setShowDeleteDialog(true)}
                disabled={isLoading}
                className="sm:mr-auto"
              >
                <Trash2 className="w-4 h-4 mr-2" />
                Eliminar
              </Button>
              <div className="flex gap-2">
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleReset}
                  disabled={isLoading}
                >
                  Restablecer
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={handleClose}
                  disabled={isLoading}
                >
                  Cancelar
                </Button>
                <Button type="submit" disabled={isLoading}>
                  {isLoading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
                  Guardar cambios
                </Button>
              </div>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
      
      {/* Delete Confirmation Dialog */}
      <AlertDialog open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar usuario?</AlertDialogTitle>
            <AlertDialogDescription>
              Esta acción no se puede deshacer. Se eliminará permanentemente a{' '}
              <span className="font-medium text-foreground">{user.fullName}</span> del sistema.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={isLoading}>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              disabled={isLoading}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {isLoading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
              Eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}
