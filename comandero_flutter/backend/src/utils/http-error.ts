export class HttpError extends Error {
  status: number;
  code?: string;
  details?: unknown;

  constructor(status: number, message: string, options?: { code?: string; details?: unknown }) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
    this.code = options?.code;
    this.details = options?.details;
  }
}

export const badRequest = (message: string, details?: unknown) =>
  new HttpError(400, message, { code: 'bad_request', details });

export const unauthorized = (message = 'No autorizado') =>
  new HttpError(401, message, { code: 'unauthorized' });

export const forbidden = (message = 'Acceso prohibido') =>
  new HttpError(403, message, { code: 'forbidden' });

export const notFound = (message = 'Recurso no encontrado') =>
  new HttpError(404, message, { code: 'not_found' });

export const conflict = (message: string, details?: unknown) =>
  new HttpError(409, message, { code: 'conflict', details });

