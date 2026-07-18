# Control de Gastos · App web con Supabase

App personal de seguimiento de gastos (misma estructura de tu planilla: Fecha, Tipo, Criterio, Divisa, Monto, Forma de Pago, Aclaración) con base de datos Postgres en Supabase, login con contraseña y un dashboard de comparativas con gráficos.

## Archivos

- `index.html` — La app completa (registro + dashboard). No necesita build ni npm: es un solo archivo.
- `schema.sql` — Crea la tabla, la seguridad (RLS) y carga tus datos de mayo y junio 2026.

## Configuración (una sola vez, ~10 minutos)

### 1. Crear el proyecto en Supabase

1. Entrá a [supabase.com](https://supabase.com) y creá una cuenta (gratis).
2. **New project** → elegí nombre y una contraseña de base de datos (guardala, aunque no la vas a usar en la app). Región: `South America (São Paulo)` es la de menor latencia desde Uruguay.

### 2. Crear la tabla y cargar tus datos

1. En el panel del proyecto: **SQL Editor** → **New query**.
2. Pegá todo el contenido de `schema.sql` y presioná **Run**.
3. Verificá en **Table Editor** que la tabla `movimientos` exista con ~79 filas.

### 3. Crear tu usuario y cerrar el registro público

1. **Authentication → Users → Add user → Create new user**: poné tu email y una contraseña. Marcá **Auto Confirm User**.
2. **Authentication → Sign In / Providers → Email**: desactivá **Allow new users to sign up**. Así nadie más puede crearse una cuenta aunque tenga la URL de tu app.

### 4. Conectar la app

1. En Supabase: **Project Settings → API** (o "Data API"). Copiá:
   - **Project URL** (algo como `https://abcdefgh.supabase.co`)
   - **anon / public key**
2. Abrí `index.html` con un editor de texto y reemplazá al inicio del `<script>`:

```js
const SUPABASE_URL = "https://TU-PROYECTO.supabase.co";
const SUPABASE_ANON_KEY = "TU_ANON_KEY";
```

Nota: la anon key está pensada para ir en el frontend; la seguridad real la da la política RLS que exige estar autenticado. Nunca pongas la `service_role` key en el HTML.

### 5. Usarla

**Opción rápida (local):** abrí `index.html` con doble clic en cualquier navegador. Funciona directo.

**Opción recomendada (para tenerla en el celular):** publicala gratis en cualquiera de estos:

- **GitHub Pages**: subí `index.html` a un repo (puede ser privado con Pages activado en plan Pro, o público — la key anon no es secreta), Settings → Pages.
- **Netlify**: arrastrá la carpeta a [app.netlify.com/drop](https://app.netlify.com/drop). Listo en 30 segundos.
- **Vercel**: `npx vercel` en la carpeta, o desde la web.

Una vez publicada, en el celular: abrí la URL en Chrome → menú → **Agregar a pantalla de inicio**. Queda como una app más.

## Qué incluye

**Pestaña Registro**
- Alta rápida de gastos e ingresos con tus categorías y formas de pago
- KPIs del mes: ingresos, gastos, balance y promedio por día con gasto
- Desglose por criterio con barras y totales por forma de pago
- Lista de movimientos con borrado

**Pestaña Comparativas (estilo Power BI)**
- KPIs con variación % contra el mes anterior y tasa de ahorro
- Gasto mensual apilado por criterio (evolución de todos los meses)
- Flujo mensual: ingresos vs gastos
- Dona de distribución del mes en foco
- Comparativa por criterio: mes en foco vs anterior
- Carrera de gasto acumulado día a día contra el mes anterior

## Ideas para seguir

- Presupuesto por criterio con alertas de tope
- Exportación a CSV para mantener compatibilidad con la planilla
- Gastos recurrentes con un clic (ej: el interno de $570)
- Soporte multi-divisa real (hoy los gráficos agregan solo $U; los USD se listan aparte)
