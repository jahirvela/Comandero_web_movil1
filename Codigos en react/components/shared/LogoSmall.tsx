import React from 'react';
import logoImage from 'figma:asset/1fbc60f087d05875d90014246dd3d98bb2726ad3.png';

interface LogoSmallProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const sizeClasses = {
  sm: 'w-7 h-7', // 28px for mobile
  md: 'w-8 h-8', // 32px for desktop headers
  lg: 'w-10 h-10' // 40px for larger contexts
};

export function LogoSmall({ size = 'md', className = '' }: LogoSmallProps) {
  return (
    <div className={`${sizeClasses[size]} flex items-center justify-center ${className}`}>
      <img 
        src={logoImage}
        alt="Comandix Logo"
        className="w-full h-full object-contain"
      />
    </div>
  );
}