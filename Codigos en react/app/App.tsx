import React, { useState } from 'react';
import { Router } from './router';
import { NotificationProvider } from '@context/NotificationContext';
import { MenuProvider } from '@context/MenuContext';
import '@styles/index.css';

// Definir tipos para el usuario
interface User {
  id: string;
  name: string;
  type: 'mesero' | 'cocina' | 'admin' | 'cajero' | 'capitan';
}

export default function App() {
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  const handleLogin = (userData: User): void => {
    setCurrentUser(userData);
  };

  const handleLogout = (): void => {
    setCurrentUser(null);
  };

  return (
    <MenuProvider>
      <NotificationProvider>
        <div className="min-h-screen bg-background">
          <Router 
            currentUser={currentUser}
            onLogin={handleLogin}
            onLogout={handleLogout}
          />
        </div>
      </NotificationProvider>
    </MenuProvider>
  );
}