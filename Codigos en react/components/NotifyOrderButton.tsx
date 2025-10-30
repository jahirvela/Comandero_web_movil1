import React, { useState } from 'react';
import { Button } from './ui/button';
import { Bell } from 'lucide-react';

interface NotifyOrderButtonProps {
  orderId: string;
  onNotify: (orderId: string) => void;
  size?: 'sm' | 'default';
  variant?: 'default' | 'outline';
}

export function NotifyOrderButton({ orderId, onNotify, size = 'sm', variant = 'outline' }: NotifyOrderButtonProps) {
  const [status, setStatus] = useState<'default' | 'sending' | 'sent'>('default');

  const handleClick = async () => {
    setStatus('sending');
    try {
      await onNotify(orderId);
      setStatus('sent');
      setTimeout(() => setStatus('default'), 3000);
    } catch (error) {
      setStatus('default');
    }
  };

  const getButtonText = () => {
    switch (status) {
      case 'sending':
        return 'Enviando...';
      case 'sent':
        return 'Notificado';
      default:
        return 'Notificar a Cocina';
    }
  };

  const getButtonVariant = () => {
    if (status === 'sent') return 'default';
    return variant;
  };

  return (
    <Button
      variant={getButtonVariant()}
      size={size}
      onClick={handleClick}
      disabled={status === 'sending' || status === 'sent'}
      className={status === 'sent' ? 'bg-green-600 hover:bg-green-700' : ''}
    >
      <Bell className="h-3 w-3 mr-1" />
      {getButtonText()}
    </Button>
  );
}