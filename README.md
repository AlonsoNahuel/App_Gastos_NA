# Control de Gastos v2 · Multiusuario + Categorías dinámicas

App personal de seguimiento de gastos con base Postgres en Supabase.

**Novedades de esta versión:**
- **Multiusuario aislado**: cada usuario autenticado ve y administra únicamente sus propios movimientos y categorías. Podés crear más usuarios desde el panel de Supabase y cada uno arranca con su espacio vacío.
- **Categorías dinámicas**: pestaña nueva para crear categorías, renombrarlas, cambiarles el color y ocultarlas. Todo se guarda en la base y se refleja en los gráficos.

## Archivos

- `index.html` — La app completa (Registro + Comparativas + Categorías). Un solo archivo, sin build.
- `schema.sql` — Borra las tablas de la versión anterior y crea el modelo nuevo con tus datos de mayo/junio 2026.

## Instalación

⚠️ **El orden importa**: el usuario tiene que existir *antes* de correr el SQL, porque los datos iniciales se asignan al primer usuario del proyecto.

### 1. Crear tu usuario (si no existe ya)
**Authentication → Users → Add user → Create new user**: email + contraseña, con **Auto Confirm User** marcado.
Después: **Authentication → Sign In / Providers → Email** → desactivar **Allow new users to sign up**.

### 2. Correr el schema
**SQL Editor → New query** → pegar todo `schema.sql` → **Run**.
Al final vas a ver una fila de verificación: `categorias: 10, movimientos: 78`.
Nota: este script **borra y recrea** las tablas — si ya cargaste movimientos nuevos en la versión anterior, avisale a Claude para armar una migración que los conserve.

### 3. Conectar la app
En `index.html`, al inicio del `<script>`, pegá tu **Project URL** y tu **anon/publishable key** (Project Settings → API). La `service_role`/secret key nunca va acá.

### 4. Usar
Abrila local con doble clic, o publicala (Netlify Drop, Vercel, GitHub Pages) y agregala a la pantalla de inicio del celular.

## Modelo de datos

```
auth.users (Supabase)
    │
    ├── categorias   (id, user_id, nombre, color, activa, orden)
    │        │
    └── movimientos  (id, user_id, fecha, tipo, categoria_id → categorias,
                      divisa, monto, forma_pago, aclaracion)
```

Reglas que aplica la base (no dependen del frontend):
- RLS: `user_id = auth.uid()` en ambas tablas — un usuario no puede ver ni tocar datos ajenos.
- Todo gasto exige categoría; los ingresos no llevan.
- No se puede eliminar una categoría con movimientos (la clave foránea lo bloquea): se oculta.
- No puede haber dos categorías con el mismo nombre para el mismo usuario.

## Gestión de categorías (pestaña "Categorías")

- **Crear**: color + nombre → aparece de inmediato en el formulario y los gráficos.
- **Renombrar / recolorear**: editás el campo y se guarda solo al salir; el cambio aplica a todo el historial.
- **Ocultar**: desaparece del formulario de carga pero su historial sigue visible en listas y gráficos.
- **Eliminar (×)**: solo disponible para categorías sin movimientos.

## Power BI

Conectá Power BI Desktop al Session pooler de tu proyecto (botón **Connect** en Supabase, puerto 5432). Con el modelo nuevo tenés un esquema estrella: `movimientos` como tabla de hechos y `categorias` como dimensión — relacionalas por `categoria_id` en la vista de modelo y listo.
