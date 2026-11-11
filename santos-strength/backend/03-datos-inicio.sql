-- ============================================================
--  Archivo 3 de 3: DATOS INICIALES
--  Pégalo DESPUÉS de los archivos 1 y 2.
--  Crea el sitio "Santos Strength" y conecta a tus usuarios.
-- ============================================================

-- 1) Crear el sitio.
insert into public.sitios (slug, negocio)
values ('santos-strength', 'Santos Strength')
on conflict (slug) do nothing;

-- 2) Conectar usuarios (perfiles) a su login.
--    PRIMERO crea los usuarios en Supabase → Authentication → Users → Add user
--    (con su correo y una contraseña temporal). Luego copia el "User UID" de
--    cada uno y pégalo abajo reemplazando los UUID de ejemplo.
--
--    Tu cuenta de agencia va con rol 'gestor' y SIN sitio (ve todo).

-- --- TÚ (agencia) ---
-- insert into public.perfiles (id, sitio_id, nombre, rol, sede)
-- values ('00000000-0000-0000-0000-000000000000', null, 'WhyHunter', 'gestor', 'todas')
-- on conflict (id) do update set rol = 'gestor', sitio_id = null;

-- --- Equipo de Santos Strength ---
-- with s as (select id from public.sitios where slug = 'santos-strength')
-- insert into public.perfiles (id, sitio_id, nombre, rol, sede) values
--   ('UUID-DEL-ADMIN',    (select id from s), 'Administrador',          'admin',     'todas'),
--   ('UUID-DE-MANCHAY',   (select id from s), 'Recepción Manchay',      'recepcion', 'manchay'),
--   ('UUID-DE-VILLAMARIA',(select id from s), 'Recepción Villa María',  'recepcion', 'vmt'),
--   ('UUID-DEL-CAFETIN',  (select id from s), 'Encargada Cafetín',      'cafetin',   'todas')
-- on conflict (id) do update
--   set sitio_id = excluded.sitio_id, rol = excluded.rol, sede = excluded.sede;

-- 3) El contenido de la web (textos, planes, coaches, cafetín, galería)
--    se crea solo la primera vez que abras la web ya conectada: el adaptador
--    carga los datos de ejemplo y los guarda en la tabla 'contenido'.
--    No necesitas pegar nada más aquí.

-- 4) (Opcional) Registrar Santos en tu cartera de agencia:
-- insert into public.clientes_agencia (sitio_id, negocio, rubro, estado, url, panel, pago)
-- select id, 'Santos Strength', 'Gimnasio', 'activo',
--        'https://tu-dominio/santos-strength/',
--        'https://tu-dominio/santos-strength/panel-ss-7q2k.html', 'pendiente'
-- from public.sitios where slug = 'santos-strength';
