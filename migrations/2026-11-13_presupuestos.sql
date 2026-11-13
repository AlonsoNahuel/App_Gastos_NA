-- ============================================================
-- Migración 2026-11-13 · Presupuestos por categoría
--
-- Agrega un tope mensual opcional (en $U) a cada categoría.
-- No borra ni modifica datos existentes: se puede correr sin miedo
-- y es idempotente (correrla dos veces no rompe nada).
--
-- Ejecutar en: Supabase → SQL Editor → New query → Run
-- La política RLS "categorias propias" ya cubre la columna nueva.
-- ============================================================

alter table public.categorias
  add column if not exists presupuesto numeric(12,2);

alter table public.categorias
  drop constraint if exists categorias_presupuesto_positivo;

alter table public.categorias
  add constraint categorias_presupuesto_positivo
  check (presupuesto is null or presupuesto > 0);

-- Refresca la caché de esquema de la API para que la columna aparezca enseguida
notify pgrst, 'reload schema';
