import React from 'react';
import { UserCheck, ChefHat, Settings, Calculator, ShieldCheck } from 'lucide-react';

interface RoleIconProps {
  className?: string;
  size?: 'sm' | 'md' | 'lg';
}

const sizeClasses = {
  sm: 'h-4 w-4',
  md: 'h-5 w-5',
  lg: 'h-6 w-6'
};

export function MeseroIcon({ className = '', size = 'md' }: RoleIconProps) {
  return <UserCheck className={`${sizeClasses[size]} text-amber-600 ${className}`} />;
}

export function CocinaIcon({ className = '', size = 'md' }: RoleIconProps) {
  return <ChefHat className={`${sizeClasses[size]} text-orange-600 ${className}`} />;
}

export function AdminIcon({ className = '', size = 'md' }: RoleIconProps) {
  return <Settings className={`${sizeClasses[size]} text-green-600 ${className}`} />;
}

export function CajeroIcon({ className = '', size = 'md' }: RoleIconProps) {
  return <Calculator className={`${sizeClasses[size]} text-blue-600 ${className}`} />;
}

export function CapitanIcon({ className = '', size = 'md' }: RoleIconProps) {
  return <ShieldCheck className={`${sizeClasses[size]} text-purple-600 ${className}`} />;
}