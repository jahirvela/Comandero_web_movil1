import { useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "../../ui/dialog";
import { Button } from "../../ui/button";
import { Input } from "../../ui/input";
import { Label } from "../../ui/label";
import { Alert, AlertDescription } from "../../ui/alert";
import { Eye, EyeOff, Loader2, AlertCircle, CheckCircle2, RefreshCw, Copy } from "lucide-react";
import { User } from "./mockUsers";
import { PasswordStrengthMeter } from "./PasswordStrengthMeter";
import { toast } from "sonner";

interface ChangePasswordModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  user: User | null;
  onPasswordChanged: () => void;
}

export function ChangePasswordModal({
  open,
  onOpenChange,
  user,
  onPasswordChanged,
}: ChangePasswordModalProps) {
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  
  const [errors, setErrors] = useState<{
    newPassword?: string;
    confirmPassword?: string;
  }>({});
  
  const generatePassword = () => {
    const length = 12;
    const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*";
    let password = "";
    
    // Asegurar que tenga al menos uno de cada tipo
    password += "ABCDEFGHIJKLMNOPQRSTUVWXYZ"[Math.floor(Math.random() * 26)]; // Mayúscula
    password += "abcdefghijklmnopqrstuvwxyz"[Math.floor(Math.random() * 26)]; // Minúscula
    password += "0123456789"[Math.floor(Math.random() * 10)]; // Número
    password += "!@#$%^&*"[Math.floor(Math.random() * 8)]; // Especial
    
    // Completar el resto
    for (let i = password.length; i < length; i++) {
      password += charset[Math.floor(Math.random() * charset.length)];
    }
    
    // Mezclar
    password = password.split('').sort(() => Math.random() - 0.5).join('');
    
    setNewPassword(password);
    setConfirmPassword(password);
    setShowNewPassword(true);
    setShowConfirmPassword(true);
    setErrors({});
    
    toast.success('Contraseña generada', {
      description: 'Se ha generado una contraseña segura automáticamente',
    });
  };
  
  const copyPassword = async () => {
    try {
      await navigator.clipboard.writeText(newPassword);
      toast.success('Contraseña copiada', {
        description: 'La contraseña ha sido copiada al portapapeles',
      });
    } catch (err) {
      toast.error('Error al copiar', {
        description: 'No se pudo copiar la contraseña al portapapeles',
      });
    }
  };
  
  const validateForm = (): boolean => {
    const newErrors: typeof errors = {};
    
    if (!newPassword) {
      newErrors.newPassword = 'La nueva contraseña es obligatoria';
    } else if (newPassword.length < 8) {
      newErrors.newPassword = 'La contraseña debe tener al menos 8 caracteres';
    } else {
      const missingRequirements = [];
      if (!/[a-z]/.test(newPassword)) missingRequirements.push('una letra minúscula');
      if (!/[A-Z]/.test(newPassword)) missingRequirements.push('una letra mayúscula');
      if (!/[0-9]/.test(newPassword)) missingRequirements.push('un número');
      
      if (missingRequirements.length > 0) {
        newErrors.newPassword = `Debe incluir: ${missingRequirements.join(', ')}`;
      }
    }
    
    if (!confirmPassword) {
      newErrors.confirmPassword = 'Debe confirmar la nueva contraseña';
    } else if (confirmPassword !== newPassword) {
      newErrors.confirmPassword = 'Las contraseñas no coinciden';
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
      onPasswordChanged();
      toast.success('Contraseña actualizada', {
        description: `La contraseña de ${user.fullName} ha sido establecida exitosamente`,
      });
      handleClose();
      setIsLoading(false);
    }, 1000);
  };
  
  const handleClose = () => {
    setNewPassword('');
    setConfirmPassword('');
    setShowNewPassword(false);
    setShowConfirmPassword(false);
    setErrors({});
    onOpenChange(false);
  };
  
  if (!user) return null;
  
  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Cambiar Contraseña</DialogTitle>
          <DialogDescription>
            Establece una nueva contraseña para {user.fullName}
          </DialogDescription>
        </DialogHeader>
        
        {user.hasDefaultPassword && (
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              Este usuario aún no tiene una contraseña establecida. Debe configurarla para que pueda iniciar sesión.
            </AlertDescription>
          </Alert>
        )}
        
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Generate Password Button */}
          <div className="flex gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={generatePassword}
              className="flex-1"
            >
              <RefreshCw className="w-4 h-4 mr-2" />
              Generar contraseña
            </Button>
            {newPassword && (
              <Button
                type="button"
                variant="outline"
                onClick={copyPassword}
              >
                <Copy className="w-4 h-4" />
              </Button>
            )}
          </div>
          
          {/* New Password */}
          <div className="space-y-2">
            <Label htmlFor="newPassword">
              Nueva contraseña <span className="text-red-500">*</span>
            </Label>
            <div className="relative">
              <Input
                id="newPassword"
                type={showNewPassword ? 'text' : 'password'}
                value={newPassword}
                onChange={(e) => {
                  setNewPassword(e.target.value);
                  if (errors.newPassword) setErrors(prev => ({ ...prev, newPassword: undefined }));
                }}
                className={errors.newPassword ? 'border-red-500 pr-10' : 'pr-10'}
                placeholder="Mínimo 8 caracteres"
              />
              <button
                type="button"
                onClick={() => setShowNewPassword(!showNewPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                {showNewPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            {errors.newPassword && (
              <p className="text-sm text-red-500">{errors.newPassword}</p>
            )}
            <PasswordStrengthMeter password={newPassword} />
          </div>
          
          {/* Confirm Password */}
          <div className="space-y-2">
            <Label htmlFor="confirmPassword">
              Confirmar nueva contraseña <span className="text-red-500">*</span>
            </Label>
            <div className="relative">
              <Input
                id="confirmPassword"
                type={showConfirmPassword ? 'text' : 'password'}
                value={confirmPassword}
                onChange={(e) => {
                  setConfirmPassword(e.target.value);
                  if (errors.confirmPassword) setErrors(prev => ({ ...prev, confirmPassword: undefined }));
                }}
                className={errors.confirmPassword ? 'border-red-500 pr-10' : 'pr-10'}
                placeholder="Repite la contraseña"
              />
              <button
                type="button"
                onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            {errors.confirmPassword && (
              <p className="text-sm text-red-500">{errors.confirmPassword}</p>
            )}
            {confirmPassword && confirmPassword === newPassword && !errors.confirmPassword && (
              <div className="flex items-center gap-1 text-sm text-green-600">
                <CheckCircle2 className="w-4 h-4" />
                Las contraseñas coinciden
              </div>
            )}
          </div>
          
          {/* Requirements */}
          <div className="p-3 bg-muted/50 rounded-lg space-y-1">
            <p className="text-sm">La contraseña debe contener:</p>
            <ul className="text-sm text-muted-foreground space-y-1 ml-4 list-disc">
              <li>Al menos 8 caracteres</li>
              <li>Una letra mayúscula</li>
              <li>Una letra minúscula</li>
              <li>Un número</li>
            </ul>
          </div>
          
          <Alert className="bg-amber-50 border-amber-200">
            <AlertCircle className="h-4 w-4 text-amber-600" />
            <AlertDescription className="text-amber-900">
              Como administrador, puedes establecer la contraseña sin conocer la contraseña anterior del usuario.
            </AlertDescription>
          </Alert>
          
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
              Establecer contraseña
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
