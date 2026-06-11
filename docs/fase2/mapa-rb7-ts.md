# MAPEAMENTO COMPLETO — rb7-financeiro (C:\Users\luizrog3rio\projetos\rb7-financeiro)

## RAIZ / BUILD

### package.json
- Nome `rb7-financeiro` v0.1.0, `"type": "module"`. Scripts: `dev`=vite, `build`=`tsc -b && vite build`, `lint`=eslint, `preview`.
- Dependencies: `@supabase/supabase-js ^2.49.0`, `lucide-react ^0.468.0`, `react ^19.2.6`, `react-dom ^19.2.6`, `react-router-dom ^7.1.0`, `recharts ^2.15.0`.
- DevDeps relevantes: `tailwindcss ^4.1.0` + `@tailwindcss/vite ^4.1.0` (Tailwind v4 — SEM tailwind.config.js, plugin no Vite), `vite ^8.0.12`, `typescript ~6.0.2`, `@vitejs/plugin-react ^6.0.1`, eslint 10 + typescript-eslint + react-hooks/react-refresh plugins.

### vite.config.ts (8 linhas)
- `defineConfig({ plugins: [react(), tailwindcss()] })`. Nada mais — sem alias, sem proxy, sem define. Tailwind v4 entra via plugin `@tailwindcss/vite` (não há postcss.config nem tailwind.config na raiz; confirmado, não existem).

### index.html
- Título `rb7-financeiro` (linha 7), favicon `/favicon.svg` (public/ tem favicon.svg e icons.svg), monta `#root` e carrega `/src/main.tsx`. `lang="en"` (linha 2 — trocar pra pt-BR se quiser).

### tsconfig.json / tsconfig.app.json / tsconfig.node.json
- Project references (app + node). App: target es2023, `moduleResolution: bundler`, `verbatimModuleSyntax: true` (obriga `import type`), `noEmit`, `jsx: react-jsx`, `erasableSyntaxOnly`, `noUnusedLocals/Parameters`, `types: ["vite/client"]`, include `src`. Node: igual, types node, include só vite.config.ts.

### .env.example
- `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY` ← **divergência direta com o categorizador, que usa `VITE_SUPABASE_PUBLISHABLE_KEY`**.

---

## src/main.tsx
- Bootstrap padrão: `createRoot(#root)` + `<StrictMode><App/></StrictMode>`, importa `./index.css`. Sem acoplamento.

## src/index.css
- `@import "tailwindcss";` (sintaxe Tailwind v4) + `body { @apply bg-slate-100 text-slate-900 antialiased; }`. É TODO o CSS global.

## src/App.css
- Vazio (só comentário "estilos via Tailwind em index.css"). Não é importado por ninguém — pode ser deletado.

## src/App.tsx
- Papel: roteamento + gate de auth. Export default `App` (BrowserRouter > AppProvider > Rotas).
- `Rotas()` (linhas 12–38): se `carregando` → tela "Carregando…"; se `!session` → `<Login/>`; senão `<Routes>` aninhadas em `<Route element={<Layout/>}>`:
  - `/` → Dashboard
  - `/pagar` → `<Lancamentos key="pagar" tipo="pagar"/>` (linha 29 — note o `key` pra forçar remount entre tipos)
  - `/receber` → `<Lancamentos key="receber" tipo="receber"/>`
  - `/contas` → Contas
  - `/ofx` → ImportarOfx
  - `/hotmart` → Hotmart
  - `/categorias` → Categorias
- Sem rota 404, sem rota de signup (usuários criados pelo admin — ver Login).

## src/lib/supabase.ts
- Cria client com `import.meta.env.VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` (linhas 3–4); `console.warn` se faltar; `createClient(url ?? '', anonKey ?? '')`. **ADAPTAR: trocar pra `VITE_SUPABASE_PUBLISHABLE_KEY`** (linhas 4, 8).

## src/lib/types.ts (íntegra conceitual)
- Type aliases (linhas 1–4):
  - `TipoLancamento = 'pagar' | 'receber'` → enum EN da Fase 1c: `payable | receivable`
  - `StatusLancamento = 'pendente' | 'pago' | 'atrasado' | 'cancelado'` → `pending | paid | overdue | cancelled`
  - `TipoConta = 'corrente' | 'cartao_credito' | 'inter_empresa'` → `checking | credit_card | inter_company`
  - `PapelUsuario = 'admin' | 'operador'`
- Interfaces:
  - `Perfil { id, nome, papel }` (tabela `perfis` → `profiles` viva do categorizador; verificar colunas reais)
  - `Empresa { id, nome, cnpj|null }` → `companies`
  - `Conta { id, empresa_id, nome, tipo: TipoConta, banco|null, saldo_inicial: number, empresa_contraparte_id|null, dia_fechamento|null, dia_vencimento|null, ativa: boolean }` → `accounts`
  - `Categoria { id, nome, tipo: TipoLancamento, cor, ativa }` → `categories` (viva, PT — colunas do banco vivo a confirmar; categorias do categorizador foram criadas pra fatura, modelo pode divergir: lá não há `tipo` pagar/receber necessariamente)
  - `Lancamento { id, empresa_id, conta_id|null, categoria_id|null, tipo, descricao, valor, data_emissao, data_vencimento, data_pagamento|null, status, fornecedor_cliente|null, observacoes|null, fatura_conta_id|null, fatura_mes|null, categoria?: Categoria|null, conta?: Conta|null }` → `entries`. Note os DOIS FKs pra contas (`conta_id` e `fatura_conta_id`) — raiz do PGRST201.
  - `TransacaoOfx { id, conta_id, fitid, data, valor, memo|null, tipo_transacao|null, categoria_id|null, lancamento_id|null, categoria? }` → `bank_transactions`. **Não confundir com `transactions` (fatura/PT viva) do categorizador.**
  - `VendaHotmart { id, empresa_id, codigo_transacao, produto, data_venda, data_liberacao|null, valor_bruto, taxa_hotmart, comissao_afiliado, comissao_coproducao, valor_liquido, afiliado|null, coprodutor|null, meio_pagamento|null, status, comprador|null }` → `hotmart_sales`.
- Campos `valor`/numéricos vêm como string do PostgREST em vários pontos — o código defende com `Number(...)` em todo lugar (padrão a manter).

## src/lib/format.ts
- `fmtBRL(v)` — toLocaleString pt-BR currency.
- `fmtData(iso)` — fatia YYYY-MM-DD → DD/MM/YYYY sem criar Date (evita bug de timezone); retorna '—' pra null.
- `hoje()`, `primeiroDiaMes()`, `ultimoDiaMes()` — strings ISO date. ATENÇÃO: `hoje()` usa `toISOString()` = UTC; perto da meia-noite BRT pode dar o dia seguinte (comportamento herdado, não corrigido).

## src/lib/ofx.ts (parser OFX)
- Export: interface `OfxTransacao { fitid, data, valor, memo, tipo }` e `parseOfx(conteudo): OfxTransacao[]`.
- Como parseia: split por `<STMTTRN>` (case-insensitive, linha 26), corta no `</STMTTRN>` se existir; `extrairTag` (linhas 10–15) com regex `<TAG>([^<\r\n]*)` — **suporta SGML (sem fechamento de tag) E XML**, edge case principal do OFX de banco BR.
- `parseDataOfx` (linhas 17–22): pega só YYYYMMDD do formato `YYYYMMDDHHMMSS[.XXX][TZ]`.
- Valor: `TRNAMT` com `replace(',', '.')` (linha 31) — aceita decimal com vírgula (Sicredi/C6).
- memo: fallback `MEMO || NAME` (linha 33). Descarta transação se faltar fitid/data ou valor NaN (linha 35).
- O que NÃO faz: não lê BANKACCTFROM/CCACCTFROM, não distingue extrato de fatura de cartão, não trata encoding (assume `file.text()` UTF-8 — OFX Sicoob costuma ser Latin-1/Windows-1252: o App.jsx atual do categorizador pode ter tratamento próprio; verificar no cutover). **Não resolve o problema do fit_id Sicoob** (FITID derivado de data+valor; o dedupe `onConflict: 'conta_id,fitid'` do ImportarOfx descartaria parcelas legítimas se aplicado ao fluxo de fatura do categorizador — ok para extrato corrente, perigoso para fatura).

## src/lib/hotmart.ts (parser CSV Hotmart)
- Exports: `VendaHotmartImportada` (espelho de VendaHotmart sem id/empresa_id), `vendaAprovada(status)`, `parseHotmartCSV(text): { vendas, erros }`.
- `parseCSV` (linhas 22–41): parser CSV caractere-a-caractere com suporte a aspas, aspas escapadas (`""`), `\r\n`, e separador autodetectado.
- `detectarSeparador` (43–46): conta `;` vs `,` na primeira linha (Hotmart pt-BR exporta com `;`).
- `idxPor` (48–53): localiza colunas por palavras-chave case-insensitive (headers variam por idioma/versão): transa(ção/ction), produto/product, data/date, bruto/gross, taxa, comiss+afili, comiss+coprod, líquido/liquido/net, afiliado/affiliate, coprodutor, pagamento/payment, status, comprador/buyer, libera(ção).
- `parseValor` (55–65) — **ponto corrigido na auditoria**: heurística BR vs US: se termina em `,\d{1,2}` → formato BR (remove `.` milhar, vírgula vira ponto); se for `1.234`/`12.345.678` (grupos de 3 com ponto) → milhar BR sem decimais, remove pontos (o bug antigo lia 1.234 como 1,234); senão remove vírgulas (US). Strip de tudo que não é dígito/`.`/`,`/`-` (aceita "R$ ").
- `parseData` (67–76): YYYY-MM-DD, DD/MM/YYYY, fallback `new Date()`.
- `vendaAprovada` (80–82) — **ponto corrigido na auditoria**: ALLOWLIST `/aprovad|complet|conclu|approved/i` (a denylist anterior deixava passar WAITING_PAYMENT, BILLET_PRINTED, EXPIRED como receita).
- `parseHotmartCSV` (84–138): exige coluna de código e data (senão erro fatal); linha sem código/data vira aviso e é pulada (linha 114); `valor_liquido` calculado como `bruto - taxa - comAf - comCo` se a coluna não existir (linha 119); defaults: produto='Produto', status='aprovada'.

## src/contexts/AppContext.tsx
- Papel: contexto global de auth + multi-empresa. Exports: `AppProvider`, `useApp`.
- Shape `AppCtx` (linhas 7–15): `session`, `carregando`, `perfil`, `empresas`, **`empresaAtiva: Empresa | null` (null = CONSOLIDADO/todas as empresas)**, `setEmpresaAtiva`, `recarregarEmpresas`.
- Auth (26–33): `supabase.auth.getSession()` + `onAuthStateChange` com unsubscribe.
- Queries:
  - linha 36: `from('empresas').select('*').order('nome')` → estado `empresas`
  - linhas 44–48: `from('perfis').select('*').eq('id', session.user.id).single()` → `perfil`
- `empresaAtiva` é só estado em memória (não persiste em localStorage). TODO consumidor de página filtra com `if (empresaAtiva) q = q.eq('empresa_id', empresaAtiva.id)` — o padrão "consolidado" é a AUSÊNCIA do filtro.

## src/components/Layout.tsx
- Papel: shell com sidebar fixa. Export default `Layout` (usa `<Outlet/>`).
- Sidebar `w-60 bg-slate-900` fixa (`fixed inset-y-0`), main com `ml-60` (linha 78).
- Nav (linhas 15–23): 7 itens com lucide icons — LayoutDashboard, ArrowDownCircle (Pagar), ArrowUpCircle (Receber), Landmark (Contas), FileDown (OFX), ShoppingCart (Hotmart), Tags (Categorias).
- **Seletor de empresa** (linhas 35–53): `<select>` com option vazia "Consolidado (todas)" + empresas; `setEmpresaAtiva(empresas.find(...) ?? null)`.
- Mostra `perfil?.nome` no header (linha 33); botão Sair → `supabase.auth.signOut()` (linha 72).
- NavLink ativo: `bg-indigo-600 text-white`; tema indigo/slate em todo o app.

## src/components/ui.tsx (design system mínimo)
- `Card` — `bg-white rounded-xl shadow-sm border border-slate-200`.
- `PageHeader { titulo, subtitulo?, acao? }` — h2 2xl bold + slot de ação.
- `Badge { children, cor }` — pill com `backgroundColor: cor+'22'` (alpha hex) e `color: cor`.
- `StatusBadge { status }` — mapas hardcoded (linhas 42–54): cores `pendente:#f59e0b, pago:#22c55e, atrasado:#ef4444, cancelado:#94a3b8` e rótulos PT. **Se o enum virar EN (pending/paid/overdue/cancelled), esses dois Records precisam trocar as CHAVES mantendo rótulos PT.**
- `Vazio { mensagem }` — empty state.
- Strings de classe exportadas: `inputCls`, `btnPrimario` (indigo-600), `btnSecundario`.
- `Modal { titulo, aberto, onFechar, children }` — overlay `bg-black/40`, painel `max-w-lg max-h-[90vh]`, fecha no backdrop.

## src/pages/Login.tsx
- Papel: tela de login email/senha. SÓ `signInWithPassword` (linha 14) — **NÃO tem signup nem reset de senha**; texto na linha 55: "Usuários são criados pelo administrador no painel do Supabase". Erro genérico "E-mail ou senha inválidos."
- Adaptação: o categorizador tem signup com confirmação (commit recente "mensagem de signup pós-confirmação desligada + favicon") — decidir se o fluxo de signup do categorizador sobrevive ou se adota o modelo admin-cria.

## src/pages/Dashboard.tsx
- Papel: KPIs + gráficos recharts + próximos vencimentos.
- Queries (em `carregar`, useCallback dep `[empresaAtiva]`):
  - linhas 32–38: `from('lancamentos').select('*, categoria:categorias(*)').neq('status','cancelado').gte('data_vencimento', inicio).lte('data_vencimento', fimStr)` + `.eq('empresa_id', empresaAtiva.id)` se empresa ativa. Janela: mês-5 até mês+2.
  - linha 42: `from('vendas_hotmart').select('*').gte('data_venda', inicio)` + filtro empresa opcional.
- KPIs (52–68): aReceber/aPagar do mês (status != pago), atrasados (status atrasado OU pendente vencido — linha 58), hotmartMes (líquido com `vendaAprovada`), **aLiberar** (líquido com `data_liberacao >= hoje` — "previsibilidade de saque", linhas 64–66).
- Gráficos: `BarChart` fluxo mensal por vencimento (receber verde #22c55e / pagar vermelho #ef4444, radius [4,4,0,0], YAxis em 'k'), `PieChart` donut despesas do mês por categoria (cores da categoria, innerRadius 55/outerRadius 95). `ResponsiveContainer height={260}`.
- Lista "Próximos vencimentos": 8 itens não pagos futuros.
- Status hardcoded PT nas comparações: `'cancelado'` (linha 35), `'pago'` (54, 56, 98), `'atrasado'`/`'pendente'` (58); tipos `'receber'`/`'pagar'` (54, 56, 76, 86).

## src/pages/Lancamentos.tsx
- Papel: CRUD de contas a pagar/receber (componente único parametrizado por prop `tipo`).
- Queries:
  - linhas 47–56 (carregar): `from('lancamentos').select('*, categoria:categorias(*), conta:contas!conta_id(*)').eq('tipo', tipo).order('data_vencimento')` + filtros opcionais `.eq('empresa_id', ...)` e `.eq('status', filtroStatus)`. **PONTO CORRIGIDO NA AUDITORIA (comentário linhas 49–50): o hint `!conta_id` é obrigatório porque lancamentos tem 2 FKs pra contas (conta_id e fatura_conta_id) — sem o hint, PostgREST devolve PGRST201 (embed ambíguo). Em entries (EN) o mesmo hint vira `accounts!account_id` se a tabela nova mantiver os dois FKs.**
  - linha 65: `from('categorias').select('*').eq('tipo', tipo).eq('ativa', true).order('nome')`
  - linha 67: `from('contas').select('*').eq('ativa', true).order('nome')` (sem filtro de empresa — filtra client-side no select do form, linha 279)
  - linha 111: `from('lancamentos').update(payload).eq('id', form.id)`
  - linha 112: `from('lancamentos').insert(payload)` — payload (96–110): empresa_id, conta_id|null, categoria_id|null, tipo, descricao, valor (`parseFloat(form.valor.replace(',', '.'))` — aceita vírgula), data_emissao, data_vencimento, data_pagamento|null, **status derivado client-side** (linha 106: pago se tem data_pagamento; atrasado se vencimento < hoje; senão pendente), fornecedor_cliente|null, observacoes|null, **`criado_por: session?.user.id` só no insert** (linha 109).
  - linhas 119–122 (marcarPago): `update({ data_pagamento: hoje(), status: 'pago' })`
  - linha 128 (excluir): `.delete().eq('id', l.id)` com `confirm()` nativo.
- UI: 3 cards de totais (aberto/atrasado/pago), filtro de status, tabela com Badge de categoria + StatusBadge + ações (CheckCircle2 marcar pago, Pencil editar, Trash2 excluir), Modal de form grid 2 colunas. Rótulo pago vira "Recebido" quando tipo=receber.
- Usa `session` do useApp (linha 37) — acoplamento com criado_por (em EN: `created_by`).

## src/pages/Contas.tsx
- Papel: CRUD de contas/cartões com cálculo de saldo client-side.
- Queries (carregar, 34–62):
  - linha 35: `from('contas').select('*').order('nome')` + filtro empresa opcional
  - linhas 42–43: `from('transacoes_ofx').select('conta_id, valor').in('conta_id', ids)`
  - linhas 44–45: `from('lancamentos').select('conta_id, tipo, valor').eq('status','pago').in('conta_id', ids)`
  - **Regra de saldo (linha 59, comentário 40 e 58): saldo = saldo_inicial + (se há OFX importado pra conta, soma do OFX é a fonte da verdade; SENÃO soma dos lançamentos pagos, pagar negativo / receber positivo).**
  - linha 78: `from('contas').update(payload).eq('id', form.id)`; linha 79: `.insert(payload)` — payload (68–77): empresa_id, nome, tipo, banco|null, saldo_inicial (parseFloat com vírgula), dia_fechamento|null, dia_vencimento|null, ativa.
- UI: grid de cards com ícone por tipo (Landmark/CreditCard/ArrowLeftRight, linhas 13–17), rótulos PT por tipo (19–23 — **chaves precisam virar checking/credit_card/inter_company**), saldo vermelho se negativo, nota "Fecha dia X · vence dia Y" pra cartão, opacity-50 se inativa. Form mostra dia_fechamento/dia_vencimento só quando tipo=cartao_credito (linha 174).
- NOTA: o form NÃO expõe `empresa_contraparte_id` (existe no schema/types mas não é editável na UI).

## src/pages/ImportarOfx.tsx
- Papel: importar OFX de conta corrente (Sicredi/C6) + categorizar transações inline.
- Queries:
  - linha 20: `from('contas').select('*').eq('ativa', true).neq('tipo','inter_empresa').order('nome')` + filtro empresa opcional (exclui contas inter-empresa do import)
  - linha 26: `from('categorias').select('*').eq('ativa', true).order('nome')`
  - linhas 33–38 (carregarTransacoes): `from('transacoes_ofx').select('*, categoria:categorias(*)').eq('conta_id', contaSelecionada).order('data', {ascending:false}).limit(300)`
  - linhas 63–66 (importar): `from('transacoes_ofx').upsert(linhas, { onConflict: 'conta_id,fitid', ignoreDuplicates: true }).select('id')` — linhas montadas de `parseOfx` (conta_id, fitid, data, valor, memo|null, tipo_transacao|null). Mensagem reporta "X no arquivo · Y novas (duplicadas ignoradas)".
  - linha 74 (categorizar): `from('transacoes_ofx').update({ categoria_id: categoriaId || null }).eq('id', t.id)`
- UI: select de conta destino + label-as-button com `<input type="file" accept=".ofx,.OFX,.qfx" className="hidden">` (reseta `e.target.value` pós-import, linha 102); tabela com valor verde/vermelho por sinal e select "Categorizar…" filtrado por tipo da categoria conforme sinal do valor (linha 145: negativo→pagar, positivo→receber); botão × pra descategorizar.
- **ATENÇÃO ao adaptar**: o dedupe `conta_id,fitid` com `ignoreDuplicates: true` é seguro pra EXTRATO corrente, mas é exatamente o anti-padrão pro fluxo de FATURA do categorizador (fit_id Sicoob repete entre parcelas legítimas — R$ 22.475,33 em jogo). O fluxo de fatura existente (tabelas `invoices`/`transactions`) NÃO deve ser substituído por este import; são dois fluxos distintos (bank_transactions = extrato; transactions = fatura).

## src/pages/Hotmart.tsx
- Papel: importar CSV Hotmart + conciliação bruto/líquido.
- Queries:
  - linha 23 (carregar): `from('vendas_hotmart').select('*').order('data_venda', {ascending:false}).limit(500)` + filtro empresa opcional + filtro de mês `gte/lte data_venda` (25–29, calcula último dia do mês).
  - linhas 54–57 (importar): `from('vendas_hotmart').upsert(linhas, { onConflict: 'codigo_transacao' }).select('id')` — **DOIS pontos corrigidos na auditoria, comentados no código**: (1) linhas 48–51: dedupe no lote via `Map` por codigo_transacao (última ocorrência vence) — sem isso, código repetido no mesmo arquivo derruba o upsert inteiro com erro 21000 do Postgres ("cannot affect row a second time"); (2) linhas 52–53: upsert em modo MERGE (sem ignoreDuplicates) de propósito — re-importar CSV mais novo atualiza status de vendas existentes (reembolso/chargeback refletem).
  - Linhas levam `empresa_id: empresaDestino` (select próprio, default empresaAtiva ?? primeira empresa, linhas 18–20).
- Totais (68–77): filtrados por `vendaAprovada` — qtd, bruto, taxas, afiliados (afiliado+coprodução somados), líquido. 5 KPI cards + tabela com filtro `<input type="month">`.

---

## ADAPTAÇÕES OBRIGATÓRIAS (consolidado)

1. **Env var** — `src/lib/supabase.ts:4` (e warning na :8) e `.env.example`: `VITE_SUPABASE_ANON_KEY` → `VITE_SUPABASE_PUBLISHABLE_KEY`. URL mantém o nome.

2. **Renomes de tabela PT→EN** (todas as ocorrências `.from(...)`):
   - `empresas` → `companies`: AppContext.tsx:36
   - `perfis` → `profiles` (tabela PT VIVA do categorizador — manter nome PT): AppContext.tsx:44. Verificar colunas reais de profiles no banco vivo (o tipo `Perfil` espera `nome`/`papel`; profiles do categorizador pode não ter `papel`).
   - `contas` → `accounts`: Lancamentos.tsx:67, Contas.tsx:35/78/79, ImportarOfx.tsx:20
   - `categorias` → `categories` (tabela PT VIVA): AppContext n/a; Lancamentos.tsx:65, Categorias.tsx:15/23/24, ImportarOfx.tsx:26, e TODOS os embeds `categoria:categorias(*)` (Dashboard:34, Lancamentos:51, ImportarOfx:35) → `categoria:categories(*)`. ATENÇÃO: o modelo `Categoria` do rb7 tem `tipo`('pagar'|'receber'), `cor`, `ativa` — conferir se a `categories` viva do categorizador (12 seeds pós-consolidação) tem essas colunas ou se precisa de migration aditiva (Fase 1c/3).
   - `lancamentos` → `entries`: Dashboard.tsx:33, Lancamentos.tsx:48/111/112/120/128, Contas.tsx:45
   - `transacoes_ofx` → `bank_transactions`: Contas.tsx:43, ImportarOfx.tsx:34/64/74. NÃO confundir com `transactions` (fatura, PT viva).
   - `vendas_hotmart` → `hotmart_sales`: Dashboard.tsx:42, Hotmart.tsx:23/56

3. **Renomes de coluna PT→EN** (conforme schema EN da Fase 1c — confirmar nomes exatos via `mcp__supabase__list_tables` antes de codar): empresa_id→company_id, conta_id→account_id, categoria_id→category_id, descricao/valor/data_emissao/data_vencimento/data_pagamento/fornecedor_cliente/observacoes/fatura_conta_id/fatura_mes/criado_por, nome/tipo/banco/saldo_inicial/dia_fechamento/dia_vencimento/ativa, fitid/data/memo/tipo_transacao/lancamento_id, codigo_transacao/produto/data_venda/data_liberacao/valor_bruto/taxa_hotmart/comissao_afiliado/comissao_coproducao/valor_liquido/afiliado/coprodutor/meio_pagamento/comprador. Afeta: types.ts inteiro, todos os `.select/.eq/.order/.gte/.lte/.in` listados acima, payloads de insert/update/upsert, e os `onConflict` ('conta_id,fitid' → 'account_id,fitid'; 'codigo_transacao' → coluna EN equivalente).

4. **Valores de enum PT→EN** (hardcoded em MUITOS pontos — grep por literais):
   - tipo: `'pagar'`/`'receber'` → `payable`/`receivable` — App.tsx:29-30 (props), types.ts:1, Dashboard:54/56/76/86, Lancamentos (prop `tipo`, query :52, payload :100, rótulos :141/175/285), Categorias:11/29/43/81-84, ImportarOfx:145, ui.tsx (nada), Contas:51.
   - status: `'pendente'/'pago'/'atrasado'/'cancelado'` → `pending/paid/overdue/cancelled` — ui.tsx:42-54 (chaves dos Records coresStatus/rotulosStatus, MANTER rótulos PT), Dashboard:35/54/56/58/98, Lancamentos:106/121/133-137/172-177/217, Contas:45.
   - tipo de conta: `'corrente'/'cartao_credito'/'inter_empresa'` → `checking/credit_card/inter_company` — types.ts:3, Contas.tsx:13-23 (chaves de icones/rotulos)/32/160-164/174, ImportarOfx:20.
   - Estratégia alternativa: criar camada de mapeamento (labels PT por valor EN) em vez de espalhar — os Records de ui.tsx e Contas.tsx já são o lugar natural.

5. **Embed PGRST201** — Lancamentos.tsx:51: manter o hint disambiguador no schema novo: `conta:accounts!account_id(*)` (entries terá account_id e fatura/invoice_account_id como 2 FKs pra accounts). Sem o hint, quebra em runtime com PGRST201.

6. **Auth/RLS/perfil**:
   - Login.tsx só tem signInWithPassword; o categorizador tem signup ativo — decidir o fluxo (provável: manter login-only no app de equipe ou portar o signup do categorizador). `handle_new_user` do categorizador precisa do fix de search_path (Fase 1a; o fix já existe pronto em rb7-financeiro/supabase/migrations/20260609175517_fix_handle_new_user_search_path.sql, e o hardening de privilégio de coluna em 20260609180002_hardening_advisors.sql — reaproveitáveis).
   - Com RLS `using(true)` (modelo equipe), nenhuma query precisa de `.eq('user_id', ...)` — o código rb7 já NÃO filtra por user em lugar nenhum (compatível). Único uso de user id: `criado_por` no insert de Lancamentos.tsx:109.

7. **Contexto de empresa**: `empresaAtiva === null` = consolidado; o padrão é filtro condicional `if (empresaAtiva) q = q.eq('empresa_id', ...)` em Dashboard:38/43, Lancamentos:54, Contas:36, ImportarOfx:21, Hotmart:24. Toda página NOVA portada do categorizador (faturas/transactions/purchase_items) precisa decidir como se encaixa nesse filtro — `invoices` ganhou `account_id` na Fase 1c, então o filtro de empresa pode propagar via invoices→accounts→company_id.

8. **Funcionalidades do categorizador SEM equivalente no rb7 (precisam ser portadas pra dentro desta base, não existem aqui)**: parser OFX de FATURA Sicoob (o ofx.ts atual é p/ extrato; não trata encoding Latin-1 nem o fit_id não-único do Sicoob), auto_rules/categorização automática, purchase_items + purchase_item_categories (aba Compras), invoices/transactions. O upsert `ignoreDuplicates` por (conta,fitid) de ImportarOfx.tsx:65 NÃO pode ser usado no fluxo de fatura.

9. **Cosmético/estrutural**: index.html título "rb7-financeiro" e `lang="en"` → trocar; favicon do categorizador (commit 84e1170) deve prevalecer; Layout.tsx:32 "RB7 Financeiro" (nome do app a decidir); App.css morto (deletar); Tailwind v4 via plugin Vite — se o categorizador estiver em Tailwind v3 com config, a migração de build é trocar pro modelo v4 (`@import "tailwindcss"` + `@tailwindcss/vite`); React 19 + react-router-dom 7 + recharts 2.15 + lucide são as versões alvo.

10. **Nomes de rota**: rotas atuais `/`, `/pagar`, `/receber`, `/contas`, `/ofx`, `/hotmart`, `/categorias` — faltam rotas pras features do categorizador (fatura, compras, regras); Layout.tsx:15-23 é onde se adiciona nav.