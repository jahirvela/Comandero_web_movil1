import React from 'react';
import { Card, CardContent } from '../../ui/card';
import { DollarSign, CreditCard, Star, TrendingUp } from 'lucide-react';

interface ClosureSummaryData {
  totalNeto: number;
  efectivo: number;
  tarjeta: number;
  propinasTarjeta: number;
  propinasEfectivo: number;
  pedidosParaLlevar: number;
}

interface ClosureSummaryCardsProps {
  data: ClosureSummaryData;
}

export function ClosureSummaryCards({ data }: ClosureSummaryCardsProps) {
  const cards = [
    {
      title: 'Efectivo',
      value: data.efectivo,
      icon: DollarSign,
      bgColor: 'bg-green-50',
      borderColor: 'border-green-200',
      textColor: 'text-green-800',
      iconColor: 'text-green-600'
    },
    {
      title: 'Tarjeta',
      value: data.tarjeta,
      icon: CreditCard,
      bgColor: 'bg-blue-50',
      borderColor: 'border-blue-200',
      textColor: 'text-blue-800',
      iconColor: 'text-blue-600'
    },
    {
      title: 'Propinas (Tarjeta)',
      value: data.propinasTarjeta,
      icon: Star,
      bgColor: 'bg-purple-50',
      borderColor: 'border-purple-200',
      textColor: 'text-purple-800',
      iconColor: 'text-purple-600'
    },
    {
      title: 'Propinas (Efectivo)',
      value: data.propinasEfectivo,
      icon: Star,
      bgColor: 'bg-amber-50',
      borderColor: 'border-amber-200',
      textColor: 'text-amber-800',
      iconColor: 'text-amber-600'
    },
    {
      title: 'Pedidos Para llevar',
      value: data.pedidosParaLlevar,
      icon: TrendingUp,
      bgColor: 'bg-indigo-50',
      borderColor: 'border-indigo-200',
      textColor: 'text-indigo-800',
      iconColor: 'text-indigo-600'
    },
    {
      title: 'Total Neto',
      value: data.totalNeto,
      icon: DollarSign,
      bgColor: 'bg-gray-50',
      borderColor: 'border-gray-200',
      textColor: 'text-gray-800',
      iconColor: 'text-gray-600'
    }
  ];

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4 mb-6">
      {cards.map((card, index) => {
        const IconComponent = card.icon;
        return (
          <Card key={index} className={`${card.bgColor} ${card.borderColor}`}>
            <CardContent className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className={`text-sm ${card.textColor} opacity-80`}>
                    {card.title}
                  </p>
                  <p className={`text-xl font-medium ${card.textColor}`}>
                    ${card.value.toFixed(2)}
                  </p>
                </div>
                <IconComponent className={`h-6 w-6 ${card.iconColor}`} />
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
}