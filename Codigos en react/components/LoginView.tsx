import React, { useState } from 'react';
import { Button } from './ui/button';
import { Input } from './ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './ui/card';
import { Label } from './ui/label';
import { Badge } from './ui/badge';
import { Checkbox } from './ui/checkbox';
import { Alert, AlertDescription } from './ui/alert';
import { LogoC } from './RoleSpecificIcons';
import { RolePickerModal } from './RolePickerModal';
import { UserCheck, ChefHat, Settings, Calculator, ShieldCheck, Eye, EyeOff, AlertCircle, Loader2 } from 'lucide-react';

interface User {
  id: number;
  name: string;
  type: 'mesero' | 'cocina' | 'admin' | 'cajero' | 'capitan';
  role: string;
  shift: string;
  roles?: string[]; // Para usuarios con múltiples roles
}

interface LoginViewProps {
  onLogin: (user: User) => void;
}

export function LoginView({ onLogin }: LoginViewProps) {
  const [username, setUsername] = useState<string>('');
  const [password, setPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [rememberMe, setRememberMe] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');
  const [showRolePicker, setShowRolePicker] = useState<boolean>(false);
  const [pendingUser, setPendingUser] = useState<any>(null);
  const [rememberRole, setRememberRole] = useState<boolean>(false);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    // Simular delay de conexión
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Usuarios demo con roles específicos
    const users = {
      'mesero': { id: 1, name: 'Juan Martínez', type: 'mesero' as const, role: 'Mesero', shift: 'Matutino', status: 'Activo' },
      'cocina': { id: 2, name: 'Carlos López', type: 'cocina' as const, role: 'Cocinero', shift: 'Matutino', status: 'Activo' },
      'admin': { id: 3, name: 'María González', type: 'admin' as const, role: 'Administrador', shift: 'Completo', status: 'Activo' },
      'cajero': { id: 4, name: 'Ana Rodríguez', type: 'cajero' as const, role: 'Cajero', shift: 'Vespertino', status: 'Activo' },
      'capitan': { id: 5, name: 'Roberto Silva', type: 'capitan' as const, role: 'Capitán', shift: 'Matutino', status: 'Activo' },
      'inactivo': { id: 6, name: 'Usuario Inactivo', type: 'mesero' as const, role: 'Mesero', shift: 'Matutino', status: 'Inactivo' },
      'admin_multi': { id: 7, name: 'Admin Multi-Rol', type: 'admin' as const, role: 'Administrador', shift: 'Completo', status: 'Activo', roles: ['admin', 'cajero'] }
    };

    const user = users[username.toLowerCase().trim()];
    
    if (!user) {
      setError('Credenciales inválidas. Verifica tu nombre de usuario y contraseña.');
      setLoading(false);
      return;
    }
    
    if (user.status === 'Inactivo') {
      setError('Tu cuenta está inactiva. Contacta al administrador para más información.');
      setLoading(false);
      return;
    }
    
    // Validación básica de contraseña (en producción validaría contra backend)
    if (!password || password.length < 3) {
      setError('Credenciales inválidas. Verifica tu nombre de usuario y contraseña.');
      setLoading(false);
      return;
    }
    
    // Si el usuario tiene múltiples roles, mostrar el modal de selección
    if (user.roles && user.roles.length > 1) {
      setPendingUser(user);
      setShowRolePicker(true);
      setLoading(false);
      return;
    }
    
    // Si todo está bien y solo tiene 1 rol, hacer login directo
    onLogin(user);
    setLoading(false);
  };

  const handleRoleSelected = (roleType: string) => {
    if (pendingUser) {
      // Actualizar el tipo y rol del usuario según el rol seleccionado
      const roleMap = {
        'mesero': { type: 'mesero' as const, role: 'Mesero' },
        'cocina': { type: 'cocina' as const, role: 'Cocinero' },
        'admin': { type: 'admin' as const, role: 'Administrador' },
        'cajero': { type: 'cajero' as const, role: 'Cajero' },
        'capitan': { type: 'capitan' as const, role: 'Capitán' },
      };
      
      const selectedRole = roleMap[roleType];
      const userWithRole = {
        ...pendingUser,
        type: selectedRole.type,
        role: selectedRole.role,
      };
      
      setShowRolePicker(false);
      setPendingUser(null);
      onLogin(userWithRole);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-amber-50 to-orange-100 p-4">
      <Card className="w-full max-w-md border-amber-200/50 shadow-lg">
        <CardHeader className="space-y-4 text-center">
          <div className="flex justify-center mb-4">
            <LogoC size={64} />
          </div>
          <div>
            <CardTitle className="text-2xl text-amber-900 font-bold">Comandix</CardTitle>
            <CardDescription className="text-amber-700">
              Sistema de comandero para puesto de barbacoa
            </CardDescription>
          </div>
          
          <div className="space-y-3">
            <div className="text-xs text-amber-800 font-medium">Roles del sistema (referencia)</div>
            <div className="grid grid-cols-2 gap-3">
              <div className="flex flex-col items-center gap-2 p-2 rounded-lg border border-amber-200 bg-amber-50">
                <UserCheck className="h-8 w-8 text-amber-600" />
                <Badge variant="outline" className="border-amber-300 text-amber-800 bg-transparent text-xs">
                  mesero
                </Badge>
              </div>
              <div className="flex flex-col items-center gap-2 p-2 rounded-lg border border-orange-200 bg-orange-50">
                <ChefHat className="h-8 w-8 text-orange-600" />
                <Badge variant="outline" className="border-orange-300 text-orange-800 bg-transparent text-xs">
                  cocina
                </Badge>
              </div>
              <div className="flex flex-col items-center gap-2 p-2 rounded-lg border border-green-200 bg-green-50">
                <Settings className="h-8 w-8 text-green-600" />
                <Badge variant="outline" className="border-green-300 text-green-800 bg-transparent text-xs">
                  admin
                </Badge>
              </div>
              <div className="flex flex-col items-center gap-2 p-2 rounded-lg border border-blue-200 bg-blue-50">
                <Calculator className="h-8 w-8 text-blue-600" />
                <Badge variant="outline" className="border-blue-300 text-blue-800 bg-transparent text-xs">
                  cajero
                </Badge>
              </div>
              <div className="flex flex-col items-center gap-2 p-2 rounded-lg border border-purple-200 bg-purple-50 col-span-2">
                <ShieldCheck className="h-8 w-8 text-purple-600" />
                <Badge variant="outline" className="border-purple-300 text-purple-800 bg-transparent text-xs">
                  capitan
                </Badge>
              </div>
            </div>
          </div>
        </CardHeader>
        
        <CardContent>
          {error && (
            <Alert variant="destructive" className="mb-4">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}
          
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="username" className="text-amber-900">Nombre de usuario</Label>
              <Input
                id="username"
                placeholder="Ingresa tu nombre de usuario"
                value={username}
                onChange={(e) => {
                  setUsername(e.target.value);
                  setError('');
                }}
                className="border-amber-200 focus:border-amber-500 focus:ring-amber-500"
                required
                disabled={loading}
                autoComplete="username"
              />
            </div>
            
            <div className="space-y-2">
              <Label htmlFor="password" className="text-amber-900">Contraseña</Label>
              <div className="relative">
                <Input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  placeholder="Ingresa tu contraseña"
                  value={password}
                  onChange={(e) => {
                    setPassword(e.target.value);
                    setError('');
                  }}
                  className="border-amber-200 focus:border-amber-500 focus:ring-amber-500 pr-10"
                  required
                  disabled={loading}
                  autoComplete="current-password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-amber-600 hover:text-amber-800"
                  disabled={loading}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>
            
            <div className="flex items-center space-x-2">
              <Checkbox
                id="remember"
                checked={rememberMe}
                onCheckedChange={(checked) => setRememberMe(checked === true)}
                disabled={loading}
              />
              <label
                htmlFor="remember"
                className="text-sm cursor-pointer select-none text-amber-900"
              >
                Recordarme
              </label>
            </div>
            
            <Button 
              type="submit" 
              className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700 text-white shadow-md"
              disabled={loading}
              size="lg"
            >
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {loading ? 'Iniciando sesión...' : 'Iniciar sesión'}
            </Button>
            
            <p className="text-center text-sm text-amber-700 mt-4">
              ¿Problemas para entrar?{' '}
              <span className="font-medium">Contacta al administrador</span>
            </p>
          </form>
        </CardContent>
      </Card>

      {pendingUser && (
        <RolePickerModal
          open={showRolePicker}
          userName={pendingUser.name}
          availableRoles={
            pendingUser.roles?.map((roleType: string) => {
              const roleMap = {
                'mesero': { type: 'mesero' as const, name: 'Mesero', icon: UserCheck, color: 'text-amber-600', bgColor: 'bg-amber-50' },
                'cocina': { type: 'cocina' as const, name: 'Cocinero', icon: ChefHat, color: 'text-orange-600', bgColor: 'bg-orange-50' },
                'admin': { type: 'admin' as const, name: 'Administrador', icon: Settings, color: 'text-green-600', bgColor: 'bg-green-50' },
                'cajero': { type: 'cajero' as const, name: 'Cajero', icon: Calculator, color: 'text-blue-600', bgColor: 'bg-blue-50' },
                'capitan': { type: 'capitan' as const, name: 'Capitán', icon: ShieldCheck, color: 'text-purple-600', bgColor: 'bg-purple-50' },
              };
              return roleMap[roleType];
            }) || []
          }
          onRoleSelected={handleRoleSelected}
          rememberRole={rememberRole}
          onRememberChange={setRememberRole}
        />
      )}
    </div>
  );
}
