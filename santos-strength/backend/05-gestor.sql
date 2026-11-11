-- Convierte TU cuenta en gestor (acceso total al Panel Gestor).
-- Requisito: ya creaste tu usuario en Authentication → Users.
-- Reemplaza el correo por el tuyo exacto y pulsa Run.
insert into public.perfiles (id, sitio_id, nombre, rol, sede)
select id, null, 'WhyHunter', 'gestor', 'todas'
from auth.users where email = 'TU-CORREO-AQUI'
on conflict (id) do update set rol = 'gestor', sitio_id = null, activo = true;
