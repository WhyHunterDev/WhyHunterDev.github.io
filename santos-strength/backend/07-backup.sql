-- ============================================================
--  07 · Backup automático semanal (gratis, dentro de Supabase)
--  Guarda una copia de TODO el contenido de las webs cada semana.
--  Corre este archivo en Supabase → SQL Editor → RUN.
--
--  Si la línea de "cron.schedule" da error, primero activa la
--  extensión: Dashboard → Database → Extensions → busca "pg_cron"
--  y actívala. Luego vuelve a correr este archivo.
-- ============================================================

-- Tabla donde se guardan las copias (con fecha).
create table if not exists public.backups (
  id      bigint generated always as identity primary key,
  creado  timestamptz not null default now(),
  sitio_id uuid,
  clave   text,
  valor   jsonb
);

alter table public.backups enable row level security;

drop policy if exists "gestor lee backups" on public.backups;
create policy "gestor lee backups" on public.backups
  for select using (public.es_gestor());

-- Función que copia el contenido actual a 'backups' y limpia lo viejo (>120 días).
create or replace function public.hacer_backup()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.backups (sitio_id, clave, valor)
  select sitio_id, clave, valor from public.contenido;
  delete from public.backups where creado < now() - interval '120 days';
end;
$$;

-- Programa el backup cada domingo 3:00 AM (hora del servidor).
create extension if not exists pg_cron;
select cron.unschedule('backup-semanal')
  where exists (select 1 from cron.job where jobname = 'backup-semanal');
select cron.schedule('backup-semanal', '0 3 * * 0', $$ select public.hacer_backup(); $$);

-- (Opcional) Haz un primer backup ahora mismo:
select public.hacer_backup();
