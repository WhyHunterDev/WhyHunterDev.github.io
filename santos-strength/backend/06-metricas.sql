-- ============================================================
--  06 · Métricas (visitas y clics a WhatsApp)
--  Corre este archivo en Supabase → SQL Editor → RUN.
--  Gratis. No necesita nada más.
-- ============================================================

-- Tabla: un contador por sitio, día y tipo de evento.
create table if not exists public.metricas (
  sitio_id uuid not null references public.sitios(id) on delete cascade,
  dia      date not null default current_date,
  tipo     text not null,                 -- 'visita' | 'whatsapp'
  n        integer not null default 0,
  primary key (sitio_id, dia, tipo)
);

alter table public.metricas enable row level security;

-- Solo el gestor puede leer las métricas.
drop policy if exists "gestor lee metricas" on public.metricas;
create policy "gestor lee metricas" on public.metricas
  for select using (public.es_gestor());

-- RPC: registra un evento de forma anónima y segura (la web la llama sin login).
create or replace function public.registrar_evento(p_slug text, p_tipo text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_id uuid;
begin
  if p_tipo not in ('visita','whatsapp') then return; end if;
  select id into v_id from public.sitios where slug = p_slug;
  if v_id is null then return; end if;
  insert into public.metricas (sitio_id, dia, tipo, n)
  values (v_id, current_date, p_tipo, 1)
  on conflict (sitio_id, dia, tipo)
  do update set n = public.metricas.n + 1;
end;
$$;

-- Permite llamar la RPC a visitantes anónimos y logueados.
grant execute on function public.registrar_evento(text, text) to anon, authenticated;
