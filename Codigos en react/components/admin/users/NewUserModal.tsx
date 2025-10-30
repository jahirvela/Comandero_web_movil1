import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "../../ui/dialog";
import { Button } from "../../ui/button";
import { Input } from "../../ui/input";
import { Label } from "../../ui/label";
import { Checkbox } from "../../ui/checkbox";
import { Loader2, Eye, EyeOff, RefreshCw } from "lucide-react";
import { UserRole, User } from "./mockUsers";
import { PasswordStrengthMeter } from "./PasswordStrengthMeter";
import { toast } from "sonner";

interface NewUserModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onUserCreated: (user: User) => void;
  existingEmails: string[];
  existingUsernames?: string[];
}

const availableRoles: UserRole[] = ['Mesero', 'Cocinero', 'Capitán', 'Cajero', 'Administrador'];

export function NewUserModal({ 
  open, 
  onOpenChange, 
  onUserCreated, 
  existingEmails,
  existingUsernames = []
}: NewUserModalProps) {
  const [username, setUsername] = useState('');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [selectedRoles, setSelectedRoles] = useState<UserRole[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  
  const [errors, setErrors] = useState<{
    username?: string;
    fullName?: string;
    email?: string;
    password?: string;
    roles?: string;
  }>({});
  
  const generateSecurePassword = () => {
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const symbols = '!@#$%^&*';
    
    const allChars = lowercase + uppercase + numbers + symbols;
    
    let password = '';
    // Asegurar al menos uno de cada tipo
    password += lowercase[Math.floor(Math.random() * lowercase.length)];
    password += uppercase[Math.floor(Math.random() * uppercase.length)];
    password += numbers[Math.floor(Math.random() * numbers.length)];
    password += symbols[Math.floor(Math.random() * symbols.length)];
    
    // Completar hasta 12 caracteres
    for (let i = password.length; i < 12; i++) {
      password += allChars[Math.floor(Math.random() * allChars.length)];
    }
    
    // Mezclar los caracteres
    return password.split('').sort(() => Math.random() - 0.5).join('');
  };
  
  const validateForm = (): boolean => {
    const newErrors: typeof errors = {};
    
    if (!username.trim()) {
      newErrors.username = 'El nombre de usuario es obligatorio';
    } else if (username.trim().length < 3 || username.trim().length > 20) {
      newErrors.username = 'El nombre de usuario debe tener entre 3 y 20 caracteres';
    } else if (!/^[a-z0-9_.]+$/.test(username.trim().toLowerCase())) {
      newErrors.username = 'Solo minúsculas, números, guion bajo (_) y punto (.)';
    } else if (existingUsernames.includes(username.toLowerCase().trim())) {
      newErrors.username = 'Este nombre de usuario ya está en uso';
    }
    
    if (!fullName.trim()) {
      newErrors.fullName = 'El nombre completo es obligatorio';
    }
    
    if (!password.trim()) {
      newErrors.password = 'La contraseña es obligatoria';
    } else if (password.length < 8) {
      newErrors.password = 'La contraseña debe tener al menos 8 caracteres';
    } else if (!/[a-z]/.test(password)) {
      newErrors.password = 'Debe contener al menos una minúscula';
    } else if (!/[A-Z]/.test(password)) {
      newErrors.password = 'Debe contener al menos una mayúscula';
    } else if (!/[0-9]/.test(password)) {
      newErrors.password = 'Debe contener al menos un número';
    } else if (!/[^a-zA-Z0-9]/.test(password)) {
      newErrors.password = 'Debe contener al menos un carácter especial';
    }
    
    if (selectedRoles.length === 0) {
      newErrors.roles = 'Debe seleccionar al menos un rol';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }
    
    setIsLoading(true);
    
    // Simulate API call
    setTimeout(() => {
      const newUser: User = {
        id: Date.now().toString(),
        username: username.trim().toLowerCase(),
        fullName: fullName.trim(),
        email: email.toLowerCase().trim(),
        phone: phone.trim() || undefined,
        password: password,
        roles: selectedRoles,
        status: 'Activo',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        hasDefaultPassword: false,
      };
      
      onUserCreated(newUser);
      toast.success('Usuario creado exitosamente', {
        description: `${newUser.fullName} ha sido agregado al sistema con contraseña.`,
      });
      handleClose();
      setIsLoading(false);
    }, 800);
  };
  
  const handleClose = () => {
    setUsername('');
    setFullName('');
    setEmail('');
    setPhone('');
    setPassword('');
    setShowPassword(false);
    setSelectedRoles([]);
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
  
  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Nuevo Usuario</DialogTitle>
          <DialogDescription>
            Completa la información del nuevo usuario del sistema
          </DialogDescription>
        </DialogHeader>
        
        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="space-y-4">
            {/* Username */}
            <div className="space-y-2">
              <Label htmlFor="username">
                Nombre de usuario <span className="text-red-500">*</span>
              </Label>
              <Input
                id="username"
                value={username}
                onChange={(e) => {
                  setUsername(e.target.value.toLowerCase());
                  if (errors.username) setErrors(prev => ({ ...prev, username: undefined }));
                }}
                placeholder="ej. juan.perez, mgarcia_22"
                className={errors.username ? 'border-red-500' : ''}
                maxLength={20}
              />
              {errors.username && (
                <p className="text-sm text-red-500">{errors.username}</p>
              )}
              <p className="text-sm text-muted-foreground">
                3–20 caracteres; minúsculas, números, guion bajo (_) o punto (.)
              </p>
            </div>
            
            {/* Full Name */}
            <div className="space-y-2">
              <Label htmlFor="fullName">
                Nombre completo <span className="text-red-500">*</span>
              </Label>
              <Input
                id="fullName"
                value={fullName}
                onChange={(e) => {
                  setFullName(e.target.value);
                  if (errors.fullName) setErrors(prev => ({ ...prev, fullName: undefined }));
                }}
                placeholder="Ej. Carlos Mendoza García"
                className={errors.fullName ? 'border-red-500' : ''}
              />
              {errors.fullName && (
                <p className="text-sm text-red-500">{errors.fullName}</p>
              )}
            </div>
            
            {/* Password */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password">
                  Contraseña <span className="text-red-500">*</span>
                </Label>
                <Button
                  type="button"
                  variant="ghost"
                  size="sm"
                  onClick={() => {
                    const newPassword = generateSecurePassword();
                    setPassword(newPassword);
                    if (errors.password) setErrors(prev => ({ ...prev, password: undefined }));
                  }}
                  className="h-8 text-xs"
                >
                  <RefreshCw className="w-3 h-3 mr-1" />
                  Generar
                </Button>
              </div>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => {
                    setPassword(e.target.value);
                    if (errors.password) setErrors(prev => ({ ...prev, password: undefined }));
                  }}
                  placeholder="Contraseña segura"
                  className={errors.password ? 'border-red-500 pr-10' : 'pr-10'}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
              {errors.password && (
                <p className="text-sm text-red-500">{errors.password}</p>
              )}
              {password && <PasswordStrengthMeter password={password} />}
              <p className="text-sm text-muted-foreground">
                Mínimo 8 caracteres: mayúsculas, minúsculas, números y símbolos
              </p>
            </div>
            
            {/* Phone */}
            <div className="space-y-2">
              <Label htmlFor="phone">Teléfono</Label>
              <Input
                id="phone"
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+52 55 1234 5678"
              />
              <p className="text-sm text-muted-foreground">Opcional</p>
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
                      id={`role-${role}`}
                      checked={selectedRoles.includes(role)}
                      onCheckedChange={() => toggleRole(role)}
                    />
                    <label
                      htmlFor={`role-${role}`}
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
            
            {/* Password Note */}
            <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg">
              <p className="text-sm text-blue-900">
                <strong>Nota:</strong> La contraseña será visible en la tabla de usuarios. 
                Asegúrate de compartirla de forma segura con el usuario.
              </p>
            </div>
          </div>
          
          <DialogFooter>
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
              Crear Usuario
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
