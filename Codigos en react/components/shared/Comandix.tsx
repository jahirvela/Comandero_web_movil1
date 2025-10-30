import React from 'react';

interface ComandixLogoProps {
  width?: number;
  height?: number;
  className?: string;
}

export function Comandix({ width = 32, height = 32, className = '' }: ComandixLogoProps) {
  return (
    <svg
      width={width}
      height={height}
      viewBox="0 0 32 32"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
    >
      <defs>
        <linearGradient id="fireGradient1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#FF6B35" />
          <stop offset="50%" stopColor="#F7931E" />
          <stop offset="100%" stopColor="#FF4500" />
        </linearGradient>
        <linearGradient id="fireGradient2" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#FFB366" />
          <stop offset="50%" stopColor="#FF8C42" />
          <stop offset="100%" stopColor="#FF6B35" />
        </linearGradient>
      </defs>
      
      {/* Forma principal del fuego */}
      <path
        d="M16 2C10 2 8 8 8 12c0 2 1 4 2 5.5C11 19 12 20 12 22c0 3 2 6 4 6s4-3 4-6c0-2 1-3 2-4.5 1-1.5 2-3.5 2-5.5 0-4-2-10-8-10z"
        fill="url(#fireGradient1)"
      />
      
      {/* Llama interna */}
      <path
        d="M16 6c-3 0-4 3-4 5.5 0 1.5 0.5 2.5 1 3.5 0.5 1 1 1.5 1 2.5 0 2 1 3.5 2 3.5s2-1.5 2-3.5c0-1 0.5-1.5 1-2.5 0.5-1 1-2 1-3.5 0-2.5-1-5.5-4-5.5z"
        fill="url(#fireGradient2)"
      />
      
      {/* Punto de luz central */}
      <ellipse
        cx="16"
        cy="18"
        rx="3"
        ry="4"
        fill="#FFFFFF"
        opacity="0.3"
      />
      
      {/* Curva característica tipo "C" */}
      <path
        d="M20 14c2 0 3-1 3-3 0-1-0.5-2-1.5-2.5"
        stroke="url(#fireGradient1)"
        strokeWidth="1.5"
        fill="none"
        strokeLinecap="round"
      />
    </svg>
  );
}