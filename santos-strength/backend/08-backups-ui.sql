-- ============================================================
--  08 · Permisos para gestionar backups desde el Gestor
--  (crear una copia al instante y borrar copias viejas)
--  Corre este archivo en Supabase → SQL Editor → RUN.
--  Necesita que ya hayas corrido el 07-backup.sql.
-- ============================================================

-- Dejar que el gestor cree una copia al instante (llamar hacer_backup()).
grant execute on function public.hacer_backup() to authenticated;

-- Dejar que el gestor borre copias (para ahorrar espacio).
drop policy if exists "gestor borra backups" on public.backups;
create policy "gestor borra backups" on public.backups
  for delete using (public.es_gestor());
