# App Eventual — Club de Suboficiales

Prototipo de aplicación móvil con arquitectura cliente-servidor para la gestión de eventos del Club de Suboficiales.

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│  CLIENTE (Flutter / Dart)                           │
│  Clean Architecture: Data | Domain | Presentation   │
│  Patrones: BLoC, Observer, Strategy                 │
└─────────────────────────┬───────────────────────────┘
                          │ HTTP/REST (JWT)
┌─────────────────────────▼───────────────────────────┐
│  SERVIDOR (Node.js / Express)                       │
│  REST API con autenticación JWT                     │
└─────────────────────────┬───────────────────────────┘
                          │ Supabase JS Client
┌─────────────────────────▼───────────────────────────┐
│  BASE DE DATOS (PostgreSQL via Supabase)             │
│  roles | profiles | eventos | propuestas_evento     │
└─────────────────────────────────────────────────────┘
```

## Estructura del proyecto

```
proyecto_eventual/
├── backend/                   # Node.js + Express
│   ├── src/
│   │   ├── config/
│   │   │   └── supabase.js    # Cliente Supabase Admin
│   │   ├── controllers/
│   │   │   ├── authController.js
│   │   │   ├── membersController.js
│   │   │   ├── eventsController.js
│   │   │   └── proposalsController.js
│   │   ├── middleware/
│   │   │   ├── auth.js        # JWT authenticate + authorize
│   │   │   └── validation.js  # express-validator
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── members.js
│   │   │   ├── events.js
│   │   │   └── proposals.js
│   │   └── index.js           # Entry point Express
│   ├── .env.example
│   └── package.json
│
└── frontend/                  # Flutter + Dart
    ├── lib/
    │   ├── main.dart          # Entry point + rutas
    │   ├── core/
    │   │   ├── constants/     api_constants.dart
    │   │   ├── di/            injection.dart (get_it)
    │   │   ├── errors/        failures.dart
    │   │   ├── network/       api_client.dart
    │   │   └── utils/
    │   │       ├── observer.dart   ← PATRÓN OBSERVER
    │   │       └── strategy.dart   ← PATRÓN STRATEGY
    │   └── features/
    │       ├── auth/          CU-001 Acceso al software
    │       ├── members/       CU-002 Gestionar Miembros
    │       ├── events/        CU-003 Consultar Calendario
    │       ├── proposals/     CU-004 Proponer Evento
    │       └── home/          Navegación principal
    └── pubspec.yaml
```

## Patrones de Diseño

### Observer (`core/utils/observer.dart`)
- **AppEventBus** – singleton que permite suscribirse/emitir eventos de dominio sin acoplamiento.
- **Aplicado en:** `MembersBloc` (emite `MEMBER_UPDATED`, `MEMBER_DEACTIVATED`) y `ProposalsBloc` (emite `PROPOSAL_CREATED`).
- **Extensible para:** RF5 (Confirmar Asistencia) → `ATTENDANCE_CONFIRMED`.

### Strategy (`core/utils/strategy.dart`)
- **EventFilterStrategy** – interfaz con `buildParams()` y `label`.
- Estrategias concretas: `AllEventsStrategy`, `FilterByTypeStrategy`, `FilterByMonthStrategy`, `FilterByTypeAndMonthStrategy`.
- **Aplicado en:** `EventsBloc` y `CalendarPage` — el usuario cambia el filtro y se intercambia la estrategia en caliente sin modificar el BLoC.
- **Extensible para:** `FilterByConfirmedStrategy` en RF5.

## Requisitos Funcionales implementados

| RF | Caso de uso | Actor |
|----|-------------|-------|
| CU-001 | Acceso al software | Todos |
| CU-002 | Gestionar Miembros (agregar, asignar rol, modificar, desactivar) | Presidente |
| CU-003 | Consultar calendario de eventos | Todos |
| CU-004 | Proponer Evento | Socio |

## Endpoints REST

### Auth
| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/auth/login` | Autenticación con cédula + contraseña |

### Members (solo Presidente)
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/members` | Listar todos los socios |
| GET | `/api/members/roles` | Listar roles disponibles |
| POST | `/api/members` | Agregar nuevo socio |
| PUT | `/api/members/:id` | Modificar datos del socio |
| PATCH | `/api/members/:id/role` | Asignar rol |
| PATCH | `/api/members/:id/deactivate` | Desactivar socio |

### Events (todos autenticados)
| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/events?tipo=&year=&month=` | Calendario con filtros |
| GET | `/api/events/:id` | Detalle de un evento |

### Proposals (Socio)
| Método | Ruta | Descripción |
|--------|------|-------------|
| POST | `/api/proposals` | Enviar propuesta de evento |
| GET | `/api/proposals/mine` | Ver mis propuestas |

## Instalación y ejecución

### Backend
```bash
cd backend
cp .env.example .env
# Editar .env con tus credenciales de Supabase y JWT_SECRET
npm install
npm run dev
```

### Frontend
```bash
cd frontend
flutter pub get
# Editar lib/core/constants/api_constants.dart → baseUrl
flutter run
```

### Base de datos
Ejecutar el script SQL en el editor de Supabase (ver `database.sql`).

## Variables de entorno (backend/.env)
```
PORT=3000
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_SERVICE_KEY=tu_service_role_key
JWT_SECRET=tu_secreto_muy_largo_y_aleatorio
JWT_EXPIRES_IN=1h
```

> **Nota:** Usa la `service_role` key de Supabase (no la anon key) para que el backend pueda crear/gestionar usuarios en `auth.users`.
