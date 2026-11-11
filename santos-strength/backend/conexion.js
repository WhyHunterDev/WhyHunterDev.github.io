/* ============================================================
 *  Conexión al backend real (Supabase)
 *  Cómo usarlo:
 *   1) Pon tus datos en CONFIG (los copias de Supabase → Settings → API).
 *   2) En index.html y panel-ss-7q2k.html, ANTES de store.js agrega:
 *        <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
 *        <script src="backend/conexion.js"></script>
 *   3) store.js detecta esta conexión y, si existe, usa la nube en vez del
 *      navegador. Si no la pones, todo sigue funcionando en modo demo local.
 * ============================================================ */
(function () {
  const CONFIG = {
    url: 'https://szvdzcaoxjstdyblhxrd.supabase.co',             // Project URL
    anonKey: 'sb_publishable_LOmoV7GDpORg5J1eE7YriA_tB4Y6EYe',  // llave publishable (pública)
    sitio: 'santos-strength'                                     // slug del sitio de esta web
  };
  if (!window.supabase || CONFIG.url.includes('TU-PROYECTO')) return; // sin configurar → demo local

  const sb = window.supabase.createClient(CONFIG.url, CONFIG.anonKey);
  let sitioId = null;
  const idDe = async () => sitioId || (sitioId = (await sb.from('sitios').select('id').eq('slug', CONFIG.sitio).single()).data?.id);

  // Convierte las filas de 'contenido' en el mismo objeto que usa la web.
  async function cargar() {
    const sid = await idDe();
    const { data } = await sb.from('contenido').select('clave,valor').eq('sitio_id', sid);
    const out = {};
    (data || []).forEach((r) => { out[r.clave] = r.valor; });
    const { data: us } = await sb.from('perfiles').select('*').eq('sitio_id', sid);
    out.usuarios = us || [];
    return out;
  }
  async function guardarClave(clave, valor) {
    const sid = await idDe();
    await sb.from('contenido').upsert({ sitio_id: sid, clave, valor });
  }

  // Sube una foto/video al bucket 'medios' y devuelve su URL pública.
  async function subir(file) {
    const sid = await idDe();
    const ext = (file.name.split('.').pop() || 'bin').toLowerCase();
    const path = `${sid}/${Date.now()}-${Math.random().toString(36).slice(2, 7)}.${ext}`;
    const { error } = await sb.storage.from('medios').upload(path, file, { upsert: false });
    if (error) throw error;
    return sb.storage.from('medios').getPublicUrl(path).data.publicUrl;
  }

  async function actividad(sitioSlug, quien, que) {
    const sid = await idDe();
    await sb.from('actividad').insert({ sitio_id: sid, quien, que });
  }

  // Autenticación (reemplaza al login local del panel).
  const auth = {
    async entrar(email, pass) {
      const { data, error } = await sb.auth.signInWithPassword({ email, password: pass });
      if (error) throw error;
      const { data: perfil } = await sb.from('perfiles').select('*').eq('id', data.user.id).single();
      return perfil;
    },
    async salir() { await sb.auth.signOut(); },
    async actual() {
      const { data } = await sb.auth.getUser();
      if (!data.user) return null;
      return (await sb.from('perfiles').select('*').eq('id', data.user.id).single()).data;
    },
    async cambiarPass(nueva) { const { error } = await sb.auth.updateUser({ password: nueva }); if (error) throw error; }
  };

  // Expuesto para que store.js lo use si está presente.
  window.SS_BACKEND = { sb, cargar, guardarClave, subir, actividad, auth, idDe };
})();
