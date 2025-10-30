import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { Badge } from './ui/badge';

interface CriticalNotesProps {
  notes: string;
  className?: string;
}

const CRITICAL_KEYWORDS = [
  'alergia', 'alérgico', 'alérgica', 'alergico', 'alergica',
  'sin', 'no', 'diabético', 'diabética', 'diabetico', 'diabetica',
  'celíaco', 'celíaca', 'celiaco', 'celiaca',
  'vegetariano', 'vegetariana', 'vegano', 'vegana',
  'hipertensión', 'hipertenso', 'hipertensa',
  'especial', 'importante', 'cuidado', 'atención'
];

export function CriticalNotes({ notes, className = '' }: CriticalNotesProps) {
  if (!notes || notes.trim().length === 0) {
    return null;
  }

  // Verificar si contiene palabras críticas
  const hasCriticalKeywords = CRITICAL_KEYWORDS.some(keyword =>
    notes.toLowerCase().includes(keyword.toLowerCase())
  );

  // Resaltar palabras críticas en el texto
  const highlightCriticalWords = (text: string) => {
    let highlightedText = text;
    
    CRITICAL_KEYWORDS.forEach(keyword => {
      const regex = new RegExp(`(${keyword})`, 'gi');
      highlightedText = highlightedText.replace(
        regex, 
        '<span class="bg-red-200 text-red-800 font-medium px-1 rounded">$1</span>'
      );
    });

    return highlightedText;
  };

  if (!hasCriticalKeywords) {
    // Nota normal
    return (
      <div className={`p-2 bg-yellow-50 border border-yellow-200 rounded-md ${className}`}>
        <div className="flex items-start gap-2">
          <span className="text-yellow-600 text-sm font-medium">Nota:</span>
          <span className="text-sm text-yellow-800">{notes}</span>
        </div>
      </div>
    );
  }

  // Nota crítica
  return (
    <div className={`p-3 bg-red-50 border-2 border-red-200 rounded-md ${className}`}>
      <div className="flex items-start gap-2 mb-2">
        <AlertTriangle className="h-4 w-4 text-red-600 mt-0.5 flex-shrink-0" />
        <Badge variant="destructive" className="text-xs">
          Nota crítica
        </Badge>
      </div>
      <div 
        className="text-sm text-red-800 leading-relaxed"
        dangerouslySetInnerHTML={{ 
          __html: highlightCriticalWords(notes) 
        }}
      />
      <div className="mt-2 text-xs text-red-600 font-medium">
        ⚠️ Mostrar siempre
      </div>
    </div>
  );
}

export default CriticalNotes;