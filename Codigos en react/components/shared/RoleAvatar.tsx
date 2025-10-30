import React from 'react';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface RoleAvatarProps {
  role: 'admin' | 'cajero' | 'cocina' | 'capitan' | 'mesero' | 'placeholder';
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const roleImages = {
  admin: 'https://images.unsplash.com/photo-1745559734544-7a1f023812fa?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyZXN0YXVyYW50JTIwbWFuYWdlciUyMGFkbWluJTIwcHJvZmVzc2lvbmFsfGVufDF8fHx8MTc1ODIzNTcwM3ww&ixlib=rb-4.1.0&q=80&w=1080',
  cajero: 'https://images.unsplash.com/photo-1579236215220-7f50f72152d6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYXNoaWVyJTIwcmVzdGF1cmFudCUyMHByb2Zlc3Npb25hbHxlbnwxfHx8fDE3NTgyMzU3MDN8MA&ixlib=rb-4.1.0&q=80&w=1080',
  cocina: 'https://images.unsplash.com/photo-1704895291329-a70e49f8b879?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaGVmJTIwa2l0Y2hlbiUyMGNvb2slMjBwcm9mZXNzaW9uYWx8ZW58MXx8fHwxNzU4MjM1NzA0fDA&ixlib=rb-4.1.0&q=80&w=1080',
  capitan: 'https://images.unsplash.com/photo-1713965588378-4771f415f2f7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxyZXN0YXVyYW50JTIwY2FwdGFpbiUyMHdhaXRlciUyMHByb2Zlc3Npb25hbHxlbnwxfHx8fDE3NTgyMzU3MDR8MA&ixlib=rb-4.1.0&q=80&w=1080',
  mesero: 'https://images.unsplash.com/photo-1713965588378-4771f415f2f7?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3YWl0ZXIlMjBzZXJ2ZXIlMjByZXN0YXVyYW50JTIwcHJvZmVzc2lvbmFsfGVufDF8fHx8MTc1ODIzNTcwNHww&ixlib=rb-4.1.0&q=80&w=1080',
  placeholder: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMjAiIGZpbGw9IiNGM0U4RDgiLz4KPHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeD0iOCIgeT0iOCI+CjxwYXRoIGQ9Ik0yMCAyMXYtMmE0IDQgMCAwIDAtNC00SDhhNCA0IDAgMCAwLTQgNHYyIiBzdHJva2U9IiM4RDZFNjMiIHN0cm9rZS13aWR0aD0iMiIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIi8+CjxjaXJjbGUgY3g9IjEyIiBjeT0iNyIgcj0iNCIgc3Ryb2tlPSIjOEQ2RTYzIiBzdHJva2Utd2lkdGg9IjIiLz4KPC9zdmc+Cjwvc3ZnPgo='
};

const sizeClasses = {
  sm: 'w-5 h-5', // 20x20
  md: 'w-8 h-8', // 32x32
  lg: 'w-14 h-14', // 56x56
  xl: 'w-20 h-20' // 80x80
};

const borderRadiusClasses = {
  sm: 'rounded-full',
  md: 'rounded-full',
  lg: 'rounded-lg',
  xl: 'rounded-lg'
};

const roleNames = {
  admin: 'Administrador',
  cajero: 'Cajero',
  cocina: 'Cocina',
  capitan: 'Capitán',
  mesero: 'Mesero',
  placeholder: 'Usuario'
};

export function RoleAvatar({ role, size = 'md', className = '' }: RoleAvatarProps) {
  const sizeClass = sizeClasses[size];
  const borderClass = borderRadiusClasses[size];
  const imageUrl = roleImages[role];
  const altText = `Avatar ${roleNames[role]}`;
  
  return (
    <div className={`${sizeClass} ${borderClass} overflow-hidden shadow-sm border border-border ${className}`}>
      <ImageWithFallback
        src={imageUrl}
        alt={altText}
        className="w-full h-full object-cover"
      />
    </div>
  );
}