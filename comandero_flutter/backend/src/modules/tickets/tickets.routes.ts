import { Router } from 'express';
import { imprimirTicketHandler, listarTicketsHandler } from './tickets.controller.js';
import { authenticate } from '../../middlewares/authentication.js';
import { requireRoles } from '../../middlewares/authorization.js';

const ticketsRouter = Router();

// GET /api/tickets
// Listar todos los tickets
ticketsRouter.get(
  '/',
  authenticate,
  requireRoles('administrador', 'cajero', 'capitan', 'mesero'),
  listarTicketsHandler
);

// POST /api/tickets/imprimir
// Cajero, admin y capitan pueden imprimir tickets
ticketsRouter.post(
  '/imprimir',
  authenticate,
  requireRoles('administrador', 'cajero', 'capitan'),
  imprimirTicketHandler
);

export default ticketsRouter;

