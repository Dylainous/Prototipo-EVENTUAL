-- ==========================================
-- SCRIPT SQL - App Eventual
-- Club de Suboficiales - Supabase/PostgreSQL
-- ==========================================
-- Ejecutar en el SQL Editor de Supabase

-- ==========================================
-- TABLA DE ROLES
-- ==========================================
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO roles (nombre) VALUES
    ('Socio'),
    ('Presidente'),
    ('Secretario'),
    ('Tesorero');

-- ==========================================
-- TABLA DE PERFILES
-- Complementa auth.users de Supabase
-- ==========================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    cedula VARCHAR(10) NOT NULL UNIQUE,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(15),
    direccion TEXT,
    fecha_ingreso DATE NOT NULL DEFAULT CURRENT_DATE,
    rol_id INTEGER NOT NULL
        REFERENCES roles(id),
    estado VARCHAR(20) NOT NULL DEFAULT 'Activo'
        CHECK (estado IN ('Activo', 'Inactivo')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==========================================
-- TABLA DE PROPUESTAS DE EVENTOS
-- ==========================================
CREATE TABLE propuestas_evento (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    socio_id UUID NOT NULL
        REFERENCES profiles(id),
    tipo_evento VARCHAR(20) NOT NULL
        CHECK (tipo_evento IN ('Social', 'Deportivo')),
    descripcion TEXT NOT NULL,
    fecha_sugerida DATE NOT NULL,
    justificacion TEXT NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Pendiente'
        CHECK (estado IN ('Pendiente', 'Aprobada', 'Rechazada')),
    numero_seguimiento VARCHAR(20) UNIQUE,
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==========================================
-- TABLA DE EVENTOS
-- Para el calendario
-- ==========================================
CREATE TABLE eventos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    propuesta_id UUID
        REFERENCES propuestas_evento(id),
    nombre VARCHAR(150) NOT NULL,
    tipo_evento VARCHAR(20) NOT NULL
        CHECK (tipo_evento IN ('Social', 'Deportivo')),
    descripcion TEXT,
    fecha DATE NOT NULL,
    hora TIME NOT NULL,
    lugar VARCHAR(150) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'Definido'
        CHECK (
            estado IN (
                'Definido',
                'Registrado',
                'Difundido',
                'Ejecutado',
                'Cerrado'
            )
        ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==========================================
-- ROW LEVEL SECURITY (RLS)
-- ==========================================
-- Habilitar RLS en todas las tablas
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE propuestas_evento ENABLE ROW LEVEL SECURITY;
ALTER TABLE eventos ENABLE ROW LEVEL SECURITY;

-- El backend usa service_role key (bypassa RLS automáticamente).
-- Estas políticas son para acceso directo desde Supabase client (si se usa).
-- Con service_role key del backend, no es necesario definirlas.

-- Política: cualquier usuario autenticado puede ver eventos
CREATE POLICY "eventos_select_authenticated"
ON eventos FOR SELECT
TO authenticated
USING (true);

-- Política: socios pueden ver sus propias propuestas
CREATE POLICY "propuestas_select_own"
ON propuestas_evento FOR SELECT
TO authenticated
USING (auth.uid() = socio_id);

-- ==========================================
-- DATOS DE PRUEBA (opcional)
-- ==========================================
-- Para probar el calendario, insertar eventos de ejemplo
-- NOTA: Primero crear un usuario Presidente via el backend /api/members
-- y luego insertar eventos manualmente o via el sistema.

-- Ejemplo de evento de prueba (ajustar fechas según sea necesario):
/*
INSERT INTO eventos (nombre, tipo_evento, descripcion, fecha, hora, lugar, estado)
VALUES
    ('Reunión Mensual', 'Social', 'Reunión ordinaria del club', '2026-07-15', '19:00', 'Salón Principal', 'Definido'),
    ('Torneo de Fútbol', 'Deportivo', 'Torneo interno anual', '2026-07-22', '10:00', 'Cancha Deportiva', 'Definido'),
    ('Cena de Gala', 'Social', 'Celebración aniversario del club', '2026-08-05', '20:00', 'Salón de Eventos', 'Registrado');
*/
