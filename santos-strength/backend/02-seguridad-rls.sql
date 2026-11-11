-- ============================================================
--  Archivo 2 de 3: SEGURIDAD (Row Level Security + Storage)
--  Pégalo DESPUÉS del archivo 1. SQL Editor → Run.
--  Reglas: cada quien solo toca lo de su sitio; tú (gestor) ves todo;
--  la web pública solo puede LEER contenido, nunca escribir.
-- ============================================================

-- ---- Funciones de ayuda (saben quién eres por tu login) ----
create or replace function public.mi_sitio()
returns uuid language sql stable security definer set search_path = public as $$
  select sitio_id from public.perfiles where id = auth.uid() and activo;
$$;

create or replace function public.mi_rol()
returns text language sql stable security definer set search_path = public as $$
  select rol from public.perfiles where id = auth.uid() and activo;
$$;

create or replace function public.es_gestor()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfiles
                 where id = auth.uid() and rol = 'gestor' and activo);
$$;

-- ---- Activar RLS en todo ----
alter table public.sitios            enable row level security;
alter table public.perfiles          enable row level security;
alter table public.contenido         enable row level security;
alter table public.actividad         enable row level security;
alter table public.clientes_agencia  enable row level security;

-- ---- SITIOS ----
drop policy if exists sitios_ver on public.sitios;
create policy sitios_ver on public.sitios for select
  using ( true );                              -- la web pública necesita leerlos
drop policy if exists sitios_gestor on public.sitios;
create policy sitios_gestor on public.sitios for all
  using ( public.es_gestor() ) with check ( public.es_gestor() );

-- ---- PERFILES ----
drop policy if exists perfiles_ver on public.perfiles;
create policy perfiles_ver on public.perfiles for select
  using ( id = auth.uid()                       -- mi propia ficha
          or public.es_gestor()                 -- tú ves todas
          or ( sitio_id = public.mi_sitio() and public.mi_rol() = 'admin' ) );
drop policy if exists perfiles_gestionar on public.perfiles;
create policy perfiles_gestionar on public.perfiles for all
  using ( public.es_gestor()
          or ( sitio_id = public.mi_sitio() and public.mi_rol() = 'admin' ) )
  with check ( public.es_gestor()
          or ( sitio_id = public.mi_sitio() and public.mi_rol() = 'admin' ) );

-- ---- CONTENIDO ----  (lectura pública; escritura solo del equipo del sitio)
drop policy if exists contenido_leer on public.contenido;
create policy contenido_leer on public.contenido for select
  using ( true );
drop policy if exists contenido_escribir on public.contenido;
create policy contenido_escribir on public.contenido for all
  to authenticated
  using ( public.es_gestor() or sitio_id = public.mi_sitio() )
  with check ( public.es_gestor() or sitio_id = public.mi_sitio() );

-- ---- ACTIVIDAD ----
drop policy if exists actividad_ver on public.actividad;
create policy actividad_ver on public.actividad for select
  to authenticated
  using ( public.es_gestor() or sitio_id = public.mi_sitio() );
drop policy if exists actividad_crear on public.actividad;
create policy actividad_crear on public.actividad for insert
  to authenticated
  with check ( public.es_gestor() or sitio_id = public.mi_sitio() );

-- ---- CLIENTES_AGENCIA ----  (SOLO tú)
drop policy if exists clientes_solo_gestor on public.clientes_agencia;
create policy clientes_solo_gestor on public.clientes_agencia for all
  using ( public.es_gestor() ) with check ( public.es_gestor() );

-- ---- STORAGE (fotos y videos) ----
-- Crea el bucket público 'medios'. Cada archivo va en una carpeta por sitio:
--   <sitio_id>/<archivo>.  Lectura pública; subir/borrar solo el equipo del sitio.
insert into storage.buckets (id, name, public)
values ('medios','medios', true)
on conflict (id) do nothing;

drop policy if exists medios_leer on storage.objects;
create policy medios_leer on storage.objects for select
  using ( bucket_id = 'medios' );

drop policy if exists medios_subir on storage.objects;
create policy medios_subir on storage.objects for insert
  to authenticated
  with check ( bucket_id = 'medios'
    and ( public.es_gestor()
          or (storage.foldername(name))[1] = public.mi_sitio()::text ) );

drop policy if exists medios_borrar on storage.objects;
create policy medios_borrar on storage.objects for delete
  to authenticated
  using ( bucket_id = 'medios'
    and ( public.es_gestor()
          or (storage.foldername(name))[1] = public.mi_sitio()::text ) );
