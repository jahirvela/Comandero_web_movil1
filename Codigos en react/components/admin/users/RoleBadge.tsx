import { Badge } from "../../ui/badge";
import { UserRole } from "./mockUsers";

interface RoleBadgeProps {
  role: UserRole;
  className?: string;
}

const roleStyles: Record<UserRole, { bg: string; text: string }> = {
  Mesero: { bg: 'bg-blue-100 hover:bg-blue-100', text: 'text-blue-700' },
  Cocinero: { bg: 'bg-orange-100 hover:bg-orange-100', text: 'text-orange-700' },
  Capitán: { bg: 'bg-purple-100 hover:bg-purple-100', text: 'text-purple-700' },
  Cajero: { bg: 'bg-green-100 hover:bg-green-100', text: 'text-green-700' },
  Administrador: { bg: 'bg-slate-700 hover:bg-slate-700', text: 'text-white' },
};

export function RoleBadge({ role, className = '' }: RoleBadgeProps) {
  const styles = roleStyles[role];
  
  return (
    <Badge
      variant="secondary"
      className={`${styles.bg} ${styles.text} ${className}`}
    >
      {role}
    </Badge>
  );
}
