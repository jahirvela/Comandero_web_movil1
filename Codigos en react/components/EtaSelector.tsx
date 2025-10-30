import React, { useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from './ui/dialog';
import { Button } from './ui/button';
import { Badge } from './ui/badge';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { RadioGroup, RadioGroupItem } from './ui/radio-group';
import { Clock } from 'lucide-react';

interface EtaSelectorProps {
  currentEta: number;
  orderId: string;
  onUpdateEta: (orderId: string, newEta: number) => void;
}

export function EtaSelector({ currentEta, orderId, onUpdateEta }: EtaSelectorProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [selectedOption, setSelectedOption] = useState('');
  const [customMinutes, setCustomMinutes] = useState('');

  const quickOptions = [
    { value: '5', label: '5 min' },
    { value: '15', label: '15 min' },
    { value: '30', label: '30 min' },
    { value: '45', label: '45 min' },
    { value: '60', label: '1 h' }
  ];

  const handleSubmit = () => {
    let newEta = currentEta;
    
    if (selectedOption === 'custom' && customMinutes) {
      newEta = parseInt(customMinutes);
    } else if (selectedOption && selectedOption !== 'custom') {
      newEta = parseInt(selectedOption);
    }

    if (newEta && newEta > 0 && newEta !== currentEta) {
      onUpdateEta(orderId, newEta);
    }
    
    handleClose();
  };

  const handleClose = () => {
    setIsOpen(false);
    setSelectedOption('');
    setCustomMinutes('');
  };

  const formatEtaDisplay = (minutes: number) => {
    if (minutes >= 60) {
      const hours = Math.floor(minutes / 60);
      const remainingMinutes = minutes % 60;
      if (remainingMinutes === 0) {
        return `${hours}h`;
      }
      return `${hours}h ${remainingMinutes}min`;
    }
    return `${minutes} min`;
  };

  return (
    <Dialog open={isOpen} onOpenChange={setIsOpen}>
      <DialogTrigger asChild>
        <Button 
          variant="outline" 
          size="sm" 
          className="bg-blue-50 border-blue-200 text-blue-700 hover:bg-blue-100"
        >
          <Clock className="h-3 w-3 mr-1" />
          {formatEtaDisplay(currentEta)}
        </Button>
      </DialogTrigger>
      
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Modificar tiempo de salida (ETA)</DialogTitle>
          <DialogDescription>
            Actualiza el tiempo estimado de salida para esta orden
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">

          <div className="space-y-3">
            <Label>Opciones rápidas</Label>
            <RadioGroup value={selectedOption} onValueChange={setSelectedOption}>
              {quickOptions.map(option => (
                <div key={option.value} className="flex items-center space-x-2">
                  <RadioGroupItem value={option.value} id={option.value} />
                  <Label htmlFor={option.value}>{option.label}</Label>
                </div>
              ))}
              <div className="flex items-center space-x-2">
                <RadioGroupItem value="custom" id="custom" />
                <Label htmlFor="custom">Personalizado</Label>
              </div>
            </RadioGroup>
          </div>

          {selectedOption === 'custom' && (
            <div className="space-y-2">
              <Label htmlFor="customMinutes">Minutos</Label>
              <Input
                id="customMinutes"
                type="number"
                min="1"
                max="999"
                value={customMinutes}
                onChange={(e) => setCustomMinutes(e.target.value)}
                placeholder="Ej: 25"
              />
            </div>
          )}

          <div className="flex gap-2 pt-4">
            <Button variant="outline" onClick={handleClose} className="flex-1">
              Cancelar
            </Button>
            <Button 
              onClick={handleSubmit} 
              className="flex-1"
              disabled={!selectedOption || (selectedOption === 'custom' && !customMinutes)}
            >
              Actualizar ETA
            </Button>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}