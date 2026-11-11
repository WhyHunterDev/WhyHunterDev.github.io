/* Páginas legales: rellena los datos de la empresa y maneja el Libro de Reclamaciones. */
(function () {
  const $ = (s, r = document) => r.querySelector(s);
  const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const B = window.SS_BACKEND;
  let data = null;

  async function cargar() {
    try { if (B) data = await B.cargar(); } catch (_) {}
    const L = (data && data.config && data.config.legal) || {};
    const val = { razon: L.razon || 'Santos Strength', ruc: L.ruc || '[RUC pendiente]', direccion: L.direccion || '[dirección fiscal pendiente]', email: L.email || '[correo pendiente]' };
    document.querySelectorAll('[data-l]').forEach((el) => { el.textContent = val[el.dataset.l]; });
    const sedes = (data && data.sedes) || [{ nombre: 'Manchay' }, { nombre: 'Villa María' }];
    const sel = $('#rSede'); if (sel) sel.innerHTML = sedes.map((s) => `<option>${esc(s.nombre)}</option>`).join('');
    const fecha = $('#rFecha'); if (fecha) fecha.textContent = new Date().toLocaleDateString('es-PE', { day: '2-digit', month: '2-digit', year: 'numeric', timeZone: 'America/Lima' });
  }
  cargar();

  const f = $('#rForm');
  if (!f) return;
  const menor = $('#rMenor');
  menor.addEventListener('change', () => { $('#rApoWrap').hidden = !menor.checked; $('#rApo').required = menor.checked; });
  f.addEventListener('submit', async (e) => {
    e.preventDefault();
    const err = $('#rErr'); err.hidden = true;
    const g = (id) => ($(id).value || '').trim();
    const p = {
      tipo: f.querySelector('input[name=tipo]:checked').value, sede: g('#rSede'), nombre: g('#rNombre'), documento: g('#rDoc'),
      domicilio: g('#rDom'), telefono: g('#rTel'), email: g('#rEmail'), menor: menor.checked, apoderado: g('#rApo'),
      bien: f.querySelector('input[name=bien]:checked').value, monto: g('#rMonto'), descripcion: g('#rDesc'), detalle: g('#rDetalle'), pedido: g('#rPedido')
    };
    if (!$('#rAcepto').checked) { err.textContent = 'Marca la casilla de conformidad para continuar.'; err.hidden = false; return; }
    const btn = $('#rBtn'); btn.disabled = true; btn.textContent = 'Enviando…';
    try {
      if (!B) throw new Error('Sin conexión con el sistema. Acércate a la sede para usar el libro físico.');
      const { data: codigo, error } = await B.sb.rpc('registrar_reclamo', { p_slug: B.sitio, p });
      if (error) throw new Error(/function|schema cache/i.test(error.message) ? 'El libro virtual aún no está activo. Acércate a la sede para usar el libro físico.' : error.message);
      const L = (data && data.config && data.config.legal) || {};
      $('#rOk').innerHTML = `<h2>✅ ${p.tipo === 'queja' ? 'Queja' : 'Reclamo'} registrado</h2>
        <p class="big">N.º <b>${esc(codigo)}</b></p>
        <p>Fecha: ${esc(new Date().toLocaleString('es-PE', { timeZone: 'America/Lima' }))} · Sede: ${esc(p.sede)}</p>
        <p>${esc(L.razon || 'Santos Strength')} · RUC ${esc(L.ruc || '—')}</p>
        <p><b>Nombre:</b> ${esc(p.nombre)} · <b>Documento:</b> ${esc(p.documento)}</p>
        <p><b>Detalle:</b> ${esc(p.detalle)}</p><p><b>Pedido:</b> ${esc(p.pedido || '—')}</p>
        <p class="nota">Te responderemos en un plazo máximo de 15 días hábiles al correo o teléfono que dejaste. Guarda esta constancia.</p>
        <div class="acts"><button type="button" onclick="print()">🖨️ Imprimir o guardar PDF</button><a href="./">Volver a la web</a></div>`;
      f.hidden = true; $('#rOk').hidden = false; scrollTo(0, 0);
    } catch (ex) { err.textContent = ex.message || 'No se pudo registrar.'; err.hidden = false; }
    btn.disabled = false; btn.textContent = 'Enviar';
  });
})();
