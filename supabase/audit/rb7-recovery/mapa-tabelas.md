# Mapa de tabelas — rb7-financeiro (A) x categorizador-fatura (B)

Extraído da auditoria cruzada (sessão 3bf3e25a, task w6jvunmh1; 11 agentes).
Resumo da auditoria: Auditoria cruzada dos dois apps financeiros para plano de unificação sem duplicação

## 1. Perfil de usuário

- **Veredicto**: semelhante
- **Lado A (rb7-financeiro)**: Tabela perfis: id uuid PK FK auth.users ON DELETE CASCADE, nome text NOT NULL, papel papel_usuario default 'operador', criado_em (A supabase/migrations/00001_schema.sql:13-18). RLS: select para todos authenticated (00001:159); update só do próprio com (select auth.uid())=id (20260609180002_hardening_advisors.sql:27-31); privilégio de coluna: só GRANT UPDATE(nome), papel imutável pelo app (20260609180002:22-23). Tipo TS em src/lib/types.ts:6-10. papel é só informativo, nenhuma tela verifica.
- **Lado B (categorizador-fatura)**: Tabela profiles: id uuid PK FK auth.users CASCADE, email text, created_at (B supabase/migration.sql:6-10). RLS select/insert/update próprias por auth.uid()=id (migration.sql:14-24). App NUNCA lê nem escreve profiles — tabela morta do ponto de vista do client (zero referências em App.jsx).
- **Unificação**: Nome final: perfis (PT). Colunas: id, nome, papel, email text NULL (única coluna útil de B), criado_em. Migrar: para cada usuário de B que continuar existindo no projeto unificado, criar linha em perfis com nome=email e papel='operador' (mesma regra do trigger A). Descartar: tabela profiles inteira (era write-only via trigger), suas 3 policies. Manter o hardening de A (coluna papel só editável via service role).

## 2. Trigger de bootstrap de perfil (handle_new_user / on_auth_user_created)

- **Veredicto**: conflito
- **Lado A (rb7-financeiro)**: function handle_new_user() SECURITY DEFINER SET search_path='' inserindo em public.perfis (id, nome=coalesce(raw_user_meta_data->>'nome', email), papel='operador') (A 20260609175517_fix_handle_new_user_search_path.sql; versão original 00001:137-147); trigger on_auth_user_created AFTER INSERT ON auth.users (00001:145-147); EXECUTE revogado de public/anon/authenticated (20260609180002:15).
- **Lado B (categorizador-fatura)**: function public.handle_new_user() SECURITY DEFINER SEM search_path fixo, insere em public.profiles (id, email) (B migration.sql:27-34); trigger on_auth_user_created AFTER INSERT ON auth.users (migration.sql:36-38). MESMOS NOMES de função e trigger que A.
- **Unificação**: Colisão de nomes direta: função public.handle_new_user e trigger on_auth_user_created existem nos dois schemas — impossível coexistirem no mesmo projeto Supabase. Manter SOMENTE a versão de A (hardened: search_path='', nomes qualificados, EXECUTE revogado), estendida para também gravar email se a coluna for adotada: insert into public.perfis (id, nome, papel, email). Descartar a função/trigger de B. Qualquer função nova deve nascer com SET search_path='' (lição do bug histórico de A que quebrava signup via GoTrue).

## 3. Empresa (multi-tenant por empresa)

- **Veredicto**: so_A
- **Lado A (rb7-financeiro)**: Tabela empresas: id, nome, cnpj, criado_em (A 00001:21-26); seed 'RB7 Digital' e 'Berta' (00001:170). empresa_id NOT NULL em contas/lancamentos/vendas_hotmart. Seletor global 'empresa ativa' com consolidado=null no Layout (src/components/Layout.tsx:39-52) e filtro .eq('empresa_id', ...) por página (Dashboard.tsx:38, Lancamentos.tsx:54, Contas.tsx:36, ImportarOfx.tsx:21, Hotmart.tsx:24). Variante inter_empresa com empresa_contraparte_id para empréstimos RB7↔Berta (00001:36-37, 184-186).
- **Lado B (categorizador-fatura)**: ausente — nenhum conceito de empresa; partição é por user_id.
- **Unificação**: Manter empresas intacta como eixo de partição do app unificado. Dados migrados de B recebem empresa_id atribuído na migração (decisão do dono por fatura; default sugerido: RB7 Digital, já que as DEFAULT_RULES de B citam fornecedores da operação RB7 — App.jsx:6-69). Nada a descartar.

## 4. Conta bancária / cartão de crédito

- **Veredicto**: so_A
- **Lado A (rb7-financeiro)**: Tabela contas: empresa_id NOT NULL, nome, tipo enum corrente|cartao_credito|inter_empresa, banco, saldo_inicial numeric(14,2), empresa_contraparte_id, dia_fechamento/dia_vencimento (cartão), ativa (A 00001:29-42). Seed de 8 contas (00001:172-186). Saldo calculado no client com regra 'se há OFX, OFX é fonte da verdade' (src/pages/Contas.tsx:40-61).
- **Lado B (categorizador-fatura)**: ausente — não existe tabela de conta/cartão; cada invoice é implicitamente a fatura de UM cartão, identificado só pelo nome do arquivo .ofx (App.jsx:745).
- **Unificação**: Manter contas. Na migração de B, cada invoice precisa ser mapeada para uma conta tipo cartao_credito existente (Cartão Sicredi RB7, Cartão C6 RB7, Cartão Sicredi Berta — seed 00001:177-180) ou para uma conta nova criada na migração; transactions de B herdam esse conta_id (NOT NULL em transacoes_ofx, 00001:85). ATENÇÃO ao risco: injetar transações OFX de cartão em contas existentes ativa a regra 'OFX exclui lançamentos pagos' do saldo (Contas.tsx:58-59) — preferir contas de cartão dedicadas, cujo saldo de fatura não se mistura com corrente.

## 5. Lançamento (contas a pagar/receber)

- **Veredicto**: so_A
- **Lado A (rb7-financeiro)**: Tabela lancamentos: empresa_id NOT NULL, conta_id, categoria_id, tipo pagar|receber, descricao, valor numeric(14,2), data_emissao/data_vencimento/data_pagamento (date), status enum com trigger atualizado_em, fornecedor_cliente, observacoes, fatura_conta_id+fatura_mes (órfãs, sem UI), criado_por FK perfis (A 00001:55-80). CRUD completo em src/pages/Lancamentos.tsx; status derivado só no save (Lancamentos.tsx:106).
- **Lado B (categorizador-fatura)**: ausente — B não tem contas a pagar/receber; transactions é extrato de fatura, não obrigação financeira.
- **Unificação**: Manter lancamentos sem alteração estrutural. Ponto de encaixe do merge: as colunas órfãs fatura_conta_id/fatura_mes (00001:70-72) passam a ser escritas por uma feature nova 'fechar fatura' que gera 1 lançamento a pagar a partir do total de transações da fatura importada (funcionalidade que B não tinha e A só modelou). Nenhum dado de B migra para cá diretamente.

## 6. Transação de cartão/extrato (transação OFX)

- **Veredicto**: conflito
- **Lado A (rb7-financeiro)**: Tabela transacoes_ofx: conta_id NOT NULL FK contas CASCADE, fitid NOT NULL, data DATE NOT NULL, valor numeric(14,2) COM SINAL, memo, tipo_transacao, categoria_id FK categorias, lancamento_id FK lancamentos (conciliação, nunca escrito), UNIQUE(conta_id,fitid) para dedupe (A 00001:83-95). Import com upsert onConflict 'conta_id,fitid' ignoreDuplicates (src/pages/ImportarOfx.tsx:55-66). Sem flag de auto-categorização, sem vínculo a lote de import.
- **Lado B (categorizador-fatura)**: Tabela transactions: user_id NOT NULL, invoice_id FK invoices CASCADE, fit_id text SEM UNIQUE (reimport duplica), memo NOT NULL, amount numeric SEMPRE POSITIVO (Math.abs no parser, App.jsx:134; CREDIT>0 descartado, App.jsx:132), date TEXT 'DD/MM/YYYY' (App.jsx:130; migration.sql:95), category TEXT livre (não FK, migration.sql:96), auto_categorized boolean (B migration.sql:88-99).
- **Unificação**: Nome final: transacoes_ofx (estrutura de A vence em todos os eixos: date real, valor com sinal, categoria FK, dedupe por UNIQUE(conta_id,fitid)). Adicionar 2 colunas: fatura_id uuid FK faturas NULL (vínculo ao lote/fatura, vindo de B) e auto_categorizada boolean default false (vindo de B). Migração dos dados de B: date text → to_date(date,'DD/MM/YYYY'); amount → valor = -amount (todas eram despesas de cartão, sinal negativo restaura a semântica de A); category (nome) → categoria_id via tabela de-para de nomes; user_id morre (vira nada; auditoria não existia por linha); invoice_id → fatura_id; dedupe na carga por (conta_id, fitid) ficando com a ocorrência mais antiga (B tem duplicatas potenciais de reimport). Descartar: tabela transactions, date text, category text, amount absoluto, ausência de unique.

## 7. Fatura de cartão / lote de importação (invoice)

- **Veredicto**: semelhante
- **Lado A (rb7-financeiro)**: Não existe tabela; existem apenas colunas órfãs lancamentos.fatura_conta_id + fatura_mes ('agrupa lançamentos de cartão no contas a pagar', A 00001:70-72; types.ts:53-54) que nenhuma UI escreve — README orienta cadastrar fatura como lançamento manual.
- **Lado B (categorizador-fatura)**: Tabela invoices: user_id, name (nome do arquivo .ofx, App.jsx:745), total numeric e transaction_count int DENORMALIZADOS (snapshot do import, nunca recalculados — App.jsx:738,747), imported_at; SEM coluna de competência/mês (B migration.sql:72-79). 1 linha por import; delete CASCADE apaga transactions e purchase_items anexados sem confirmação (App.jsx:852-859; migration.sql:91,127).
- **Unificação**: Criar tabela nova faturas (PT): id uuid PK, conta_id uuid NOT NULL FK contas (o cartão), competencia date (1º dia do mês — alinhada a lancamentos.fatura_mes), nome_arquivo text, importado_em timestamptz, lancamento_id uuid FK lancamentos NULL (o lançamento a pagar gerado no fechamento). Migrar invoices de B: name→nome_arquivo, imported_at→importado_em, conta_id atribuído no de-para de cartões, competencia inferida do max(date) das transactions da invoice. DESCARTAR: total e transaction_count (passam a ser calculados por view/aggregate sobre transacoes_ofx.fatura_id — eram snapshots congelados e divergentes), user_id. A dupla (fatura_conta_id, fatura_mes) de lancamentos passa a casar com (conta_id, competencia) de faturas.

## 8. Categoria de transação/lançamento

- **Veredicto**: conflito
- **Lado A (rb7-financeiro)**: Tabela categorias GLOBAL (sem empresa_id, sem user_id): nome, tipo enum pagar|receber, cor text hex default '#6366f1', ativa (A 00001:45-52). Referenciada por FK em lancamentos.categoria_id e transacoes_ofx.categoria_id. Seed de 12 (9 pagar + 3 receber) com cores hex (00001:188-200). CRUD em src/pages/Categorias.tsx; sem UNIQUE em nome.
- **Lado B (categorizador-fatura)**: Tabela categories POR USUÁRIO: user_id NOT NULL, name, color_index int 0-9 → paleta TAG_COLORS no client (App.jsx:92-103), UNIQUE(user_id,name) (B migration.sql:41-48). Usada por NOME (texto livre) em transactions.category e auto_rules.category — não há FK. Seed client-side de 9 defaults no primeiro login (App.jsx:71-81, 588-607). Sem renomear/excluir.
- **Unificação**: Nome final: categorias (modelo A vence: global, FK, cor hex, tipo, ativa). Adicionar UNIQUE(nome, tipo) para sanear. Migrar as categorias de B como tipo='pagar' (todas são despesas de cartão) com de-para de nomes para evitar duplicação semântica: 'Tráfego Pago'→'Tráfego Pago' (já existe, 00001:189), 'Viagem'→'Viagens' (00001:193), 'Ferramenta'→'Software/Ferramentas' (00001:190), 'Imposto'→'Impostos' (00001:192); criar as sem equivalente ('Compras Online', 'Educação', 'Operacional', 'PF - Rafa', 'Taxa') convertendo color_index→cor hex aproximada da TAG_COLORS. Descartar: tabela categories, color_index, user_id, referência por texto (todas as colunas category text de B viram categoria_id FK na carga). Eliminar seed client-side — seed só via migration SQL.

## 9. Regra de auto-categorização (auto_rule)

- **Veredicto**: so_B
- **Lado A (rb7-financeiro)**: ausente — ImportarOfx só permite categorização manual inline pós-import (src/pages/ImportarOfx.tsx:144-146); nenhuma regra automática.
- **Lado B (categorizador-fatura)**: Tabela auto_rules: user_id NOT NULL, keywords text[] NOT NULL, category TEXT livre, SEM unique (seed pode duplicar) (B migration.sql:57-63). 62 DEFAULT_RULES hardcoded (App.jsx:6-69, linhas 7-68 — inventários citavam 64/69, contagem real é 62), seedadas no 1º login se vazio (App.jsx:617-624). Aplicação: substring match case-insensitive da primeira regra que casa, SÓ no momento do import (App.jsx:111-117, 133); select sem ORDER BY → ordem indeterminada (App.jsx:610-612); não aprende, sem UI de gestão.
- **Unificação**: Nome final: regras_categorizacao (PT, GLOBAL — compartilhada pela equipe, sem user_id): id, palavras_chave text[] NOT NULL, categoria_id uuid NOT NULL FK categorias (mata o texto livre), prioridade int NOT NULL (ordem de avaliação determinística — corrige o select sem order), ativa boolean default true, UNIQUE em palavras_chave ou em (categoria_id, palavras_chave) para impedir seed duplicado. Migrar: as 62 regras default + quaisquer regras já em produção (dedupe), category→categoria_id pelo mesmo de-para. Aplicar no fluxo de import OFX do app A. Descartar: user_id, category text, seed client-side. Avaliar limpar regras pessoais ('PF - Rafa', App.jsx:52-53) ou mantê-las como categoria própria.

## 10. Item de compra / anotação (purchase_item)

- **Veredicto**: so_B
- **Lado A (rb7-financeiro)**: ausente.
- **Lado B (categorizador-fatura)**: Tabela purchase_items. Schema versionado: user_id NOT NULL, invoice_id FK invoices CASCADE NOT NULL, description NOT NULL, amount numeric NULL, category text, created_at (B migration.sql:124-132). DRIFT CONFIRMADO: o código usa invoice_id NULL (compras pendentes — App.jsx:692, queries .is('invoice_id',null) em 671-672/682/787) e 3 colunas inexistentes nos SQLs: month text 'YYYY-MM' (App.jsx:696), purchase_date (App.jsx:697), payment_method (App.jsx:698) — produção recebeu ALTERs manuais não commitados. Regra de negócio: anotações NÃO entram em totais/dashboard (App.jsx:1243-1246). Modal de anexação de pendentes ao importar (App.jsx:805-822, 1350-1441).
- **Unificação**: Nome final: compras_anotadas (PT): id, fatura_id uuid FK faturas NULL (null = pendente, preserva o fluxo de pendentes), empresa_id uuid FK empresas NULL (atribuído quando anexada ou na criação), descricao text NOT NULL, valor numeric(14,2) NULL, categoria_compra_id uuid FK categorias_compras NULL, mes date NULL (converter 'YYYY-MM' → 1º dia do mês), data_compra date NULL, forma_pagamento text NULL, criado_por uuid FK perfis (substitui user_id como auditoria), criado_em. FONTE DO SCHEMA DE MIGRAÇÃO: o banco de produção de B (db pull), NUNCA os SQLs do repo (estão desatualizados). Corrigir na unificação a perda de dados de B: ao excluir fatura, compras anexadas devem voltar a pendentes (ON DELETE SET NULL em fatura_id) em vez do CASCADE atual que as destrói (migration.sql:127).

## 11. Categoria de compra (purchase_item_categories)

- **Veredicto**: so_B
- **Lado A (rb7-financeiro)**: ausente — A tem um único vocabulário de categorias (categorias).
- **Lado B (categorizador-fatura)**: Tabela purchase_item_categories: user_id NOT NULL, name, color_index, UNIQUE(user_id,name) (B migration.sql:108-115; duplicada literalmente em migration_purchase_items.sql:6-13). Vocabulário SEPARADO do de transactions por design. 5 defaults: Estrutura, Operacional, Material de escritório, Viagem, Educação (App.jsx:83-89). Referenciada por texto em purchase_items.category.
- **Unificação**: Nome final: categorias_compras (PT, GLOBAL, mantendo o vocabulário separado de categorias — design intencional de B): id, nome text NOT NULL UNIQUE, cor text hex, ativa boolean. Migrar as 5 defaults + customizadas de produção, color_index→cor hex. compras_anotadas.categoria_compra_id referencia por FK. Descartar: user_id, color_index, referência por texto, e o arquivo migration_purchase_items.sql inteiro (é patch duplicado de migration.sql:108-147 sem IF NOT EXISTS — rodar os dois num banco limpo falha).

## 12. Venda Hotmart

- **Veredicto**: so_A
- **Lado A (rb7-financeiro)**: Tabela vendas_hotmart: empresa_id NOT NULL, codigo_transacao UNIQUE global, produto, data_venda, data_liberacao, valor_bruto/taxa_hotmart/comissao_afiliado/comissao_coproducao/valor_liquido numeric(14,2), afiliado, coprodutor, meio_pagamento, status text livre, comprador (A 00001:101-122). Import CSV com upsert MERGE por codigo_transacao (src/pages/Hotmart.tsx:52-57); allowlist vendaAprovada (src/lib/hotmart.ts:78-82).
- **Lado B (categorizador-fatura)**: ausente.
- **Unificação**: Manter intacta. Nenhum dado de B toca este domínio. Melhorias opcionais fora do escopo do mapa (status como enum, proteção contra upsert trocar empresa_id silenciosamente — Hotmart.tsx:56).

## 13. Modelo de tenancy / RLS (eixo compartilhado-por-equipe vs isolado-por-usuário)

- **Veredicto**: conflito
- **Lado A (rb7-financeiro)**: RLS habilitado nas 7 tabelas (A 00001:150-156) com políticas FOR ALL TO authenticated USING(true) WITH CHECK(true) em todas as tabelas de negócio (00001:162-167) — equipe pequena compartilha tudo; NENHUMA tabela de negócio tem user_id; partição é empresa_id e só na UI; único vínculo a usuário é lancamentos.criado_por (auditoria, 00001:73).
- **Lado B (categorizador-fatura)**: RLS auth.uid()=user_id FOR ALL (sem WITH CHECK explícito) em todas as tabelas; user_id NOT NULL FK auth.users CASCADE em todas (B migration.sql:43,52-54,59,67-69,74,83-85,90,103-105,110,119-121,126,136-138). Quase nenhuma query do App.jsx filtra user_id explicitamente — confia 100% no RLS (única exceção: App.jsx:788).
- **Unificação**: DECISÃO CENTRAL DO MERGE — adotar o modelo de A (compartilhado por equipe, RLS 'to authenticated using(true)'): mesmo dono, time pequeno, e o app unificado é multi-empresa, não multi-tenant por usuário. Resolução concreta do eixo: user_id de B é SUBSTITUÍDO por empresa_id (partição de negócio, atribuída na migração) + criado_por FK perfis opcional (auditoria, padrão de lancamentos). Todas as policies auth.uid()=user_id de B morrem; tabelas novas (faturas, transacoes_ofx alterada, compras_anotadas, categorias_compras, regras_categorizacao) nascem com a mesma policy padrão de A. Consequência a aceitar explicitamente: dados antes privados por usuário em B ficam visíveis a toda a equipe. As novas migrations devem entrar APÓS 20260609180002, nunca editando 00001 (ordem é obrigatória).

## 14. Idioma e tipagem do schema (eixo PT vs EN, FK vs texto, date vs text)

- **Veredicto**: conflito
- **Lado A (rb7-financeiro)**: 100% PT-BR, enums nativos (tipo_lancamento, status_lancamento, tipo_conta, papel_usuario — A 00001:7-10), datas como DATE, dinheiro numeric(14,2), integridade por FK em tudo.
- **Lado B (categorizador-fatura)**: 100% EN, zero enums, datas de transação como TEXT 'DD/MM/YYYY' (migration.sql:95), mês como TEXT 'YYYY-MM' (drift), categorias por texto livre sem FK (migration.sql:61,96,130), numeric sem precisão definida.
- **Unificação**: Schema final 100% PT-BR (A é a base — React 19+TS+migrations ordenadas). Conversões obrigatórias na carga de B: transactions.date → to_date(_, 'DD/MM/YYYY'); purchase_items.month 'YYYY-MM' → date (1º dia); purchase_date 'YYYY-MM-DD' → date; todos os category/name texto → FKs via tabelas de-para; amount → numeric(14,2) com sinal restaurado. Descartar: todas as colunas text-que-deviam-ser-date/FK de B.

## 15. Parser OFX (código, não tabela — mas define o dado gravado)

- **Veredicto**: semelhante
- **Lado A (rb7-financeiro)**: src/lib/ofx.ts: regex por bloco <STMTTRN>, suporta SGML e XML (extrairTag para em quebra de linha OU '<', ofx.ts:10-15), DTPOSTED→'YYYY-MM-DD' (ofx.ts:17-22), TRNAMT com sinal preservado, MEMO com fallback NAME, TRNTYPE gravado; NÃO descarta créditos; sem auto-categorização; dedupe delegada ao banco.
- **Lado B (categorizador-fatura)**: App.jsx:119-137: regex <STMTTRN>...</STMTTRN> com fechamento obrigatório (linha 121), DTPOSTED→'DD/MM/YYYY' string (130), descarta TRNTYPE=CREDIT com valor>0 (pagamentos/estornos somem, 132), Math.abs no valor (134), decodifica &amp; no MEMO (127), auto-categoriza inline com as rules (133).
- **Unificação**: Manter o parser de A (ofx.ts) como único: preserva sinal, créditos e tipo, e o formato de fechamento opcional cobre mais bancos. Incorporar de B: decode de &amp; no memo e a etapa de auto-categorização (chamando regras_categorizacao após o parse, gravando auto_categorizada=true). Descartar parseOFX de B, o descarte de créditos e o Math.abs (estornos/pagamentos passam a existir no extrato unificado — créditos ficam visíveis e podem ser filtrados na UI da fatura).

## 16. Dedupe de importação por FITID

- **Veredicto**: conflito
- **Lado A (rb7-financeiro)**: UNIQUE(conta_id, fitid) no banco (A 00001:94) + upsert onConflict 'conta_id,fitid' ignoreDuplicates:true no import (src/pages/ImportarOfx.tsx:55-66) — reimportar o mesmo arquivo não duplica.
- **Lado B (categorizador-fatura)**: fit_id gravado (App.jsx:758) mas NUNCA comparado; sem unique constraint (migration.sql:92); handleFile sempre cria invoice nova e insere tudo (App.jsx:734-769) — reimportar duplica fatura e lançamentos.
- **Unificação**: Modelo de A vence integralmente. Na carga dos dados de B: deduplicar transactions por (conta_id_atribuído, fit_id) mantendo a mais antiga e descartando duplicatas de reimport; faturas que ficarem vazias após o dedupe são removidas. fit_id vazio (FITID ausente no OFX) precisa de tratamento: A exige fitid NOT NULL (00001:86) — gerar fitid sintético determinístico (hash de data+valor+memo) para linhas de B sem fit_id.

## 17. Fluxo de autenticação

- **Veredicto**: conflito
- **Lado A (rb7-financeiro)**: Só signInWithPassword (src/pages/Login.tsx:14); sem signup/reset/OAuth — usuários criados pelo admin no painel (Login.tsx:54-56). Sessão em AppContext (getSession + onAuthStateChange, src/contexts/AppContext.tsx:26-33).
- **Lado B (categorizador-fatura)**: Login + SIGNUP públicos com confirmação por e-mail (src/components/Auth.jsx:19-26), senha mínima 6 só no HTML (Auth.jsx:77); sem reset/OAuth. Copy de privacidade do rodapé (Auth.jsx:101-104) e README ('sem banco de dados') são falsos na versão atual.
- **Unificação**: Adotar o modelo de A (sem signup público — app interno de equipe; signup aberto seria furo grave combinado com RLS using(true)). Descartar Auth.jsx e desabilitar signup no projeto Supabase unificado. Usuários de B que continuarem são recriados/convidados pelo admin e ganham perfil via trigger de A.

## 18. Seeds e disciplina de migrations

- **Veredicto**: conflito
- **Lado A (rb7-financeiro)**: Seed 100% em SQL versionado (00001:169-200); 3 migrations ordenadas e a ordem é obrigatória (20260609175517 e 20260609180002 alteram objetos de 00001).
- **Lado B (categorizador-fatura)**: Seed client-side no 1º login com check-then-insert sem lock (App.jsx:572-676) — StrictMode pode duplicar auto_rules (sem unique); migrations aplicadas à mão fora do repo (drift de purchase_items confirmado: App.jsx:692-698 vs migration.sql:124-132); migration_purchase_items.sql é redeclaração conflitante de migration.sql:108-147.
- **Unificação**: Padrão de A vence: todo seed e DDL do merge entram como novas migrations numeradas após 20260609180002 no repo rb7-financeiro (ex.: 2026xxxx_merge_categorizador.sql com faturas, alterações de transacoes_ofx, regras_categorizacao, categorias_compras, compras_anotadas, seeds de-para). Descartar: todo seed client-side de B, migration_purchase_items.sql, e os SQLs de B como fonte de schema (usar supabase db pull do projeto de produção de B para extrair o schema real, incluindo as colunas month/purchase_date/payment_method e o invoice_id nullable).

## Observações gerais da auditoria

Base técnica do app unificado: rb7-financeiro (React 19 + TS + Tailwind 4 + Vite 8, migrations ordenadas, projeto Supabase ref qnjjipkqjcmsmumcqltg — C:/Users/luizrog3rio/projetos/rb7-financeiro/README.md:19). Tudo de B vira migração de dados + 2 features portadas (auto-categorização e compras anotadas) + 1 tabela nova (faturas) que finalmente dá uso às colunas órfãs lancamentos.fatura_conta_id/fatura_mes e transacoes_ofx.lancamento_id de A.

PRÉ-REQUISITO BLOQUEANTE do plano de migração de dados: extrair o schema REAL do banco de produção do categorizador-fatura via supabase db pull/introspecção — o drift está confirmado em código (C:/Users/luizrog3rio/projetos/categorizador-fatura/src/App.jsx:692 insere invoice_id null; :696-698 inserem month/purchase_date/payment_method) contra os DDLs do repo que declaram invoice_id NOT NULL e não têm essas colunas (supabase/migration.sql:124-132; supabase/migration_purchase_items.sql:21-29). Os SQLs do repo de B NÃO são fonte da verdade.

Correção factual aos inventários: DEFAULT_RULES tem 62 regras (App.jsx linhas 7-68, contagem direta), não 64 nem 69.

Decisões que o orquestrador precisa ratificar com o dono: (1) empresa_id de destino dos dados de B (sugerido RB7 Digital — as regras citam fornecedores da operação RB7) e o de-para invoice→conta de cartão; (2) aceitar que dados antes privados por user_id ficam visíveis à equipe toda (consequência do modelo using(true)); (3) destino da categoria pessoal 'PF - Rafa' (App.jsx:52-53,77); (4) de-para de categorias proposto (Viagem→Viagens, Ferramenta→Software/Ferramentas, Imposto→Impostos, Tráfego Pago→Tráfego Pago; criar Compras Online/Educação/Operacional/PF - Rafa/Taxa).

Riscos colaterais do merge a endereçar no plano: (a) regra de saldo de A 'qualquer OFX descarta lançamentos pagos' (src/pages/Contas.tsx:58-59) — transações de cartão migradas de B mudariam saldos se caíssem em contas erradas; usar contas cartao_credito dedicadas; (b) créditos/estornos de B foram destruídos no parse (descartados + Math.abs, App.jsx:132-134) — dados históricos de B não têm estornos, impossível recuperá-los; documentar a lacuna; (c) hoje() de A usa UTC (src/lib/format.ts:10) — bug de fuso pré-existente que afeta status atrasado; (d) fit_id de B pode ser vazio e A exige fitid NOT NULL — gerar fitid sintético determinístico; (e) trigger/função handle_new_user e trigger on_auth_user_created têm nomes idênticos nos dois projetos — se a migração de dados for feita apontando o app B para o projeto de A em algum estágio intermediário, jamais aplicar o migration.sql de B lá; (f) env vars divergentes: A usa VITE_SUPABASE_ANON_KEY (src/lib/supabase.ts:12, .env.example), B usa VITE_SUPABASE_PUBLISHABLE_KEY (src/lib/supabase.js:1-6) — atualizar Vercel se o front unificado for para lá; (g) export XLSX de B depende de CDN runtime (App.jsx:144-156, xlsx 0.18.5 via cdnjs, não é dep npm) — se a feature de export for portada, empacotar como dependência; (h) B não trata erro em ~18 chamadas Supabase (updates otimistas) — nada disso deve ser portado como está.

Arquivos-fonte verificados nesta análise: C:/Users/luizrog3rio/projetos/rb7-financeiro/supabase/migrations/00001_schema.sql, .../20260609180002_hardening_advisors.sql, C:/Users/luizrog3rio/projetos/rb7-financeiro/src/lib/types.ts, C:/Users/luizrog3rio/projetos/categorizador-fatura/supabase/migration.sql, .../migration_purchase_items.sql, C:/Users/luizrog3rio/projetos/categorizador-fatura/src/App.jsx (linhas 1-160 e 680-810 lidas diretamente; restante conforme inventários fornecidos).
