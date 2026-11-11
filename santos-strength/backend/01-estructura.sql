-- ============================================================
--  SANTOS / AGENCIA — Backend real (Supabase / PostgreSQL)
--  Archivo 1 de 3: ESTRUCTURA (tablas)
--  Pégalo en Supabase → SQL Editor → New query → Run.
--  Multi-cliente: una sola base para todas las webs que crees.
-- ============================================================

-- Cada web/cliente es un "sitio".
create table if not exists public.sitios (
  id        uuid primary key default gen_random_uuid(),
  slug      text unique not null,                 -- ej: 'santos-strength'
  negocio   text not null,
  activo    boolean not null default true,
  creado    timestamptz not null default now()
);

-- Usuarios del sistema (ligados al login de Supabase Auth).
-- rol 'gestor' = tú (agencia, ve todo). Los demás pertenecen a un sitio.
create table if not exists public.perfiles (
  id        uuid primary key references auth.users on delete cascade,
  sitio_id  uuid references public.sitios on delete cascade,
  nombre    text not null default '',
  rol       text not null default 'recepcion'
            check (rol in ('gestor','admin','recepcion','cafetin')),
  sede      text not null default 'todas',
  activo    boolean not null default true,
  creado    timestamptz not null default now()
);

-- Contenido de cada web, por clave (config, sedes, planes, entrenadores,
-- cafetin, publicaciones, galeria, pase, notaPlanes...). Mismo formato
-- que usa la web hoy, guardado como JSON. Lectura pública (es una web).
create table if not exists public.contenido (
  sitio_id    uuid not null references public.sitios on delete cascade,
  clave       text not null,
  valor       jsonb not null default '{}'::jsonb,
  actualizado timestamptz not null default now(),
  primary key (sitio_id, clave)
);

-- Bitácora de actividad del equipo de cada sitio (quién hizo qué).
create table if not exists public.actividad (
  id       bigint generated always as identity primary key,
  sitio_id uuid not null references public.sitios on delete cascade,
  quien    text not null default '',
  que      text not null default '',
  t        timestamptz not null default now()
);
create index if not exists actividad_sitio_idx on public.actividad (sitio_id, t desc);

-- Cartera de la agencia: SOLO para ti (rol gestor). Costos, soporte,
-- contactos y versiones de cada cliente. Esto alimenta tu Panel Gestor.
create table if not exists public.clientes_agencia (
  id        uuid primary key default gen_random_uuid(),
  sitio_id  uuid references public.sitios on delete set null,
  negocio   text not null,
  rubro     text default '',
  estado    text default 'activo' check (estado in ('activo','soporte','pausado','baja')),
  contacto  text default '',
  telefono  text default '',
  url       text default '',
  panel     text default '',
  costo     numeric default 0,
  soporte   numeric default 0,
  pago      text default 'pendiente' check (pago in ('pendiente','pagado')),
  ciclo     text default 'mensual' check (ciclo in ('mensual','anual','unico','ninguno')),
  entregado date,
  notas     text default '',
  versiones jsonb not null default '[]'::jsonb,
  creado    timestamptz not null default now()
);

-- Mantiene 'actualizado' al día en cada cambio de contenido.
create or replace function public.tocar_contenido()
returns trigger language plpgsql as $$
begin new.actualizado := now(); return new; end; $$;
drop trigger if exists trg_tocar_contenido on public.contenido;
create trigger trg_tocar_contenido before update on public.contenido
  for each row execute function public.tocar_contenido();
