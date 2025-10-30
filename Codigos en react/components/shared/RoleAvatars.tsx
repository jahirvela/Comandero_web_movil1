import React from 'react';
import logoImage from 'figma:asset/1fbc60f087d05875d90014246dd3d98bb2726ad3.png';

interface RoleAvatarProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const sizeClasses = {
  sm: 'w-8 h-8', // 32px for mobile
  md: 'w-9 h-9', // 36px for desktop
  lg: 'w-12 h-12' // 48px for larger contexts
};

// Colores por rol
const roleColors = {
  admin: 'bg-gradient-to-br from-green-500 to-green-600',
  mesero: 'bg-gradient-to-br from-amber-500 to-amber-600', 
  cajero: 'bg-gradient-to-br from-blue-500 to-blue-600',
  cocina: 'bg-gradient-to-br from-orange-500 to-orange-600',
  capitan: 'bg-gradient-to-br from-purple-500 to-purple-600'
};

export function AvatarAdmin({ size = 'md', className = '' }: RoleAvatarProps) {
  return (
    <div className={`${sizeClasses[size]} ${roleColors.admin} rounded-full flex items-center justify-center shadow-md ${className}`}>
      <img 
        src={logoImage}
        alt="Admin Avatar"
        className="w-3/4 h-3/4 object-contain"
      />
    </div>
  );
}

export function AvatarMesero({ size = 'md', className = '' }: RoleAvatarProps) {
  return (
    <div className={`${sizeClasses[size]} ${roleColors.mesero} rounded-full flex items-center justify-center shadow-md ${className}`}>
      <img 
        src={logoImage}
        alt="Mesero Avatar"
        className="w-3/4 h-3/4 object-contain"
      />
    </div>
  );
}

export function AvatarCajero({ size = 'md', className = '' }: RoleAvatarProps) {
  return (
    <div className={`${sizeClasses[size]} ${roleColors.cajero} rounded-full flex items-center justify-center shadow-md ${className}`}>
      <img 
        src={logoImage}
        alt="Cajero Avatar"
        className="w-3/4 h-3/4 object-contain"
      />
    </div>
  );
}

export function AvatarCocina({ size = 'md', className = '' }: RoleAvatarProps) {
  return (
    <div className={`${sizeClasses[size]} ${roleColors.cocina} rounded-full flex items-center justify-center shadow-md ${className}`}>
      <img 
        src={logoImage}
        alt="Cocina Avatar"
        className="w-3/4 h-3/4 object-contain"
      />
    </div>
  );
}

export function AvatarCapitan({ size = 'md', className = '' }: RoleAvatarProps) {
  return (
    <div className={`${sizeClasses[size]} ${roleColors.capitan} rounded-full flex items-center justify-center shadow-md ${className}`}>
      <img 
        src={logoImage}
        alt="Capitán Avatar"
        className="w-3/4 h-3/4 object-contain"
      />
    </div>
  );
}