-- ============================================================
-- Control de Gastos · Esquema v2 (multiusuario + categorías dinámicas)
--
-- IMPORTANTE ANTES DE CORRER:
--   1. Tu usuario debe existir YA en Authentication → Users
--      (los datos iniciales se asignan al primer usuario creado).
--   2. Este script BORRA las tablas anteriores y sus datos,
--      y las vuelve a crear con los datos de mayo/junio 2026.
--
-- Ejecutar en: SQL Editor → New query → Run (una sola vez)
-- ============================================================

drop table if exists public.movimientos cascade;
drop table if exists public.categorias cascade;

-- ─────────────── Tabla de categorías ───────────────
create table public.categorias (
  id       uuid primary key default gen_random_uuid(),
  user_id  uuid not null default auth.uid() references auth.users(id) on delete cascade,
  nombre   text not null,
  color    text not null default '#6A7570',
  activa   boolean not null default true,
  orden    int not null default 0,
  unique (user_id, nombre)
);

-- ─────────────── Tabla de movimientos ───────────────
create table public.movimientos (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  fecha        date not null,
  tipo         text not null check (tipo in ('Gasto', 'Ingreso')),
  categoria_id uuid references public.categorias(id),  -- sin cascade: no se puede borrar una categoría en uso
  divisa       text not null default '$U' check (divisa in ('$U', 'USD')),
  monto        numeric(12,2) not null check (monto > 0),
  forma_pago   text,
  aclaracion   text,
  created_at   timestamptz not null default now(),
  check (tipo = 'Ingreso' or categoria_id is not null)  -- todo gasto necesita categoría
);

create index movimientos_fecha_idx on public.movimientos (fecha);
create index movimientos_user_idx  on public.movimientos (user_id);
create index categorias_user_idx   on public.categorias (user_id);

-- ─────────────── Seguridad: cada usuario ve solo lo suyo ───────────────
alter table public.categorias  enable row level security;
alter table public.movimientos enable row level security;

create policy "categorias propias"
  on public.categorias for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "movimientos propios"
  on public.movimientos for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============================================================
-- Datos iniciales: se asignan al PRIMER usuario creado en el proyecto
-- ============================================================

with u as (
  select id from auth.users order by created_at limit 1
),
nuevas_cats as (
  insert into public.categorias (user_id, nombre, color, orden)
  select u.id, c.nombre, c.color, c.orden
  from u cross join (values
    ('Comida semanal',      '#14684A', 1),
    ('Comida finde/Gustos', '#4C9B72', 2),
    ('Alcohol',             '#8A6FB2', 3),
    ('Omnibus',             '#2E5F8A', 4),
    ('Salud',               '#B04430', 5),
    ('Regalos',             '#C98A2D', 6),
    ('Ropa',                '#7A6A54', 7),
    ('Entrenamiento',       '#3E9C9C', 8),
    ('Deuda mes anterior',  '#8C4A5E', 9),
    ('Otros',               '#6A7570', 10)
  ) as c(nombre, color, orden)
  returning id, nombre
)
insert into public.movimientos (user_id, fecha, tipo, categoria_id, divisa, monto, forma_pago, aclaracion)
select (select id from u), v.fecha::date, v.tipo, nc.id, '$U', v.monto::numeric, v.forma_pago, v.aclaracion
from (values
  ('2026-05-01','Gasto','Salud',947,'Debito PREX','Shampoo y preservativos'),
  ('2026-05-01','Gasto','Comida finde/Gustos',500,'Debito ITAU',null),
  ('2026-05-07','Ingreso',null,26532,'Transferencia ITAU',null),
  ('2026-05-01','Gasto','Alcohol',300,'Debito ITAU','Grapa'),
  ('2026-05-01','Gasto','Comida semanal',400,'Debito ITAU','Milas'),
  ('2026-05-01','Gasto','Otros',850,'Efectivo','Para tener'),
  ('2026-05-01','Gasto','Comida finde/Gustos',300,'Transferencia ITAU','Bizcochos'),
  ('2026-05-04','Gasto','Comida semanal',817,'Debito ITAU',null),
  ('2026-05-04','Gasto','Comida semanal',250,'Debito ITAU',null),
  ('2026-05-04','Gasto','Omnibus',580,'Debito ITAU',null),
  ('2026-05-05','Gasto','Comida semanal',433,'Debito ITAU',null),
  ('2026-05-07','Gasto','Ropa',1200,'Debito ITAU','Pantalón'),
  ('2026-05-07','Gasto','Regalos',810,'Debito ITAU','Mamá'),
  ('2026-05-07','Gasto','Comida semanal',105,'Debito ITAU',null),
  ('2026-05-11','Gasto','Omnibus',570,'Debito ITAU','Interno'),
  ('2026-05-11','Gasto','Comida semanal',1187,'Debito ITAU',null),
  ('2026-05-09','Gasto','Regalos',4510,'Debito PREX','Regalo piku y angie'),
  ('2026-05-09','Gasto','Otros',3280,'Debito PREX','Compra de EEUU'),
  ('2026-05-04','Gasto','Omnibus',477,'Debito ITAU',null),
  ('2026-05-12','Gasto','Comida semanal',675,'Debito ITAU',null),
  ('2026-05-12','Gasto','Comida finde/Gustos',45,'Debito ITAU',null),
  ('2026-05-13','Gasto','Comida semanal',121,'Debito ITAU',null),
  ('2026-05-13','Gasto','Comida finde/Gustos',100,'Efectivo','Alfajores'),
  ('2026-05-16','Gasto','Comida finde/Gustos',1000,'Debito ITAU',null),
  ('2026-05-17','Gasto','Comida finde/Gustos',287,'Debito ITAU',null),
  ('2026-05-19','Gasto','Comida semanal',190,'Debito ITAU',null),
  ('2026-05-20','Gasto','Omnibus',570,'Debito ITAU','Interno'),
  ('2026-05-20','Gasto','Otros',1000,'Efectivo',null),
  ('2026-05-25','Gasto','Salud',270,'Debito ITAU',null),
  ('2026-05-25','Gasto','Comida finde/Gustos',714,'Debito ITAU',null),
  ('2026-05-23','Gasto','Comida finde/Gustos',450,'Debito ITAU',null),
  ('2026-05-24','Gasto','Comida finde/Gustos',400,'Debito ITAU',null),
  ('2026-05-25','Gasto','Comida semanal',200,'Debito ITAU',null),
  ('2026-05-27','Gasto','Salud',2357,'Debito ITAU','Estudio respiratorio y pastillas'),
  ('2026-05-29','Gasto','Comida finde/Gustos',570,'Debito ITAU',null),
  ('2026-05-30','Gasto','Omnibus',340,'Efectivo','Santa Lucía'),
  ('2026-06-01','Gasto','Comida semanal',175,'Debito ITAU',null),
  ('2026-06-02','Gasto','Comida semanal',637,'Debito ITAU',null),
  ('2026-06-03','Gasto','Entrenamiento',260,'Debito ITAU','Fútbol'),
  ('2026-06-03','Gasto','Otros',447,'Debito ITAU','Contrato tigo'),
  ('2026-06-04','Gasto','Comida semanal',135,'Debito ITAU',null),
  ('2026-06-04','Gasto','Omnibus',570,'Debito ITAU','Interno'),
  ('2026-06-04','Gasto','Otros',1000,'Debito ITAU','Para tener'),
  ('2026-06-05','Gasto','Comida semanal',295,'Debito ITAU',null),
  ('2026-06-05','Gasto','Comida finde/Gustos',604,'Debito ITAU',null),
  ('2026-06-05','Gasto','Salud',1538,'Debito ITAU','Pastillas y gel'),
  ('2026-06-05','Gasto','Otros',720,'Debito ITAU','Muslera moncho'),
  ('2026-06-05','Ingreso',null,26500,'Debito ITAU',null),
  ('2026-06-06','Gasto','Omnibus',1344,'Debito ITAU','Cromin'),
  ('2026-06-06','Gasto','Salud',642,'Debito ITAU','Pastillas'),
  ('2026-06-06','Gasto','Salud',44,'Debito ITAU','Pastillas'),
  ('2026-06-06','Gasto','Ropa',2242,'Debito SANTANDER','Splitwise angie'),
  ('2026-06-09','Gasto','Comida semanal',220,'Debito ITAU',null),
  ('2026-06-11','Gasto','Comida semanal',87,'Debito ITAU',null),
  ('2026-06-12','Gasto','Comida semanal',105,'Debito ITAU',null),
  ('2026-06-12','Gasto','Comida semanal',155,'Debito ITAU',null),
  ('2026-06-15','Gasto','Comida semanal',398,'Debito ITAU',null),
  ('2026-06-15','Gasto','Comida semanal',586,'Debito ITAU',null),
  ('2026-06-15','Gasto','Omnibus',570,'Debito ITAU','Interno'),
  ('2026-06-17','Gasto','Comida semanal',235,'Debito ITAU',null),
  ('2026-06-18','Gasto','Comida finde/Gustos',758,'Debito ITAU','Comida gurises'),
  ('2026-06-15','Gasto','Comida finde/Gustos',102,'Transferencia SANTANDER',null),
  ('2026-06-15','Gasto','Comida finde/Gustos',449,'Transferencia SANTANDER',null),
  ('2026-06-18','Gasto','Comida finde/Gustos',507,'Transferencia SANTANDER',null),
  ('2026-06-18','Gasto','Comida finde/Gustos',48,'Transferencia SANTANDER',null),
  ('2026-06-19','Ingreso',null,5000,'Efectivo','Bono'),
  ('2026-06-22','Gasto','Comida semanal',79,'Debito ITAU',null),
  ('2026-06-22','Gasto','Comida semanal',280,'Debito ITAU',null),
  ('2026-06-22','Gasto','Salud',375,'Debito ITAU',null),
  ('2026-06-22','Gasto','Comida finde/Gustos',295,'Debito ITAU',null),
  ('2026-06-23','Gasto','Comida semanal',365,'Debito ITAU',null),
  ('2026-06-26','Gasto','Comida finde/Gustos',85,'Debito ITAU',null),
  ('2026-06-29','Gasto','Omnibus',570,'Debito ITAU','Interno'),
  ('2026-06-29','Gasto','Comida finde/Gustos',250,'Debito ITAU',null),
  ('2026-06-29','Gasto','Comida finde/Gustos',362,'Debito ITAU',null),
  ('2026-06-30','Gasto','Comida semanal',646,'Debito ITAU',null),
  ('2026-06-23','Ingreso',null,6682,'Transferencia SANTANDER','Aguinaldo'),
  ('2026-06-24','Gasto','Otros',800,'Debito PREX','Cloude')
) as v(fecha, tipo, criterio, monto, forma_pago, aclaracion)
left join nuevas_cats nc on nc.nombre = v.criterio;

-- Verificación rápida (esto SÍ devuelve filas):
select
  (select count(*) from public.categorias)  as categorias,
  (select count(*) from public.movimientos) as movimientos;
