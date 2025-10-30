import React from 'react';

interface IconProps {
  size?: number;
  className?: string;
}

// Logo C de fuego para Admin/Cocina
export function LogoC({ size = 32, className = '' }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      <defs>
        <linearGradient id="cLogoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#FF6B35" />
          <stop offset="50%" stopColor="#F7931E" />
          <stop offset="100%" stopColor="#FF4500" />
        </linearGradient>
      </defs>
      
      {/* Forma de C con fuego */}
      <path
        d="M16 4C10 4 6 8 6 14v4c0 6 4 10 10 10"
        stroke="url(#cLogoGradient)"
        strokeWidth="4"
        fill="none"
        strokeLinecap="round"
      />
      
      {/* Llamas decorativas */}
      <path
        d="M24 8c1.5 1 2 2.5 1.5 4M26 14c1 1.5 1 3 0 4.5M24 24c1.5-1 2-2.5 1.5-4"
        stroke="url(#cLogoGradient)"
        strokeWidth="2"
        fill="none"
        strokeLinecap="round"
      />
    </svg>
  );
}

// Icono calculadora para Cajero
export function CalculatorIcon({ size = 32, className = '' }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      <rect x="6" y="4" width="20" height="24" rx="2" fill="#1E40AF" stroke="#1E40AF" strokeWidth="1"/>
      <rect x="8" y="6" width="16" height="4" rx="1" fill="#FFFFFF"/>
      
      {/* Botones de la calculadora */}
      <circle cx="10" cy="14" r="1.5" fill="#FFFFFF"/>
      <circle cx="16" cy="14" r="1.5" fill="#FFFFFF"/>
      <circle cx="22" cy="14" r="1.5" fill="#FFFFFF"/>
      
      <circle cx="10" cy="18" r="1.5" fill="#FFFFFF"/>
      <circle cx="16" cy="18" r="1.5" fill="#FFFFFF"/>
      <circle cx="22" cy="18" r="1.5" fill="#FFFFFF"/>
      
      <circle cx="10" cy="22" r="1.5" fill="#FFFFFF"/>
      <circle cx="16" cy="22" r="1.5" fill="#FFFFFF"/>
      <rect x="20.5" y="20.5" width="3" height="3" rx="1" fill="#FFFFFF"/>
    </svg>
  );
}

// Icono naranja para Mesero
export function MeseroIcon({ size = 32, className = '' }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      <defs>
        <linearGradient id="meseroGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#FF8C42" />
          <stop offset="50%" stopColor="#FF6B35" />
          <stop offset="100%" stopColor="#FF4500" />
        </linearGradient>
      </defs>
      
      {/* Avatar circular */}
      <circle cx="16" cy="16" r="14" fill="url(#meseroGradient)"/>
      
      {/* Persona */}
      <circle cx="16" cy="12" r="4" fill="#FFFFFF"/>
      <path
        d="M8 26c0-4 3.5-7 8-7s8 3 8 7"
        fill="#FFFFFF"
      />
      
      {/* Detalles de mesero */}
      <path
        d="M12 10h8M14 8h4"
        stroke="#FF6B35"
        strokeWidth="1"
        strokeLinecap="round"
      />
    </svg>
  );
}

// Icono insignia para Capitán
export function CapitanIcon({ size = 32, className = '' }: IconProps) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      <defs>
        <linearGradient id="capitanGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#8B5CF6" />
          <stop offset="50%" stopColor="#7C3AED" />
          <stop offset="100%" stopColor="#6B46C1" />
        </linearGradient>
      </defs>
      
      {/* Insignia en forma de escudo */}
      <path
        d="M16 2L6 8v8c0 6 4 12 10 14 6-2 10-8 10-14V8L16 2z"
        fill="url(#capitanGradient)"
      />
      
      {/* Persona dentro del escudo */}
      <circle cx="16" cy="12" r="3" fill="#FFFFFF"/>
      <path
        d="M11 22c0-3 2-5 5-5s5 2 5 5"
        fill="#FFFFFF"
      />
      
      {/* Estrella de autoridad */}
      <path
        d="M16 6l1 2h2l-1.5 1.5L18 12l-2-1-2 1 .5-2.5L13 8h2l1-2z"
        fill="#FFD700"
      />
    </svg>
  );
}