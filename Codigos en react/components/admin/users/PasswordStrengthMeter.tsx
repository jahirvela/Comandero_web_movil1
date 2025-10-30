import { Progress } from "../../ui/progress";

interface PasswordStrengthMeterProps {
  password: string;
}

export function PasswordStrengthMeter({ password }: PasswordStrengthMeterProps) {
  const getStrength = (pwd: string): { score: number; label: string; color: string } => {
    if (!pwd) return { score: 0, label: '', color: '' };
    
    let score = 0;
    
    // Length
    if (pwd.length >= 8) score += 25;
    if (pwd.length >= 12) score += 10;
    
    // Contains lowercase
    if (/[a-z]/.test(pwd)) score += 15;
    
    // Contains uppercase
    if (/[A-Z]/.test(pwd)) score += 15;
    
    // Contains numbers
    if (/[0-9]/.test(pwd)) score += 15;
    
    // Contains special characters
    if (/[^a-zA-Z0-9]/.test(pwd)) score += 20;
    
    if (score < 40) return { score, label: 'Débil', color: 'bg-red-500' };
    if (score < 70) return { score, label: 'Media', color: 'bg-yellow-500' };
    return { score, label: 'Fuerte', color: 'bg-green-500' };
  };
  
  const strength = getStrength(password);
  
  if (!password) return null;
  
  return (
    <div className="space-y-2">
      <div className="relative">
        <Progress value={strength.score} className="h-2" />
        <div 
          className={`absolute inset-0 h-2 rounded-full transition-all ${strength.color}`}
          style={{ width: `${strength.score}%` }}
        />
      </div>
      <p className="text-sm text-muted-foreground">
        Fuerza de contraseña: <span className="font-medium">{strength.label}</span>
      </p>
    </div>
  );
}
