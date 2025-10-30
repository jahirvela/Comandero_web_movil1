import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from './ui/dialog';
import { Button } from './ui/button';
import { Checkbox } from './ui/checkbox';
import { Card, CardContent } from './ui/card';
import { UserCheck, ChefHat, Settings, Calculator, ShieldCheck } from 'lucide-react';

interface Role {
  type: 'mesero' | 'cocina' | 'admin' | 'cajero' | 'capitan';
  name: string;
  icon: typeof UserCheck;
  color: string;
  bgColor: string;
}

interface RolePickerModalProps {
  open: boolean;
  userName: string;
  availableRoles: Role[];
  onRoleSelected: (roleType: string) => void;
  rememberRole?: boolean;
  onRememberChange?: (remember: boolean) => void;
}

const roleIcons = {
  mesero: { icon: UserCheck, color: 'text-amber-600', bgColor: 'bg-amber-50 hover:bg-amber-100 border-amber-200' },
  cocina: { icon: ChefHat, color: 'text-orange-600', bgColor: 'bg-orange-50 hover:bg-orange-100 border-orange-200' },
  admin: { icon: Settings, color: 'text-green-600', bgColor: 'bg-green-50 hover:bg-green-100 border-green-200' },
  cajero: { icon: Calculator, color: 'text-blue-600', bgColor: 'bg-blue-50 hover:bg-blue-100 border-blue-200' },
  capitan: { icon: ShieldCheck, color: 'text-purple-600', bgColor: 'bg-purple-50 hover:bg-purple-100 border-purple-200' },
};

export function RolePickerModal({
  open,
  userName,
  availableRoles,
  onRoleSelected,
  rememberRole = false,
  onRememberChange,
}: RolePickerModalProps) {
  const [remember, setRemember] = useState(rememberRole);

  const handleRoleSelect = (roleType: string) => {
    if (onRememberChange) {
      onRememberChange(remember);
    }
    onRoleSelected(roleType);
  };

  return (
    <Dialog open={open} onOpenChange={() => {}}>
      <DialogContent className="max-w-md" onInteractOutside={(e) => e.preventDefault()}>
        <DialogHeader>
          <DialogTitle>Selecciona tu rol</DialogTitle>
          <DialogDescription>
            Hola, <span className="font-medium text-foreground">{userName}</span>. Tienes múltiples roles asignados.
            Selecciona el rol con el que deseas trabajar en esta sesión.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="grid gap-3">
            {availableRoles.map((role) => {
              const iconConfig = roleIcons[role.type];
              const Icon = iconConfig.icon;
              
              return (
                <Card
                  key={role.type}
                  className={`cursor-pointer transition-all hover:shadow-md border-2 ${iconConfig.bgColor}`}
                  onClick={() => handleRoleSelect(role.type)}
                >
                  <CardContent className="flex items-center gap-4 p-4">
                    <div className={`flex-shrink-0 ${iconConfig.color}`}>
                      <Icon className="w-8 h-8" />
                    </div>
                    <div className="flex-1">
                      <h3 className="font-medium">{role.name}</h3>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>

          {onRememberChange && (
            <div className="flex items-center space-x-2 pt-2">
              <Checkbox
                id="remember-role"
                checked={remember}
                onCheckedChange={(checked) => setRemember(checked === true)}
              />
              <label
                htmlFor="remember-role"
                className="text-sm cursor-pointer select-none"
              >
                Recordar este rol para futuras sesiones
              </label>
            </div>
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}
