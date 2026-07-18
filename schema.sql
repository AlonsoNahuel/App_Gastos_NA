-- ============================================================
-- Control de Gastos · Esquema para Supabase (Postgres)
-- Ejecutar en: Supabase Dashboard → SQL Editor → New query → Run
-- ============================================================

create table if not exists public.movimientos (
  id          uuid primary key default gen_random_uuid(),
  fecha       date not null,
  tipo        text not null check (tipo in ('Gasto', 'Ingreso')),
  criterio    text,
  divisa      text not null default '$U' check (divisa in ('$U', 'USD')),
  monto       numeric(12,2) not null check (monto > 0),
  forma_pago  text,
  aclaracion  text,
  created_at  timestamptz not null default now()
);

create index if not exists movimientos_fecha_idx on public.movimientos (fecha);

-- Seguridad: solo usuarios autenticados pueden leer/escribir.
-- (Creá tu usuario en Authentication → Users → Add user,
--  y desactivá los registros públicos en Authentication → Providers → Email → "Allow new users to sign up")
alter table public.movimientos enable row level security;

create policy "acceso total autenticados"
  on public.movimientos
  for all
  to authenticated
  using (true)
  with check (true);

-- ============================================================
-- Datos iniciales: mayo y junio 2026 (importados de tu planilla)
-- ============================================================

insert into public.movimientos (fecha, tipo, criterio, divisa, monto, forma_pago, aclaracion) values
('2026-05-01','Gasto','Salud','$U',947,'Debito PREX','Shampoo y preservativos'),
('2026-05-01','Gasto','Comida finde/Gustos','$U',500,'Debito ITAU',null),
('2026-05-07','Ingreso',null,'$U',26532,'Transferencia ITAU',null),
('2026-05-01','Gasto','Alcohol','$U',300,'Debito ITAU','Grapa'),
('2026-05-01','Gasto','Comida semanal','$U',400,'Debito ITAU','Milas'),
('2026-05-01','Gasto','Otros','$U',850,'Efectivo','Para tener'),
('2026-05-01','Gasto','Comida finde/Gustos','$U',300,'Transferencia ITAU','Bizcochos'),
('2026-05-04','Gasto','Comida semanal','$U',817,'Debito ITAU',null),
('2026-05-04','Gasto','Comida semanal','$U',250,'Debito ITAU',null),
('2026-05-04','Gasto','Omnibus','$U',580,'Debito ITAU',null),
('2026-05-05','Gasto','Comida semanal','$U',433,'Debito ITAU',null),
('2026-05-07','Gasto','Ropa','$U',1200,'Debito ITAU','Pantalón'),
('2026-05-07','Gasto','Regalos','$U',810,'Debito ITAU','Mamá'),
('2026-05-07','Gasto','Comida semanal','$U',105,'Debito ITAU',null),
('2026-05-11','Gasto','Omnibus','$U',570,'Debito ITAU','Interno'),
('2026-05-11','Gasto','Comida semanal','$U',1187,'Debito ITAU',null),
('2026-05-09','Gasto','Regalos','$U',4510,'Debito PREX','Regalo piku y angie'),
('2026-05-09','Gasto','Otros','$U',3280,'Debito PREX','Compra de EEUU'),
('2026-05-04','Gasto','Omnibus','$U',477,'Debito ITAU',null),
('2026-05-12','Gasto','Comida semanal','$U',675,'Debito ITAU',null),
('2026-05-12','Gasto','Comida finde/Gustos','$U',45,'Debito ITAU',null),
('2026-05-13','Gasto','Comida semanal','$U',121,'Debito ITAU',null),
('2026-05-13','Gasto','Comida finde/Gustos','$U',100,'Efectivo','Alfajores'),
('2026-05-16','Gasto','Comida finde/Gustos','$U',1000,'Debito ITAU',null),
('2026-05-17','Gasto','Comida finde/Gustos','$U',287,'Debito ITAU',null),
('2026-05-19','Gasto','Comida semanal','$U',190,'Debito ITAU',null),
('2026-05-20','Gasto','Omnibus','$U',570,'Debito ITAU','Interno'),
('2026-05-20','Gasto','Otros','$U',1000,'Efectivo',null),
('2026-05-25','Gasto','Salud','$U',270,'Debito ITAU',null),
('2026-05-25','Gasto','Comida finde/Gustos','$U',714,'Debito ITAU',null),
('2026-05-23','Gasto','Comida finde/Gustos','$U',450,'Debito ITAU',null),
('2026-05-24','Gasto','Comida finde/Gustos','$U',400,'Debito ITAU',null),
('2026-05-25','Gasto','Comida semanal','$U',200,'Debito ITAU',null),
('2026-05-27','Gasto','Salud','$U',2357,'Debito ITAU','Estudio respiratorio y pastillas'),
('2026-05-29','Gasto','Comida finde/Gustos','$U',570,'Debito ITAU',null),
('2026-05-30','Gasto','Omnibus','$U',340,'Efectivo','Santa Lucía'),
('2026-06-01','Gasto','Comida semanal','$U',175,'Debito ITAU',null),
('2026-06-02','Gasto','Comida semanal','$U',637,'Debito ITAU',null),
('2026-06-03','Gasto','Entrenamiento','$U',260,'Debito ITAU','Fútbol'),
('2026-06-03','Gasto','Otros','$U',447,'Debito ITAU','Contrato tigo'),
('2026-06-04','Gasto','Comida semanal','$U',135,'Debito ITAU',null),
('2026-06-04','Gasto','Omnibus','$U',570,'Debito ITAU','Interno'),
('2026-06-04','Gasto','Otros','$U',1000,'Debito ITAU','Para tener'),
('2026-06-05','Gasto','Comida semanal','$U',295,'Debito ITAU',null),
('2026-06-05','Gasto','Comida finde/Gustos','$U',604,'Debito ITAU',null),
('2026-06-05','Gasto','Salud','$U',1538,'Debito ITAU','Pastillas y gel'),
('2026-06-05','Gasto','Otros','$U',720,'Debito ITAU','Muslera moncho'),
('2026-06-05','Ingreso',null,'$U',26500,'Debito ITAU',null),
('2026-06-06','Gasto','Omnibus','$U',1344,'Debito ITAU','Cromin'),
('2026-06-06','Gasto','Salud','$U',642,'Debito ITAU','Pastillas'),
('2026-06-06','Gasto','Salud','$U',44,'Debito ITAU','Pastillas'),
('2026-06-06','Gasto','Ropa','$U',2242,'Debito SANTANDER','Splitwise angie'),
('2026-06-09','Gasto','Comida semanal','$U',220,'Debito ITAU',null),
('2026-06-11','Gasto','Comida semanal','$U',87,'Debito ITAU',null),
('2026-06-12','Gasto','Comida semanal','$U',105,'Debito ITAU',null),
('2026-06-12','Gasto','Comida semanal','$U',155,'Debito ITAU',null),
('2026-06-15','Gasto','Comida semanal','$U',398,'Debito ITAU',null),
('2026-06-15','Gasto','Comida semanal','$U',586,'Debito ITAU',null),
('2026-06-15','Gasto','Omnibus','$U',570,'Debito ITAU','Interno'),
('2026-06-17','Gasto','Comida semanal','$U',235,'Debito ITAU',null),
('2026-06-18','Gasto','Comida finde/Gustos','$U',758,'Debito ITAU','Comida gurises'),
('2026-06-15','Gasto','Comida finde/Gustos','$U',102,'Transferencia SANTANDER',null),
('2026-06-15','Gasto','Comida finde/Gustos','$U',449,'Transferencia SANTANDER',null),
('2026-06-18','Gasto','Comida finde/Gustos','$U',507,'Transferencia SANTANDER',null),
('2026-06-18','Gasto','Comida finde/Gustos','$U',48,'Transferencia SANTANDER',null),
('2026-06-19','Ingreso',null,'$U',5000,'Efectivo','Bono'),
('2026-06-22','Gasto','Comida semanal','$U',79,'Debito ITAU',null),
('2026-06-22','Gasto','Comida semanal','$U',280,'Debito ITAU',null),
('2026-06-22','Gasto','Salud','$U',375,'Debito ITAU',null),
('2026-06-22','Gasto','Comida finde/Gustos','$U',295,'Debito ITAU',null),
('2026-06-23','Gasto','Comida semanal','$U',365,'Debito ITAU',null),
('2026-06-26','Gasto','Comida finde/Gustos','$U',85,'Debito ITAU',null),
('2026-06-29','Gasto','Omnibus','$U',570,'Debito ITAU','Interno'),
('2026-06-29','Gasto','Comida finde/Gustos','$U',250,'Debito ITAU',null),
('2026-06-29','Gasto','Comida finde/Gustos','$U',362,'Debito ITAU',null),
('2026-06-30','Gasto','Comida semanal','$U',646,'Debito ITAU',null),
('2026-06-23','Ingreso',null,'$U',6682,'Transferencia SANTANDER','Aguinaldo'),
('2026-06-24','Gasto','Otros','$U',800,'Debito PREX','Cloude');
