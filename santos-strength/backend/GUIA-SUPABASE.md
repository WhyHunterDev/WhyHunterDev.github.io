# Backend real con Supabase — Guía paso a paso

Hoy cada web guarda sus datos en el navegador de cada persona (modo demo). Con
este backend, todos comparten los mismos datos en la nube, con login real,
fotos y videos guardados en servidor, y seguridad por rol. Es **gratis** para
empezar (plan Free de Supabase) y te sirve para todos tus clientes a la vez.

Necesitas hacer esto **una sola vez**. Toma unos 15–20 minutos.

---

## 1. Crear el proyecto
1. Entra a https://supabase.com y crea una cuenta (puedes usar tu GitHub).
2. **New project**. Ponle un nombre (ej. `agencia-whyhunter`), crea una
   contraseña de base de datos (guárdala) y elige la región más cercana
   (**South America (São Paulo)**). Espera ~2 minutos a que se cree.

## 2. Crear la base de datos
1. En el menú izquierdo abre **SQL Editor** → **New query**.
2. Abre el archivo `01-estructura.sql`, copia todo, pégalo y pulsa **Run**.
3. Haz lo mismo con `02-seguridad-rls.sql`.
4. Haz lo mismo con `03-datos-inicio.sql` (crea el sitio Santos Strength).
Debe decir *Success* en cada uno.

## 3. Crear los usuarios del login
1. Menú izquierdo → **Authentication** → **Users** → **Add user** →
   *Create new user*.
2. Crea uno por persona con su correo y una contraseña temporal:
   - `admin@santosstrength.pe`
   - `manchay@santosstrength.pe`
   - `villamaria@santosstrength.pe`
   - `cafetin@santosstrength.pe`
   - Tu cuenta de agencia (ej. `yo@agencia.pe`).
3. De cada usuario copia su **User UID** (un código largo).

## 4. Conectar los usuarios con sus roles
1. Vuelve a **SQL Editor**.
2. Abre otra vez `03-datos-inicio.sql`: en la parte 2 verás líneas que
   empiezan con `--` (comentadas). Quítales el `--`, pega cada **User UID**
   donde dice `UUID-DEL-...` y pulsa **Run**.
   - Tu cuenta va con rol `gestor` (ve todo).
   - El resto con su rol y sede.

## 5. Copiar tus llaves
1. Menú izquierdo → **Project Settings** (engranaje) → **API**.
2. Copia **Project URL** y la llave **anon public**.
3. Abre `backend/conexion.js` y pega ambas en `CONFIG` (arriba del archivo).
   La llave `anon` es pública, no pasa nada si se ve en la web; la seguridad la
   dan las reglas RLS que ya cargaste.

## 6. Enlazar las webs
En `index.html` y en `panel-ss-7q2k.html`, justo **antes** de
`<script src="js/store.js">`, agrega estas dos líneas:
```html
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<script src="backend/conexion.js"></script>
```
Con esto, **la web pública ya lee y guarda el contenido en la nube**
(textos, planes, coaches, cafetín, galería, promos). Si dejas `conexion.js` sin
configurar, todo sigue en modo demo local (útil para pruebas).

> El **login del panel** todavía usa el sistema casero de la demo. Adaptarlo a
> Supabase Auth (correos, contraseñas cifradas, recuperación) es el último paso:
> lo dejo listo cuando me pases tu Project URL y tu llave `anon`, y lo probamos
> juntos contra tu proyecto ya creado.

---

## Cómo queda la seguridad
- **La web pública** solo puede **leer** el contenido. Nunca escribir.
- **Recepción / cafetín** solo editan **su propio sitio**, y suben fotos a la
  carpeta de su sitio. No pueden tocar otros clientes.
- **Admin** gestiona su sitio y su equipo.
- **Tú (gestor)** ves y editas **todo**, y eres el único que ve la tabla de
  costos y clientes (`clientes_agencia`).
- Las contraseñas las maneja Supabase Auth (cifradas, con recuperación por
  correo). Ya no hace falta el login casero de la demo.

## Respaldos y "volver atrás"
- Supabase hace **copias diarias** automáticas (Database → Backups).
- La tabla `contenido` guarda `actualizado` en cada cambio. Para versiones con
  un clic desde tu Panel Gestor, el siguiente paso es guardar una copia del
  JSON en una tabla `versiones_contenido`. Te lo puedo agregar cuando quieras.

## Un cliente nuevo (otra empresa)
1. `insert into public.sitios (slug, negocio) values ('mi-cliente','Mi Cliente');`
2. Crea sus usuarios en Authentication y sus perfiles (como en el paso 4).
3. Copia la web, cambia `CONFIG.sitio` al nuevo slug. Mismo backend, datos
   separados y seguros por las reglas RLS.

> Cuando tengas el proyecto creado y me pases la **Project URL** y la llave
> **anon** (son públicas), puedo dejar el `conexion.js` configurado y adaptar el
> login del panel a Supabase Auth, y lo probamos juntos.
