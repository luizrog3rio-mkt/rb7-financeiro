-- =============================================================
-- RB7 Financeiro — Schema inicial
-- Execute no SQL Editor do Supabase (ou via supabase db push)
-- =============================================================

-- ---------- ENUMS ----------
create type tipo_lancamento as enum ('pagar', 'receber');
create type status_lancamento as enum ('pendente', 'pago', 'atrasado', 'cancelado');
create type tipo_conta as enum ('corrente', 'cartao_credito', 'inter_empresa');
create type papel_usuario as enum ('admin', 'operador');

-- ---------- PERFIS ----------
create table perfis (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text not null,
  papel papel_usuario not null default 'operador',
  criado_em timestamptz not null default now()
);

-- ---------- EMPRESAS ----------
create table empresas (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cnpj text,
  criado_em timestamptz not null default now()
);

-- ---------- CONTAS (bancárias, cartões, inter-empresa) ----------
create table contas (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas(id) on delete cascade,
  nome text not null,                -- ex.: "Sicredi RB7", "C6 RB7", "Cartão Sicredi Berta"
  tipo tipo_conta not null default 'corrente',
  banco text,
  saldo_inicial numeric(14,2) not null default 0,
  -- para inter_empresa: empresa "do outro lado" do empréstimo
  empresa_contraparte_id uuid references empresas(id),
  dia_fechamento int,                -- cartão de crédito
  dia_vencimento int,                -- cartão de crédito
  ativa boolean not null default true,
  criado_em timestamptz not null default now()
);

-- ---------- CATEGORIAS (100% editáveis pelo operador) ----------
create table categorias (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  tipo tipo_lancamento not null,
  cor text default '#6366f1',
  ativa boolean not null default true,
  criado_em timestamptz not null default now()
);

-- ---------- LANÇAMENTOS (contas a pagar / receber) ----------
create table lancamentos (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas(id) on delete cascade,
  conta_id uuid references contas(id),
  categoria_id uuid references categorias(id),
  tipo tipo_lancamento not null,
  descricao text not null,
  valor numeric(14,2) not null,
  -- Fluxo completo de datas: Emissão -> Vencimento -> Pagamento
  data_emissao date not null,        -- competência (obrigatória)
  data_vencimento date not null,
  data_pagamento date,
  status status_lancamento not null default 'pendente',
  fornecedor_cliente text,
  observacoes text,
  -- fatura de cartão: agrupa lançamentos de cartão no contas a pagar
  fatura_conta_id uuid references contas(id),
  fatura_mes date,                   -- primeiro dia do mês da fatura
  criado_por uuid references perfis(id),
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create index idx_lancamentos_empresa on lancamentos(empresa_id);
create index idx_lancamentos_vencimento on lancamentos(data_vencimento);
create index idx_lancamentos_status on lancamentos(status);

-- ---------- TRANSAÇÕES OFX (extrato importado) ----------
create table transacoes_ofx (
  id uuid primary key default gen_random_uuid(),
  conta_id uuid not null references contas(id) on delete cascade,
  fitid text not null,               -- id único do banco (dedupe)
  data date not null,
  valor numeric(14,2) not null,
  memo text,
  tipo_transacao text,
  categoria_id uuid references categorias(id),
  lancamento_id uuid references lancamentos(id),  -- conciliação
  importado_em timestamptz not null default now(),
  unique (conta_id, fitid)
);

create index idx_ofx_conta on transacoes_ofx(conta_id);
create index idx_ofx_data on transacoes_ofx(data);

-- ---------- VENDAS HOTMART ----------
create table vendas_hotmart (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references empresas(id) on delete cascade,
  codigo_transacao text not null unique,
  produto text not null,
  data_venda date not null,
  data_liberacao date,               -- previsão de saque
  valor_bruto numeric(14,2) not null,
  taxa_hotmart numeric(14,2) not null default 0,
  comissao_afiliado numeric(14,2) not null default 0,
  comissao_coproducao numeric(14,2) not null default 0,
  valor_liquido numeric(14,2) not null,
  afiliado text,
  coprodutor text,
  meio_pagamento text,
  status text not null default 'aprovada',
  comprador text,
  importado_em timestamptz not null default now()
);

create index idx_hotmart_data on vendas_hotmart(data_venda);
create index idx_hotmart_empresa on vendas_hotmart(empresa_id);

-- ---------- TRIGGER: atualizado_em ----------
create or replace function set_atualizado_em()
returns trigger language plpgsql as $$
begin
  new.atualizado_em = now();
  return new;
end $$;

create trigger trg_lancamentos_atualizado
  before update on lancamentos
  for each row execute function set_atualizado_em();

-- ---------- TRIGGER: criar perfil ao registrar usuário ----------
create or replace function handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into perfis (id, nome, papel)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', new.email), 'operador');
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------- RLS ----------
alter table perfis enable row level security;
alter table empresas enable row level security;
alter table contas enable row level security;
alter table categorias enable row level security;
alter table lancamentos enable row level security;
alter table transacoes_ofx enable row level security;
alter table vendas_hotmart enable row level security;

-- Usuários autenticados têm acesso total (equipe pequena: admin + operador)
create policy "perfis: leitura autenticada" on perfis for select to authenticated using (true);
create policy "perfis: atualiza próprio" on perfis for update to authenticated using (id = auth.uid());

create policy "empresas: tudo autenticado" on empresas for all to authenticated using (true) with check (true);
create policy "contas: tudo autenticado" on contas for all to authenticated using (true) with check (true);
create policy "categorias: tudo autenticado" on categorias for all to authenticated using (true) with check (true);
create policy "lancamentos: tudo autenticado" on lancamentos for all to authenticated using (true) with check (true);
create policy "ofx: tudo autenticado" on transacoes_ofx for all to authenticated using (true) with check (true);
create policy "hotmart: tudo autenticado" on vendas_hotmart for all to authenticated using (true) with check (true);

-- ---------- SEED ----------
insert into empresas (nome) values ('RB7 Digital'), ('Berta');

insert into contas (empresa_id, nome, tipo, banco)
select e.id, c.nome, c.tipo::tipo_conta, c.banco from empresas e
join (values
  ('RB7 Digital', 'Sicredi RB7', 'corrente', 'Sicredi'),
  ('RB7 Digital', 'C6 RB7', 'corrente', 'C6 Bank'),
  ('RB7 Digital', 'Cartão Sicredi RB7', 'cartao_credito', 'Sicredi'),
  ('RB7 Digital', 'Cartão C6 RB7', 'cartao_credito', 'C6 Bank'),
  ('Berta', 'Sicredi Berta', 'corrente', 'Sicredi'),
  ('Berta', 'Cartão Sicredi Berta', 'cartao_credito', 'Sicredi')
) as c(empresa, nome, tipo, banco) on e.nome = c.empresa;

-- Contas inter-empresas (empréstimos RB7 <-> Berta)
insert into contas (empresa_id, nome, tipo, empresa_contraparte_id)
select a.id, 'Empréstimo → ' || b.nome, 'inter_empresa', b.id
from empresas a, empresas b where a.id <> b.id;

insert into categorias (nome, tipo, cor) values
  ('Tráfego Pago', 'pagar', '#ef4444'),
  ('Software/Ferramentas', 'pagar', '#f97316'),
  ('Folha/Prestadores', 'pagar', '#eab308'),
  ('Impostos', 'pagar', '#8b5cf6'),
  ('Viagens', 'pagar', '#06b6d4'),
  ('Chips/Telefonia', 'pagar', '#64748b'),
  ('Reembolsos', 'pagar', '#f43f5e'),
  ('Jurídico/Contábil', 'pagar', '#0ea5e9'),
  ('Outras Despesas', 'pagar', '#94a3b8'),
  ('Vendas Hotmart', 'receber', '#22c55e'),
  ('Vendas Diretas', 'receber', '#10b981'),
  ('Outras Receitas', 'receber', '#34d399');

