import React from 'react';
import logoImage from 'figma:asset/44551df3d711106118c9c4d0d5f3e15d89c88c93.png';

interface ProjectSmallProps {
  className?: string;
  mobile?: boolean;
}

export function ProjectSmall({ className = '', mobile = false }: ProjectSmallProps) {
  const size = mobile ? 'w-7 h-7' : 'w-8 h-8'; // 28px mobile, 32px desktop
  
  return (
    <img 
      src={logoImage}
      alt="Comandix Logo"
      className={`${size} object-contain ${className}`}
    />
  );
}