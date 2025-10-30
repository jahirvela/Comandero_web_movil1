import React from 'react';
import { LoginView } from '@components/LoginView';
import { MobileApp } from '@components/mobile/MobileApp';
import { AdminApp } from '@components/admin/AdminApp';
import { KitchenApp } from '@components/kitchen/KitchenApp';
import { CashierApp } from '@components/cashier/CashierApp';
import { CaptainApp } from '@components/captain/CaptainApp';

interface User {
  id: string;
  name: string;
  type: 'mesero' | 'cocina' | 'admin' | 'cajero' | 'capitan';
}

interface RouterProps {
  currentUser: User | null;
  onLogin: (user: User) => void;
  onLogout: () => void;
}

export function Router({ currentUser, onLogin, onLogout }: RouterProps) {
  if (!currentUser) {
    return <LoginView onLogin={onLogin} />;
  }

  // Renderizar la aplicación según el tipo de usuario
  switch (currentUser.type) {
    case 'mesero':
      return <MobileApp user={currentUser} onLogout={onLogout} />;
    
    case 'cocina':
      return <KitchenApp user={currentUser} onLogout={onLogout} />;
    
    case 'admin':
      return <AdminApp user={currentUser} onLogout={onLogout} />;
    
    case 'cajero':
      return <CashierApp user={currentUser} onLogout={onLogout} />;
    
    case 'capitan':
      return <CaptainApp user={currentUser} onLogout={onLogout} />;
    
    default:
      return <MobileApp user={currentUser} onLogout={onLogout} />;
  }
}
