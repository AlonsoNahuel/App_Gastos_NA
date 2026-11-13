# Auditoría · App_Gastos_NA

> Fecha: 2026-11-13 · Alcance: todo el repo (`index.html`, `styles.css`, `schema.sql`, `README.md`, `logo.png`) + historial de git completo (8 commits).
> **No revisado**: la base real de Supabase (el conector no tenía permisos sobre el proyecto) y el código del importador de Apps Script (no está en el repo). Donde eso importa, lo marco como **⚠ verificar**.

---

## 1. Resumen ejecutivo

1. **La base está bien pensada**: tenés RLS con `USING` y `WITH CHECK` en las tablas del schema, usás solo la *publishable key*, escapás el texto antes de meterlo en `innerHTML` y no hay secretos en el historial. Para ser código personal, es un muy buen punto de partida.
2. **El bug más peligroso es silencioso**: la app trae *todos* los movimientos en orden ascendente, y Supabase corta en 1000 filas por defecto. Cuando el importador las supere, **van a desaparecer los movimientos más nuevos** sin ningún error.
3. **Privacidad**: `schema.sql` tiene tus gastos reales de mayo y junio, con descripciones personales. Si el repo es público (es requisito de GitHub Pages en el plan Free), eso queda a la vista de cualquiera.
4. **`schema.sql` ya no refleja la base**: falta la tabla `comercios`, la columna `comercio` y la categoría "Sin clasificar". Además empieza con `DROP TABLE`, así que correrlo de nuevo borra todo.
5. **Hoy no es una PWA**: no hay manifest ni service worker. El logo pesa 1,36 MB para mostrarse a 58×40 px.
6. **UX**: no se puede editar un movimiento (solo reclasificarlo o borrarlo), borrar no pide confirmación y el botón Guardar admite doble toque. Los gastos en USD no entran en ningún KPI ni gráfico.
7. **Hosting: mi recomendación es no migrar a Netlify por ahora.** Con el modelo de créditos de 2026 te da unos 20 deploys de producción al mes, y casi todo lo que ganarías se puede resolver en GitHub Pages. Si querés headers o previews, Cloudflare Pages te queda mejor que Netlify. Igual te dejo el plan completo de Netlify más abajo.

---

## 2. Hallazgos (ordenados por severidad)

Esfuerzo: **S** < 1 h · **M** algunas horas · **L** un día o más.

| # | Sev. | Área | Dónde | Hallazgo | Esf. |
|---|---|---|---|---|---|
| H1 | 🔴 Crítica | Datos | [index.html:239](index.html:239) | `select("*")` de **todo** el historial, ordenado por `fecha` ascendente. PostgREST corta en 1000 filas por defecto (*Max rows*), así que al pasar ese número se pierden **los más recientes** sin error. | S |
| H2 | 🔴 Crítica* | Seguridad / privacidad | [schema.sql:62-164](schema.sql:62) | Movimientos reales (montos, bancos, descripciones personales, nombres de terceros) commiteados. *Es crítico si el repo es público, y además queda en el historial aunque borres el archivo. | S-M |
| H3 | 🟠 Media | Seguridad | ⚠ verificar (base) | La tabla `comercios` no está en `schema.sql`, así que no pude auditar su RLS. Si no tiene `ENABLE RLS` con una política `user_id = auth.uid()`, cualquier usuario autenticado lee y escribe el diccionario del otro. | S |
| H4 | 🟠 Media | Seguridad | ⚠ verificar (Auth) | El README indica desactivar *Allow new users to sign up*. Si sigue activado, cualquiera con la publishable key (que es pública) puede crearse una cuenta. RLS lo aísla, pero consume tu cuota y te ensucia la base. | S |
| H5 | 🟠 Media | Seguridad | Importador (no está en el repo) | Hay que confirmar dónde vive la key que usa Apps Script. Si es la `service_role`/secret, tiene que estar en *Script Properties* y nunca en el código. Lo ideal es que ni siquiera use esa (ver Fase 1). | S-M |
| H6 | 🟠 Media | Modelo | [schema.sql](schema.sql) entero | El schema se desfasó de la base real (`comercios`, `movimientos.comercio`, "Sin clasificar") y no hay migraciones versionadas. Encima, [schema.sql:13-14](schema.sql:13) hace `DROP TABLE … CASCADE`. | M |
| H7 | 🟠 Media | Datos | [index.html:405](index.html:405) | `delMes()` filtra solo `$U`. Los gastos en USD **no suman** en KPIs, barras ni gráficos, y nada te avisa. | S (aviso) / M (conversión) |
| H8 | 🟠 Media | Calidad | [index.html:12](index.html:12), [index.html:175](index.html:175) | `supabase-js@2` sin versión fija (toma cualquier 2.x nueva). Si el CDN falla, `window.supabase` queda `undefined`, la línea 175 tira una excepción y la app queda muerta: el botón Ingresar no hace nada y no hay ningún mensaje. | S |
| H9 | 🟠 Media | UX | [index.html:86](index.html:86), [index.html:260-276](index.html:260) | `agregar()` no deshabilita el botón mientras guarda. Con un doble toque en el celular, el movimiento queda duplicado. | S |
| H10 | 🟠 Media | UX | [index.html:278](index.html:278), [index.html:477](index.html:477), [styles.css:98-100](styles.css:98) | Borrar no pide confirmación ni ofrece deshacer, y la × es chica. En móvil no hay hover, así que queda siempre semitransparente y es fácil tocarla sin querer. | S |
| H11 | 🟠 Media | UX | — | No hay forma de **editar** un movimiento (monto, fecha, aclaración, divisa): solo reclasificar o borrar y volver a cargar. | M |
| H12 | 🟠 Media | Rendimiento | [index.html:19](index.html:19), [index.html:45](index.html:45) | `logo.png` pesa 1,36 MB y se muestra a 58×40 px. En 4G es lo que más tarda en cargar. | S |
| H13 | 🟠 Media | PWA | — | No hay `manifest.webmanifest`, service worker, `theme-color` ni `apple-touch-icon`. "Agregar a inicio" crea un acceso directo, no una app instalable, y sin red no abre. | M |
| H14 | 🟠 Media | Datos | Importador | Idempotencia ⚠ verificar: si no hay una columna con el ID del mail y un `UNIQUE` sobre ella, reprocesar un mail duplica el gasto. | S-M |
| H15 | 🟡 Baja | Seguridad | [index.html:357](index.html:357), [388](index.html:388), [458](index.html:458), [468](index.html:468) | `color` se interpola sin escapar en atributos y `style`, y la base no valida el formato ([schema.sql:21](schema.sql:21)). Hoy es self-XSS, porque solo vos escribís tus colores. **Pasa a media si implementan el hogar compartido.** | S |
| H16 | 🟡 Baja | Seguridad | [schema.sql:33](schema.sql:33) | El FK `categoria_id` no verifica el dueño: los FK ignoran RLS, así que un usuario podría asociar un movimiento a una categoría ajena si conociera su UUID. El impacto es mínimo, pero se arregla con un FK compuesto. | S |
| H17 | 🟡 Baja | Seguridad | [index.html:206](index.html:206) | `esc()` no escapa `'`. Hoy no se explota porque solo se interpolan UUIDs dentro de `onclick='…'`, pero es una trampa a futuro. | S |
| H18 | 🟡 Baja | Rendimiento DB | [schema.sql:50-56](schema.sql:50) | Las políticas usan `auth.uid()` directo. Supabase recomienda `(select auth.uid())` para que se evalúe una vez por consulta y no una por fila. | S |
| H19 | 🟡 Baja | Modelo | [schema.sql:42-44](schema.sql:42) | Índices sueltos en `fecha` y `user_id`. Uno compuesto `(user_id, fecha)` cubre la consulta real, y a `categoria_id` (FK) le falta índice. | S |
| H20 | 🟡 Baja | Calidad | [index.html:435](index.html:435) | La categoría "Sin clasificar" se busca por nombre. Si la renombrás, el aviso de pendientes deja de funcionar. | S |
| H21 | 🟡 Baja | Calidad | [index.html:301](index.html:301) | Los comercios se comparan por nombre exacto: `"TATA "` y `"Tata"` cuentan como dos distintos. Conviene normalizar (trim + mayúsculas) y tener un `UNIQUE (user_id, nombre)` en la base. | S |
| H22 | 🟡 Baja | UX | [index.html:295-309](index.html:295) | Al reclasificar un gasto importado se aprende el comercio, pero los **otros pendientes del mismo comercio** quedan en "Sin clasificar". | S |
| H23 | 🟡 Baja | UX | [index.html:236-251](index.html:236) | No hay estado de carga: al entrar se ven KPIs en $0 hasta que llegan los datos. Además cada acción recarga las tres tablas completas. | S |
| H24 | 🟡 Baja | UX | [index.html:203](index.html:203), [index.html:306](index.html:306) | `avisar()` usa estilo de error (rojo) también para los mensajes de éxito. | S |
| H25 | 🟡 Baja | Accesibilidad | [index.html:24-29](index.html:24), [75-85](index.html:75), [471](index.html:471), [477](index.html:477) | Las etiquetas son `<div>` y no `<label for>`. La × tiene solo `title` y le falta `aria-label`. La categoría editable es un `<span onclick>` que no se puede usar con teclado. | S |
| H26 | 🟡 Baja | Accesibilidad | [styles.css:7](styles.css:7) | El gris `#807D6C` sobre `#F4F2EB` da un contraste de ~3,9:1, por debajo del 4,5:1 que piden los textos chicos (labels de 10-12 px). | S |
| H27 | 🟡 Baja | Rendimiento | [index.html:9-12](index.html:9) | Los scripts del `<head>` no tienen `defer` y Chart.js (~200 KB) se carga aunque nunca abras Comparativas. | S |
| H28 | 🟡 Baja | Calidad | [index.html:167-636](index.html:167) | Todo el JS es inline y usa handlers `onclick="…"`. Para el tamaño actual no es un problema, pero impide una CSP estricta (obliga a `'unsafe-inline'`). | M |
| H29 | 🟡 Baja | Docs | [README.md:25](README.md:25), [README.md:31](README.md:31) | El README no menciona el importador, `comercios` ni cómo recrear la base sin perder datos. | S |

**Lo que está bien, para que no lo toques:** el RLS de `categorias` y `movimientos` con `USING` + `WITH CHECK` y `user_id default auth.uid()` ([schema.sql:19](schema.sql:19), [50-56](schema.sql:50)); `monto numeric(12,2)` con `CHECK > 0`; los `CHECK` de `tipo`/`divisa`; el FK sin cascade que protege categorías en uso; `esc()` aplicado de forma consistente en nombres y comercios; Chart.js con versión fija; los mensajes de error de Supabase que sí se muestran al usuario; `fecha` como `date` (sin líos de zona horaria en la base) y `hoyISO()` con la fecha local, que es lo correcto.

**Historial de git:** no encontré JWTs, `service_role`, `sb_secret` ni tokens. La única key es la publishable ([index.html:173](index.html:173)), que es pública por diseño. El `wrangler.toml` que se borró (commit `9579f26`) no tenía secretos.

---

## 3. Detalle por área (con trade-offs)

### 3.1 Seguridad

**H1 · El límite de 1000 filas.** No es de seguridad, pero va primero porque es el único hallazgo que te puede hacer perder información sin enterarte.
- *Opción A (la que recomiendo)*: traer solo una ventana, por ejemplo los últimos 13 meses con `.gte("fecha", desde)`, y pedir meses más viejos cuando se elijan. *Trade-off*: las comparativas ven 13 meses en lugar de todo el historial. Para uso diario sobra.
- *Opción B*: paginar con `.range()` hasta traer todo. Es simple, pero la carga inicial crece para siempre.
- *Opción C*: una vista o RPC en Postgres que devuelva los totales por mes y categoría ya agregados (los gráficos no necesitan las filas). Es lo más eficiente, a cambio de sumar SQL que mantener. Tiene sentido en Fase 3.

**H2 · Datos personales en el repo.** Primero confirmá si el repo es público (Settings → General → Danger Zone).
- *Mínimo*: sacar el bloque de datos de `schema.sql` y dejar solo la estructura. *Trade-off*: el historial sigue teniendo los datos.
- *Completo*: reescribir el historial con [`git filter-repo`](https://github.com/newren/git-filter-repo) (es la herramienta estándar, no la reinventes) y hacer force-push. *Trade-off*: si alguien ya lo clonó o forkeó, esa copia queda igual.
- *Alternativa*: hacer el repo privado. Eso implica dejar GitHub Pages Free (Pages en un repo privado requiere GitHub Pro) o pasarte a Netlify/Cloudflare, que sí deployan desde repos privados gratis. **Es uno de los pocos argumentos reales para migrar.**

**H3/H4 · Lo que tenés que revisar a mano en Supabase (10 minutos):**
1. *Database → Tables → comercios*: RLS en "Enabled" y una política `for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id)`.
2. *Advisors → Security Advisor*: debería quedar vacío. Avisa justamente de tablas sin RLS, funciones `SECURITY DEFINER` expuestas, etc.
3. *Authentication → Sign In / Providers → Email*: "Allow new users to sign up" **apagado**.
4. *Authentication → Users*: que estén solo ustedes dos.

**H5 · Seguridad del importador de Apps Script.** No tengo el código, así que te dejo el checklist:
- [ ] La key se guarda en `PropertiesService.getScriptProperties()` y no figura en el `.gs`.
- [ ] **No usa `service_role`.** Esa key saltea RLS, y si se filtra (un fork del script, un share por error), alguien lee y borra los datos de los dos. La alternativa simple es que el script **inicie sesión como tu usuario** (`/auth/v1/token?grant_type=password` con email y password guardados en Script Properties) y use el JWT resultante. Así RLS aplica también al importador. *Trade-off*: hay que guardar un password en Script Properties, que es menos grave que guardar una key que saltea todo, y renovar el token si el script corre mucho tiempo. Una alternativa más prolija es un RPC `security definer` que solo pueda insertar movimientos de un `user_id` fijo.
- [ ] Valida el remitente real del banco (`from` exacto) y no solo el asunto. Si no, cualquiera que te mande un mail con formato parecido te carga gastos.
- [ ] El parseo del monto tolera `1.234,56` (formato UY) y no hace `parseFloat("1.234,56") → 1.234`.
- [ ] Idempotencia: ver H14.
- [ ] El texto del comercio que sale del mail se guarda tal cual y el frontend lo escapa. Eso ya pasa: [index.html:473](index.html:473) y [389](index.html:389) usan `esc()`. ✅

**H15/H17 · XSS.** Hoy el riesgo es bajo porque cada uno solo ve lo suyo. Si hacen el hogar compartido, tu pareja podría (en teoría) inyectar HTML en el color de una categoría que vos ves. El arreglo cuesta dos líneas: un `CHECK (color ~ '^#[0-9A-Fa-f]{6}$')` en la base y que `esc()` también escape `'` → `&#39;`. *Trade-off*: ninguno.

### 3.2 Calidad del código

- **Estado global** (`movimientos`, `categorias`, `comercios`, `mesSel`…): para 640 líneas y una sola pantalla está bien. No metas un framework. El paso natural, si crece, es pasar el `<script>` a un `app.js` y, más adelante, partirlo en módulos ES (`<script type="module">`) por vista. Eso no necesita build.
- **Manejo de errores**: supabase-js devuelve `{ error }` incluso cuando no hay red, y vos ya lo mostrás. El hueco real es H8: si el script del CDN no carga, todo muere. La solución es fijar la versión y envolver la creación del cliente:
  ```js
  if (!window.supabase) { mostrarError("No se pudo cargar la app. Revisá tu conexión y recargá."); }
  ```
- **Dependencias CDN**: fijá `@supabase/supabase-js@2.x.y` exacto, como ya hacés con Chart.js. Si querés más robustez, *vendorizá* los dos `.min.js` en una carpeta `vendor/`: son dos archivos, no hace falta npm. *Trade-off*: actualizarlos pasa a ser manual, que en una app personal es justo lo que querés.
- **Duplicación**: los cinco gráficos repiten el mismo `tooltip.callbacks.label` ([index.html:553](index.html:553), [568](index.html:568), [598](index.html:598), [628](index.html:628)). Se resuelve con una constante `tooltipPlata`. Es cosmético.
- **Código muerto**: `forma_pago` existe en la base ([schema.sql:36](schema.sql:36)) pero el frontend nunca la escribe ni la muestra. O la sumás al formulario o la dejás solo para el importador y lo documentás.

### 3.3 Datos y modelo

- **Migraciones (H6)**: la herramienta estándar es la [Supabase CLI](https://supabase.com/docs/guides/local-development). El flujo mínimo, sin Docker:
  ```bash
  npx supabase login
  npx supabase link --project-ref zskrtupyytjglookgpfu
  npx supabase db pull          # genera supabase/migrations/<ts>_remote_schema.sql con el estado REAL
  ```
  A partir de ahí, cada cambio es un archivo nuevo en `supabase/migrations/` que aplicás con `npx supabase db push`. `schema.sql` pasa a ser historia y los datos de ejemplo, si los querés, van a un `seed.sql` **ficticio**. *Trade-off*: es una herramienta más. Como alternativa mínima, una carpeta `migrations/001_…sql` aplicada a mano en el SQL Editor también sirve: lo importante es que el repo diga la verdad.
- **Moneda (H7)**: tenés tres niveles, de menor a mayor esfuerzo:
  1. Mostrar los totales USD por separado ("+ US$ 120 en dólares, no incluidos"). Es S y no requiere tocar la base.
  2. Una columna `tipo_cambio numeric` por movimiento, cargada a mano o por el importador. Los KPIs convierten a `$U`. *Trade-off*: hay que acordarse de cargarla.
  3. Una cotización diaria automática (BCU) en una tabla `cotizaciones`. Es lo más preciso y lo más frágil (dependés de una API externa). Lo dejaría para Fase 3.
- **Fechas y zona horaria**: `fecha date` está bien. Lo que hay que mirar es que el proyecto de Apps Script tenga la zona `America/Montevideo` (*Configuración del proyecto*), porque si no, un gasto de las 22:30 puede quedar al día siguiente al convertir desde UTC.
- **Idempotencia del importador (H14)**:
  ```sql
  alter table movimientos add column origen_id text;           -- Gmail message id
  create unique index movimientos_origen_uq on movimientos (user_id, origen_id) where origen_id is not null;
  ```
  En el script, usar `Prefer: resolution=ignore-duplicates` con `on_conflict=user_id,origen_id`. Así podés reprocesar mails sin miedo. *Trade-off*: ninguno, y además te permite rastrear de qué mail salió cada gasto. Si el importador hoy marca los mails con una etiqueta de Gmail, eso ayuda, pero no alcanza: si el script falla entre el insert y el etiquetado, el gasto se duplica.
- **Constraints e índices** (todos S, en una sola migración):
  ```sql
  alter table categorias add constraint color_hex check (color ~ '^#[0-9A-Fa-f]{6}$');
  create index movimientos_user_fecha_idx on movimientos (user_id, fecha);
  create index movimientos_categoria_idx on movimientos (categoria_id);
  -- H16: el FK compuesto asegura que la categoría sea del mismo usuario
  alter table categorias add unique (id, user_id);
  alter table movimientos drop constraint movimientos_categoria_id_fkey,
    add foreign key (categoria_id, user_id) references categorias (id, user_id);
  -- H20: marcar la categoría especial con un flag y no por nombre
  alter table categorias add column es_sin_clasificar boolean not null default false;
  ```

### 3.4 UX y usabilidad móvil

- **Carga rápida**: el flujo actual necesita tocar "+ Registrar", completar campos y tocar "Guardar". Mejoras S que suman mucho:
  - Que el formulario quede abierto por defecto en móvil o recuerde su estado.
  - `autofocus` en Monto al abrirlo y Enter para guardar.
  - Recordar la última categoría y divisa usadas (`localStorage`).
  - Deshabilitar el botón mientras guarda (H9) y mostrar un toast verde de "Guardado".
- **Edición (H11)**: tocar una fila podría abrir el mismo formulario precargado, con "Guardar cambios" y "Borrar". Eso resuelve H10 y H11 juntos, saca la × de la lista y deja el borrado detrás de un toque más. *Trade-off*: hay un paso más para borrar, que es justo lo que se busca.
- **Reclasificación (H22)**: al aprender un comercio, ofrecer *"¿Aplicar también a los otros 4 pendientes de TATA?"*. Es un `update … where comercio = X and categoria_id = sin_clasificar`.
- **Filtros y búsqueda**: hoy solo se filtra por mes. Un input de búsqueda (comercio o aclaración) y un filtro por categoría sobre la lista se resuelven en cliente con lo que ya tenés en memoria. Es S.
- **Estados de carga y vacío**: los estados vacíos están bien resueltos ("Todavía no hay gastos este mes"). Falta un *skeleton* o "Cargando…" mientras llega `cargar()` (H23).
- **Accesibilidad** (H25/H26): `<label for>`, `aria-label="Borrar movimiento"` en la ×, `<button>` en lugar de `<span onclick>` y oscurecer `--gris` a algo como `#6B6858`.
- **Rendimiento en celular**: H12 (logo), H27 (`defer` y carga diferida de Chart.js) y la autohospedada de las fuentes, que además sirve para que funcionen offline.

### 3.5 PWA

Hoy no hay nada, así que es todo ganancia. Mi propuesta es **mínima y sin librerías**: para una app de este tamaño, un SW escrito a mano de unas 40 líneas se entiende mejor que Workbox. Si más adelante querés estrategias más complejas, [Workbox](https://developer.chrome.com/docs/workbox) es la herramienta estándar.

1. `manifest.webmanifest`: `name`, `short_name`, `start_url: "./"`, `scope: "./"`, `display: "standalone"`, `theme_color: "#DCF14B"`, `background_color: "#F4F2EB"`, íconos de 192 y 512 px (más uno `maskable`). Usá rutas **relativas** para que ande igual en `usuario.github.io/App_Gastos_NA/` y en un dominio propio.
2. En el `<head>`: `<link rel="manifest">`, `<meta name="theme-color">` y `<link rel="apple-touch-icon">`.
3. `sw.js` con estas estrategias:
   - **HTML**: *network-first* con fallback a la caché, para que siempre veas la última versión si hay red.
   - **CSS/JS/íconos/fuentes**: *stale-while-revalidate*.
   - **Supabase (`*.supabase.co`)**: **nunca cachear**. Siempre a la red.
   - Una constante `VERSION = "v3"` en el nombre de la caché. En `activate`, borrar las cachés viejas.
4. **Actualización**: cuando hay un SW nuevo en espera, mostrar "Hay una versión nueva · Actualizar", que manda `postMessage('skipWaiting')` y recarga. *Trade-off*: es un toque extra, pero evita recargas sorpresa en medio de una carga de datos.
5. **Offline**: con lo anterior, la app *abre* sin red y muestra el error de Supabase. **Guardar sin red** (una cola en IndexedDB que sincroniza después) es otra liga de complejidad: conflictos, duplicados, UI de "pendiente de sincronizar". Lo dejo para Fase 3 y solo si lo extrañan de verdad. Para dos personas en Montevideo con 4G, casi nunca va a hacer falta.

### 3.6 Funcionalidades que faltan (priorizadas por valor diario)

| Prioridad | Feature | Valor | Esfuerzo | Trade-off |
|---|---|---|---|---|
| 1 | **Editar movimiento** (H11) | Alto: hoy corregir un monto es borrar y volver a cargar | M | Ninguno real |
| 2 | **Reclasificar en lote** (H22) + **búsqueda/filtro** | Alto: con el importador, los pendientes se acumulan | S | Ninguno |
| 3 | **Presupuestos por categoría** | Alto: es lo que convierte "registro" en "control" | M | Tabla nueva `presupuestos (user_id, categoria_id, monto_mensual)`. Barras de progreso en Registro (ya tenés las barras, solo falta el tope) y aviso visual al 80/100 %. Las *alertas push* son otra cosa (Fase 3). |
| 4 | **Exportar CSV** | Medio: backup y Excel | S | supabase-js ya trae [`.csv()`](https://supabase.com/docs/reference/javascript/db-csv): `sb.from("movimientos").select(...).csv()` y un `Blob`. **No escribas tu propio serializador.** |
| 5 | **Gastos compartidos (hogar)** | Alto para ustedes dos, pero cambia el modelo | L | Tabla `hogares` + `hogar_miembros`. Movimientos y categorías con `hogar_id`, y RLS vía una función `es_miembro(hogar_id)` `security definer`. A cambio, un RLS más complejo y una migración de datos. **Alternativa liviana**: un flag `compartido boolean` + un campo `pagado_por`, y una vista que calcule "quién le debe a quién". Esto sí requiere que ambos lean las filas compartidas del otro, así que igual toca RLS. Conviene charlarlo antes: ¿quieren ver *todo* junto o solo los gastos comunes? |
| 6 | **Total en USD convertido** (H7) | Medio | S-M | Ver 3.3 |
| 7 | **Gastos recurrentes** (alquiler, Tigo, interno) | Medio | M | *Simple*: un botón "Duplicar al mes siguiente". *Automático*: `pg_cron` en Supabase (disponible en el plan Free) que inserte desde una tabla `recurrentes`. Lo automático te deja gastos "fantasma" si cancelás algo y te olvidás de sacarlo. |
| 8 | **Reglas de categorización por patrón** | Medio | S-M | Extender `comercios` con `patron text` y un `tipo` (`exacto`/`contiene`). La aplica el importador. Tenés que mantener las reglas, pero ya tenés la UI de comercios. |
| 9 | **Tendencias** (promedio móvil de 3 meses por categoría, proyección de fin de mes) | Medio | S | Ya tenés el gráfico de acumulado diario: la proyección es una línea punteada más. |
| 10 | **Comprobantes** (foto del ticket) | Bajo-medio | M | Supabase Storage con un bucket privado y una política por `user_id`. A cambio, ocupa espacio (1 GB en el plan Free) y conviene comprimir en el cliente. |

---

## 4. Roadmap

### Fase 1 · Quick wins y seguridad (1 o 2 fines de semana)
Cada ítem es independiente. El orden sugiere qué hacer primero.

1. **H1**: limitar la consulta a los últimos 13 meses. *(S, evita perder datos)*
2. **H3/H4/H5**: revisar a mano RLS de `comercios`, el signup apagado, el Security Advisor y dónde vive la key del importador. *(S, sin código)*
3. **H2**: sacar los datos reales de `schema.sql` y decidir entre repo privado o `git filter-repo`. *(S-M)*
4. **H6**: `supabase db pull` para capturar el schema real en `supabase/migrations/` y retirar `schema.sql`. *(M)*
5. Migración de constraints e índices: color hex, FK compuesto, índices, `(select auth.uid())` en las políticas y `origen_id` único para el importador. *(S)*
6. **H8**: fijar la versión de supabase-js y mostrar un aviso si el CDN no carga. *(S)*
7. **H9/H10/H24**: botón deshabilitado al guardar, confirmación o deshacer al borrar, toast verde. *(S)*
8. **H12**: logo a WebP/PNG de unos 10 KB (con [Squoosh](https://squoosh.app), sin código). **H27**: `defer` en los scripts. *(S)*
9. **H7 nivel 1**: mostrar el total USD aparte. *(S)*
10. **Keep-alive**: ver la sección 5.4. *(S)*

### Fase 2 · Features de mayor valor
1. Editar movimiento (H11), que de paso saca la × de la lista.
2. Reclasificar en lote (H22) + búsqueda/filtro por categoría.
3. **PWA mínima** (manifest + SW). Hacela *después* de decidir el hosting, porque el cambio de dominio afecta la instalación.
4. Presupuestos por categoría con barras de progreso.
5. Exportar CSV con `.csv()`.
6. Pasar el JS a `app.js` y reemplazar los `onclick` por `addEventListener` o delegación (H28), para poder aplicar una CSP sin `'unsafe-inline'`.
7. Accesibilidad básica (H25/H26).

### Fase 3 · A futuro
1. Hogar compartido (después de charlar el modelo entre los dos).
2. Recurrentes (`pg_cron`) y reglas por patrón.
3. Conversión USD con tipo de cambio.
4. RPC de agregados para los gráficos (H1, opción C).
5. Comprobantes en Storage.
6. Offline con cola de escritura, y notificaciones push para alertas de presupuesto.

---

## 5. Hosting: ¿Netlify o seguir en GitHub Pages?

### 5.1 Comparación honesta

| | GitHub Pages (hoy) | Netlify Free (2026) | Cloudflare Pages Free |
|---|---|---|---|
| Costo de un deploy | Gratis (límite blando de ~10 builds/hora) | **15 créditos de 300/mes → ~20 deploys de producción por mes**; si se agotan, el sitio se pausa | Gratis (500 builds/mes, ⚠ verificar) |
| Ancho de banda | 100 GB/mes (blando) | Se descuenta de los mismos 300 créditos | Ilimitado para estáticos |
| Headers propios (CSP, cache) | ❌ Solo `<meta http-equiv>` (sin `frame-ancestors`, sin cache por archivo) | ✅ `netlify.toml` o `_headers` | ✅ `_headers` |
| Deploy previews por branch/PR | ❌ | ✅ (⚠ confirmá si consumen créditos) | ✅ |
| Redirects / SPA fallback | ❌ (solo `404.html`) | ✅ | ✅ |
| Funciones / cron | ❌ (pero tenés GitHub Actions) | ✅ Functions + Scheduled Functions | ✅ Workers + Cron Triggers |
| Variables de entorno | No aplica sin build | ✅, aunque **en tu caso aportan poco** (ver 5.3) | ✅ |
| Repo privado gratis | ❌ (Pages Free exige repo público) | ✅ | ✅ |
| Dominio propio + HTTPS | ✅ | ✅ | ✅ |
| Formularios | ❌ | ✅, pero no lo necesitás: ya tenés Supabase | ❌ |

> Los límites de Netlify cambiaron al modelo de créditos en abril de 2026, y las fuentes que encontré son mayormente de terceros. Antes de decidir, chequeá los números en la página oficial de Netlify.

### 5.2 Mi recomendación: **no migrar a Netlify por ahora**

- Lo que más ganarías son **headers HTTP reales** (una CSP completa y caché por archivo), **previews** y **repo privado**. Son cosas buenas, pero ninguna es urgente para una app de dos usuarios con RLS bien puesto.
- Lo que perdés es lo que más te va a molestar: **unos 20 deploys al mes**. Vos commiteás seguido mientras iterás, y si el límite te frena, el sitio *se pausa*. Para una herramienta de uso diario es un mal trade-off.
- Si en algún momento querés headers, previews o un repo privado, **Cloudflare Pages te da lo mismo sin el límite de créditos**. Por el `wrangler.toml` del historial veo que ya lo probaste. El formato de `_headers` es casi idéntico al de Netlify, así que lo que armes acá te sirve igual.

**Mejoras que aplicaría en GitHub Pages hoy:**
1. **CSP vía `<meta>`** en `index.html`. No cubre `frame-ancestors`, pero sí lo importante: de dónde se cargan scripts y a dónde se conecta.
   ```html
   <meta http-equiv="Content-Security-Policy" content="
     default-src 'self';
     script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;
     style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
     font-src https://fonts.gstatic.com;
     img-src 'self' data:;
     connect-src 'self' https://zskrtupyytjglookgpfu.supabase.co wss://zskrtupyytjglookgpfu.supabase.co;
     manifest-src 'self'; worker-src 'self';
     base-uri 'self'; form-action 'self'">
   ```
   El `'unsafe-inline'` de `script-src` se va recién cuando hagas el ítem 6 de la Fase 2 (sacar los `onclick`). Si vendorizás las librerías, también podés sacar `cdn.jsdelivr.net`.
2. Activar **Enforce HTTPS** en Settings → Pages (seguramente ya está).
3. Keep-alive y PWA, igual que en cualquier hosting (5.4 y 3.5).
4. Si el repo es público y no querés que lo sea, ese es el momento de pasar a Cloudflare Pages.

### 5.3 Si igual querés migrar a Netlify: plan paso a paso

**¿Hace falta build?** No. Sigue siendo estático: `publish = "."` y sin comando. La única razón para meter un build sería inyectar config distinta por entorno (por ejemplo, un proyecto Supabase de staging para los previews). Con un solo proyecto no vale la pena.

**1. Ordenar el repo** para no publicar archivos que no hacen falta:
```
/public            ← publish dir
  index.html  styles.css  app.js  logo.webp  manifest.webmanifest  sw.js  icons/
/supabase/migrations
netlify.toml  README.md  AUDITORIA.md
```
Así `README`, migraciones, etc. no quedan servidos. Ojo: con `[assets] directory = "."` de tu `wrangler.toml` viejo, Cloudflare iba a servir todo el repo.

**2. `netlify.toml` recomendado:**
```toml
[build]
  publish = "public"
  # sin command: sitio estático

[[headers]]
  for = "/*"
  [headers.values]
    Content-Security-Policy = "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self' https://zskrtupyytjglookgpfu.supabase.co wss://zskrtupyytjglookgpfu.supabase.co; manifest-src 'self'; worker-src 'self'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'"
    # mientras queden onclick inline, agregá 'unsafe-inline' a script-src
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"
    Permissions-Policy = "camera=(), microphone=(), geolocation=()"
    Strict-Transport-Security = "max-age=31536000"

# HTML y SW: siempre revalidar (si no, las actualizaciones no llegan)
[[headers]]
  for = "/index.html"
  [headers.values]
    Cache-Control = "no-cache"
[[headers]]
  for = "/sw.js"
  [headers.values]
    Cache-Control = "no-cache"

# Assets: cache largo. Requiere versionar el nombre (styles.v3.css) o un ?v=3 en la URL
[[headers]]
  for = "/icons/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

# SPA fallback: la app es una sola página con tabs, así que no hace falta.
# Dejalo comentado por si en el futuro usás rutas tipo /comparativas
# [[redirects]]
#   from = "/*"
#   to = "/index.html"
#   status = 200
```

**3. Variables de entorno de Supabase.** La URL y la publishable key **son públicas por diseño**: están en el JS que baja cualquier navegador. Ponerlas en variables de entorno de Netlify no las oculta, porque igual terminan en el HTML. Mi recomendación es dejarlas en un `public/config.js` commiteado. Las variables de entorno sí sirven para:
- secretos de **Netlify Functions** (por ejemplo, si el keep-alive o un webhook usan una key privada);
- tener configuración distinta en *deploy previews* y en producción, con un build mínimo:
  ```toml
  [build]
    command = "echo \"window.CFG={url:'$SUPABASE_URL',key:'$SUPABASE_PUBLISHABLE_KEY'}\" > public/config.js"
  ```
  *Trade-off*: aparece un build step, y sin él la app ya no se puede abrir localmente con doble clic.

**4. Supabase para el nuevo dominio.**
- *Authentication → URL Configuration*: **Site URL** = `https://tu-app.netlify.app` (o tu dominio). En **Redirect URLs** agregá también `https://deploy-preview-*--tu-app.netlify.app/**` para los previews.
  Con login por email + password como el actual, estas URLs solo importan para los mails de *reset password* y los magic links, pero conviene dejarlas bien desde ahora.
- **CORS**: la API REST y Auth de Supabase aceptan cualquier origen, así que no hay nada que configurar. La seguridad la da RLS, no el origen.
- La sesión se guarda en `localStorage` **por origen**. Al cambiar de dominio, los dos van a tener que volver a loguearse una vez.

**5. Deploy continuo y previews.**
1. Netlify → *Add new site → Import from Git → GitHub* → elegir el repo (puede ser privado).
2. Branch de producción: `main`. Build command vacío. Publish: `public`.
3. *Deploy Previews*: "Any pull request". *Branch deploys*: los que quieras, por ejemplo `dev`. Si los previews consumen créditos, limitalos a PRs.
4. Para no gastar créditos en commits que no cambian el sitio, el `netlify.toml` acepta `[build] ignore = "git diff --quiet $CACHED_COMMIT_REF $COMMIT_REF -- public/"`.
5. Recién cuando Netlify funcione bien: desactivar GitHub Pages (Settings → Pages → None).

**6. Service worker y manifest al cambiar de dominio.**
- Una PWA instalada desde `usuario.github.io/App_Gastos_NA/` es **otra app** para el sistema. Hay que desinstalar ese ícono e instalar el del dominio nuevo.
- Si para ese momento ya hay SW en GitHub Pages, antes de apagarlo publicá ahí un **SW "kill switch"** que borre las cachés y redirija al dominio nuevo:
  ```js
  self.addEventListener("install", () => self.skipWaiting());
  self.addEventListener("activate", async () => {
    for (const k of await caches.keys()) await caches.delete(k);
    await self.registration.unregister();
    for (const c of await self.clients.matchAll()) c.navigate("https://tu-app.netlify.app/");
  });
  ```
- En el manifest, `start_url` y `scope` con rutas relativas (`./`) funcionan en los dos hostings sin cambios.

**7. Rollback seguro.**
- Netlify guarda cada deploy. En *Deploys* → elegís uno anterior → **Publish deploy** y es instantáneo. También podés hacer *Lock* para que un push no lo pise mientras investigás.
- **El cuidado está en el SW**: si el deploy roto llegó a instalar un SW que cachea mal, volver atrás el HTML no alcanza. Por eso `sw.js` va con `Cache-Control: no-cache` (está en el `netlify.toml` de arriba) y cada deploy sube `VERSION`. Si querés rollback *y* que el SW se actualice, el rollback tiene que ser un deploy nuevo (con `git revert` y push) y no solo republicar uno viejo, salvo que el SW viejo ya tuviera una versión distinta.
- Plan B de emergencia: mientras no apagues GitHub Pages, la versión anterior sigue viva en `github.io`.

### 5.4 Keep-alive de Supabase (con cualquier hosting)

El plan Free pausa el proyecto si no tiene actividad en la base durante unos 7 días ([FAQ oficial](https://supabase.com/kb/faqs/platform/free-project-pausing)).

**Antes que nada:** si el importador de Apps Script corre con un *trigger* de tiempo (por ejemplo, cada hora) y en cada corrida consulta o inserta en Supabase, **ya es tu keep-alive** y no necesitás nada más. Para eso, conviene que haga una consulta liviana *siempre*, aunque no haya mails nuevos. Es la opción más simple porque no suma piezas. ⚠ Verificá que el trigger exista y que consulte en cada corrida.

Si querés algo independiente del importador:

1. Un RPC trivial en la base (va como migración):
   ```sql
   create or replace function public.ping() returns timestamptz
   language sql stable as $$ select now() $$;
   grant execute on function public.ping() to anon;
   ```
2. **Opción A: GitHub Action** (`.github/workflows/keepalive.yml`):
   ```yaml
   name: supabase-keepalive
   on:
     schedule: [{ cron: "0 12 */3 * *" }]   # cada 3 días
     workflow_dispatch:
   jobs:
     ping:
       runs-on: ubuntu-latest
       steps:
         - run: |
             curl -fsS -X POST "$URL/rest/v1/rpc/ping" \
               -H "apikey: $KEY" -H "Content-Type: application/json" -d '{}'
           env:
             URL: https://zskrtupyytjglookgpfu.supabase.co
             KEY: ${{ secrets.SUPABASE_PUBLISHABLE_KEY }}
   ```
   ⚠ **Trampa conocida**: en repos públicos, GitHub **desactiva los workflows programados después de 60 días sin commits**. Si dejás de tocar el repo dos meses, el keep-alive se apaga solo (GitHub te manda un mail antes). Por eso prefiero el importador o la opción B.
3. **Opción B: Netlify Scheduled Function** (si migraste), en `netlify/functions/keepalive.mjs`:
   ```js
   export default async () => {
     await fetch(`${process.env.SUPABASE_URL}/rest/v1/rpc/ping`, {
       method: "POST",
       headers: { apikey: process.env.SUPABASE_PUBLISHABLE_KEY, "Content-Type": "application/json" },
       body: "{}",
     });
   };
   export const config = { schedule: "0 12 */3 * *" };
   ```
   Consume créditos de funciones. Con una ejecución cada 3 días debería ser despreciable, pero confirmalo en el panel de uso.

Activá también *Account → Notifications → Project status changes* en Supabase, si está disponible para tu plan, para enterarte si igual se pausa.

---

## Fuentes consultadas sobre límites de hosting
- [Netlify Pricing and Limits in 2026 (netli.fyi)](https://netli.fyi/blog/netlify-pricing-and-limits)
- [Netlify Free Plan Limits in 2026 (netli.fyi)](https://netli.fyi/blog/netlify-free-plan-limits-2026)
- [Netlify free plan (costbench)](https://costbench.com/software/cloud-infrastructure/netlify/free-plan/)
- [Supabase: Do projects pause when they're inactive? (oficial)](https://supabase.com/kb/faqs/platform/free-project-pausing)
- [Supabase project paused (productcompass)](https://www.productcompass.pm/p/supabase-project-paused)
