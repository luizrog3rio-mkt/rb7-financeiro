INVENTÁRIO COMPLETO — categorizador-fatura/src (App.jsx 1459 linhas, components/Auth.jsx 227 linhas, lib/supabase.js 6 linhas, main.jsx 9 linhas)

=====================================================================
0. INFRA / BOOT
=====================================================================
- src/lib/supabase.js:1-6 — client único `createClient(VITE_SUPABASE_URL, VITE_SUPABASE_PUBLISHABLE_KEY)`. A var lê `VITE_SUPABASE_PUBLISHABLE_KEY` (NÃO `VITE_SUPABASE_ANON_KEY` do rb7) — qualquer port tem que manter esse nome ou migrar o env na Vercel junto.
- src/main.jsx:1-9 — `ReactDOM.createRoot` + `<React.StrictMode>`. StrictMode dobra effects em dev: o seed-on-empty do loadUserData roda 2x em dev (corrida possível de seeds duplicados — provável origem dos 21 categories/124 auto_rules duplicados citados no CLAUDE.md).
- Estilo: 100% inline styles via objeto `S` (App.jsx:1445-1459 e Auth.jsx:110-227). Sem CSS framework, sem router, sem libs de UI. Fonte "'Segoe UI', system-ui, sans-serif", fundo de página #f8fafc.
- Única dependência runtime além de react: @supabase/supabase-js. SheetJS é carregado por CDN em runtime (ver feature 12).

=====================================================================
1. AUTENTICAÇÃO (components/Auth.jsx:1-228 + App.jsx:530-564, 892-900, 918-931)
=====================================================================
- Tela única com card centralizado (max-width 400), emoji 💳 tamanho 52, título "Categorizador de Fatura", subtítulo "Importe, categorize e analise suas faturas".
- Toggle de modo em pílula dupla "Entrar" / "Criar conta" (Auth.jsx:42-58); trocar de aba limpa error e message.
- Form: e-mail (type=email required) + senha (type=password required minLength=6, placeholder "Mínimo 6 caracteres"). Botão submit vira "Aguarde..." com opacity 0.6 enquanto loading.
- Login: `supabase.auth.signInWithPassword({email, password})` (Auth.jsx:19); erro mostrado em box vermelho (#fef2f2/#b91c1c) com a message crua do Supabase (em inglês).
- Signup: `supabase.auth.signUp({email, password})` (Auth.jsx:22); sucesso mostra box verde "Conta criada! Entrando..." (pressupõe confirmação de e-mail DESLIGADA — commit 84e1170; a sessão chega via onAuthStateChange e o App troca de tela sozinho).
- Rodapé do card: "Seus dados são processados localmente no navegador. / O banco armazena apenas categorias e histórico." (Auth.jsx:101-104) — texto factualmente desatualizado (transações são persistidas), decidir se mantém.
- App.jsx:553-564 — `supabase.auth.getSession()` no mount define user + authLoading; `onAuthStateChange` mantém user sincronizado; unsubscribe no cleanup.
- App.jsx:919-928 — splash "Carregando..." com 💳 enquanto authLoading.
- Logout (App.jsx:893-900): `supabase.auth.signOut()` + zera user/transactions/categories/invoices/currentInvoice (NÃO zera purchaseItems/purchaseCategories/pendingCount — lixo de estado inofensivo porque o re-login recarrega). Botão "Sair" presente em TODAS as telas logadas (lista, fatura, pendentes).
- Sem reset de senha, sem OAuth, sem magic link, sem "lembrar-me". Sem perfil/avatar; o e-mail do usuário aparece em texto no topo da lista de faturas (App.jsx:982).

=====================================================================
2. CARGA INICIAL + SEED-ON-EMPTY (App.jsx:566-676 loadUserData)
=====================================================================
Disparado por useEffect quando `user` muda (App.jsx:567-570). Sequência serial:
1. `categories.select("*").order("created_at")` (576-579). Se `dbCats.length > 0` → mapeia para `{id, name, color: TAG_COLORS[color_index % 10], colorIndex}`. Se vazio MAS não-null (`else if (dbCats)`) → seeda `DEFAULT_CATEGORIES` com `insert([{user_id, name, color_index}]).select()` (588-607).
2. `auto_rules.select("*")` sem order (610-612). Se tem linhas → `setAutoRules(map para {keywords, category})`. Se vazio → insere DEFAULT_RULES (62 linhas, `{user_id, keywords (array), category}`) e usa DEFAULT_RULES local (617-625). Nota: estado inicial de autoRules JÁ é DEFAULT_RULES (App.jsx:537), então até o load terminar uma importação usaria os defaults.
3. `purchase_item_categories.select("*").order("created_at")` (628-631), mesmo padrão seed-on-empty com DEFAULT_PURCHASE_CATEGORIES (640-658).
4. `invoices.select("*").order("imported_at", {ascending:false})` (661-664) → setInvoices(dbInvs || []).
5. `purchase_items.select("*", {count:"exact", head:true}).is("invoice_id", null)` (669-673) → pendingCount badge.
PEGADINHAS:
- O seed só dispara quando o select RESPONDE com array vazio — se o select FALHA (RLS, rede), `data` é null, cai fora dos dois branches e o estado fica vazio silenciosamente. NENHUM `error` é checado em loadUserData (nem em quase lugar nenhum do app): padrão `const {data} = await ...` com erro engolido.
- Com RLS `using(true)` (modelo de equipe), o seed-on-empty é PERIGOSO de outro jeito: usuário novo vai ENXERGAR as linhas dos colegas e nunca seedar — comportamento desejado pós-consolidação, mas o código atual escreve `user_id: user.id` em todo insert; o schema novo precisa decidir o que fazer com essa coluna.
- `auto_rules` carregadas SEM order — a precedência de regras na auto-categorização depende da ordem retornada pelo banco (indefinida). Com os defaults o array é ordenado como no código; vindas do banco, a primeira regra que der match vence em ordem arbitrária.
- categories.color_index salvo no banco; cor exibida = `TAG_COLORS[color_index % 10]`.

=====================================================================
3. PARSER OFX PRÓPRIO (App.jsx:119-137 parseOFX + 111-117 autoCategorizeMemo)
=====================================================================
- Regex `/<STMTTRN>([\s\S]*?)<\/STMTTRN>/g` sobre o texto bruto do arquivo (lido com `file.text()` — encoding default UTF-8; OFX Sicoob pode ser Latin-1, atenção a acentos no MEMO).
- Por bloco, extrai tag com `new RegExp(`<${tag}>([^<]*)`)` — pega até o próximo `<`, funciona com OFX SGML sem fechamento de tags.
- Campos: TRNTYPE, MEMO (com replace `&amp;`→`&` — único unescape feito; `&lt;` etc. não tratados), TRNAMT (`parseFloat(raw.replace(",", "."))` — troca só a PRIMEIRA vírgula), DTPOSTED, FITID.
- Data: `DTPOSTED` "YYYYMMDD..." → string `"DD/MM/YYYY"` por slice (130). A data NUNCA vira Date — é TEXTO em todo o app e no banco (`transactions.date` é texto DD/MM/YYYY). Ordenação de transações é por created_at, nunca por data.
- Filtros: descarta bloco sem memo ou amount NaN (131); descarta `TRNTYPE === "CREDIT" && amtRaw > 0` (132) — ou seja, pagamentos/estornos com tipo CREDIT positivo somem; um estorno como DEBIT negativo NÃO seria filtrado e viraria valor positivo pelo Math.abs.
- `amount: Math.abs(amtRaw)` (134) — TODO valor vira positivo; o app inteiro assume despesas positivas. Sinal original é perdido.
- Auto-categorização na importação (111-117): para cada transação, percorre `rules` na ordem do array; match = `memo.toLowerCase().includes(keyword.toLowerCase())` (substring, case-insensitive, sem word-boundary); PRIMEIRA regra com qualquer keyword vencendo. Resultado vai em `category` + flag `auto: true`.
- `fit_id` é capturado e persistido mas NUNCA usado para dedupe (correto, dado que o Sicoob repete FITID entre faturas para parcelamentos — NÃO introduzir unique constraint nem dedupe por fit_id no port).
- Importar o MESMO arquivo duas vezes cria duas faturas completas (sem detecção de duplicata — comportamento atual aceito).

=====================================================================
4. IMPORTAÇÃO DE FATURA (App.jsx:734-801 handleFile)
=====================================================================
Disparada por `<input type="file" accept=".ofx">` em dois lugares: label "📂 Importar .OFX" na lista (App.jsx:455-462) e label "📂 Nova fatura" no header da fatura aberta (1019-1022). Sem drag-and-drop real (o empty-state diz "Arraste um arquivo .OFX" mas não há handler de drop — texto mente).
Fluxo:
1. `parseOFX(text, autoRules)`; total = soma dos amounts.
2. `invoices.insert({user_id, name: file.name sem ".ofx" (regex case-insensitive), total, transaction_count}).select().single()` (741-750). Se `!inv` → return silencioso (importação morre sem feedback nenhum ao usuário). NOTA: o insert NÃO envia `account_id` (coluna nova da Fase 1a) — fica null/default.
3. `transactions.insert(rows[]).select()` (766-769) com colunas: user_id, invoice_id, fit_id, memo, amount, date (texto DD/MM/YYYY), category, auto_categorized. Se falhar, a invoice já existe órfã com transaction_count errado (sem transação) — sem rollback.
4. Busca pendentes: `purchase_items.select("*").is("invoice_id", null).order("month", {ascending:false}).order("created_at")` (784-789).
5. setCurrentInvoice(inv), insere inv no topo da lista, zera purchaseItems/filter/search, activeTab="lancamentos"; se há pendentes → `setPendingToImport(pending)` abre o modal (feature 10).
- Nenhum loading state durante a importação (tela congela na percepção do usuário em arquivos grandes).
- `total` e `transaction_count` são fotos do momento da importação; NUNCA são recalculados (deletar transação não existe; editar categoria não muda total — ok).

=====================================================================
5. LISTA DE FATURAS / HOME (App.jsx:444-526 InvoiceHistory + 963-998 render)
=====================================================================
- Top bar: "💳 Categorizador de Fatura" + botão "🛒 Compras pendentes" com contagem `(N)` quando pendingCount>0 (botão fica azul #eff6ff/#1d4ed8/#bfdbfe quando N>0, neutro quando 0) (974-981) + e-mail do usuário + "Sair".
- Cabeçalho: "Suas faturas" + subtítulo com pluralização manual "N fatura(s) importada(s)" ou "Nenhuma fatura importada ainda" (450-453).
- Loading: texto "Carregando..." (465-467).
- Empty-state: card tracejado com 💳 48px, "Importe sua primeira fatura", "Arraste um arquivo .OFX ou clique no botão acima" (469-482).
- Card por fatura (485-522): ícone 📋 em quadrado #eff6ff, nome (fallback "Fatura importada"), linha "N lançamentos · DD/MM/AAAA" (`new Date(inv.imported_at).toLocaleDateString("pt-BR")`), total em BRL à direita (fmt = Intl pt-BR currency), hover muda borda pra #93c5fd com sombra azul. Clique no card abre a fatura.
- Botão ✕ por card (511-520): `e.stopPropagation()`, cinza #cbd5e1 → vermelho #ef4444 no hover, title "Excluir fatura".

=====================================================================
6. EXCLUSÃO DE FATURA (App.jsx:851-860 deleteInvoice)
=====================================================================
- `window.confirm(`Excluir a fatura "${nome}" e todas as suas transações? Essa ação não tem desfazer.`)` — confirm nativo do browser, sem modal custom (853).
- `invoices.delete().eq("id", invoiceId)` (854) — transações somem por FK ON DELETE CASCADE no banco (o app não deleta transactions explicitamente). ATENÇÃO no port: purchase_items têm `invoice_id` — verificar no banco vivo se o cascade em purchase_items é DELETE ou SET NULL; o app não trata nem atualiza pendingCount após excluir fatura que tinha itens.
- Remove do estado; se era a fatura aberta, volta pra home (856-859). Sem checagem de erro — se o delete falhar, a UI mente que excluiu até o reload.

=====================================================================
7. VISÃO DA FATURA — HEADER + ABAS (App.jsx:1000-1045)
=====================================================================
- Header sticky (S.header, zIndex 100): botão "←" volta pra lista (limpa currentInvoice+transactions), "💳 {nome}" com ellipsis, chip "{N} lançamentos", chip laranja condicional "{N} sem categoria" (#fff7ed/#c2410c/#fed7aa) (1010-1015), ExportMenu, label "📂 Nova fatura" (input file), "Sair".
- 3 abas (1031-1045): "📋 Lançamentos", "📊 Dashboard", "🛒 Compras". Aba ativa = borda inferior 2px #3b82f6 + texto #1d4ed8 bold. Estado `activeTab`, default "lancamentos" (resetado a cada load de fatura).

=====================================================================
8. ABA LANÇAMENTOS — TABELA + BUSCA + FILTROS (App.jsx:902-916, 1047-1118)
=====================================================================
- Busca: input "🔍 Buscar descrição..." — substring case-insensitive sobre memo (903-904). Combina com filtro (AND).
- Filtros em pílulas (1053-1072): "Todos (N)", "Sem categoria (N)", e UMA pílula por categoria COM count>0 nesta fatura (categorias sem uso na fatura não aparecem). Pílula de categoria ativa adota as cores TAG_COLORS dela; clicar de novo na ativa volta pra "all" (toggle, linha 1067). "Todos"/"Sem categoria" ativos usam S.tabOn (#eff6ff/#1d4ed8).
- Tabela (1075-1109): colunas Data (88px, texto cru DD/MM/YYYY) | Descrição (memo) | Valor (right, fmt BRL, tabular-nums) | Categoria (250px). Hover de linha #f8fafc. Empty: "Nenhum lançamento encontrado." colSpan 4.
- Badge "✦ auto" (1097-1099): aparece ao lado do TagSelector quando `t.auto && t.category` — indigo #6366f1/#eef2ff/#c7d2fe, title "Categorizado automaticamente". PEGADINHA: o flag `auto_categorized` NÃO é limpo quando o usuário troca a categoria manualmente (setCategory só atualiza `category`) — a badge continua "auto" mesmo após edição manual.
- Footer sticky (1111-1116): "{N} lançamento(s) exibido(s)" + "Total: {fmt(totalFiltered)}" — total responde a busca+filtro.
- Recategorizar (862-869 setCategory): update otimista no estado + `transactions.update({category}).eq("id", txId)` — sem checagem de erro, sem rollback.
- NÃO existe: editar memo/valor/data de transação, excluir transação individual, recategorização em massa, "aplicar a similares", criação de regra a partir de edição (regras só nascem no seed).

=====================================================================
9. CATEGORIAS + TagSelector (App.jsx:255-313, 871-890 addCategory)
=====================================================================
- TagSelector (usado em transações E em purchase items, com listas de categorias DIFERENTES): botão-pílula com cores da categoria, ou tracejado "Selecionar categoria" se null; dropdown com fechamento por click-fora (mousedown listener); cada opção mostra a pílula colorida + ✓ azul na selecionada; opção "✕ Remover categoria" só quando há valor (seta null); rodapé com input "Nova categoria..." (autoFocus, Enter confirma, e.stopPropagation no keydown) + botão "+" azul — criar já SELECIONA a nova categoria na linha.
- addCategory (872-890): ignora nome duplicado exato (case-sensitive); `color_index = categories.length % 10` (reuso cíclico de cores); `categories.insert({user_id, name, color_index}).select().single()`. Idem addPurchaseCategory (715-731) na tabela `purchase_item_categories`.
- NÃO existe: renomear categoria, excluir categoria, trocar cor, mesclar. Vínculo transação↔categoria é por NOME (string em `transactions.category`), não FK — renomear no banco órfãraria transações.

=====================================================================
10. ABA COMPRAS / ITENS DE COMPRA (App.jsx:678-731 CRUD, 1162-1348 PurchaseItemsTab)
=====================================================================
Dois contextos com o MESMO componente: aba "Compras" da fatura (isPending=false, itens com invoice_id da fatura) e tela "Compras pendentes" (isPending=true, itens com invoice_id IS NULL).
- loadPurchaseItems(invoiceId) (680-685): `purchase_items.select("*").order("created_at")` + `.eq("invoice_id", id)` ou `.is("invoice_id", null)`.
- Form de adição (1195-1248): data da compra (type=date), descrição (obrigatória, única validação), forma de pagamento (texto livre), valor (number step 0.01, OPCIONAL — null permitido), TagSelector de purchase categories, e SÓ quando isPending um input type=month default mês corrente (`currentMonth()` YYYY-MM, App.jsx:1151-1154). Enter em qualquer input confirma. Botão "+ Adicionar" desabilitado sem descrição.
- Dica fixa: "💡 Itens aqui são anotações — não entram em totais nem no dashboard." + (pendentes) "Ao importar uma fatura, você poderá selecionar quais itens incluir." (1244-1247). CONTRATO: purchase items NUNCA entram em soma nenhuma.
- addPurchaseItem (687-703): insert com `invoice_id: currentInvoice?.id ?? null`, `month` (só quando passado; aba da fatura manda null — linha 1176), amount Number ou null, purchase_date/payment_method null se vazios.
- Agrupamento (1183-1191): pendentes agrupados por `month` desc (localeCompare reverso de "YYYY-MM"; itens sem month caem no grupo "" rotulado "Sem mês"); cabeçalho "📅 {Mês/Ano}" via formatMonth (Jan…Dez/YYYY, App.jsx:1155-1160) + "{N} item/itens". Aba da fatura = grupo único "Itens desta fatura".
- Tabela editável inline (1263-1335): cada célula é input com `defaultValue` + onBlur dispara `onUpdate(id, {campo})` SÓ se mudou — colunas: Data (type=date → purchase_date), Descrição (não aceita vazio: blur com vazio é ignorado), Pagamento (vazio → null), Valor (vazio → null, number), Categoria (TagSelector), ✕ excluir SEM confirm (deletePurchaseItem 710-713, otimista, delete direto sem window.confirm — diferente da fatura).
- updatePurchaseItem (705-708): otimista, `purchase_items.update(fields).eq("id", id)`, erro engolido.
- Empty: card "🛒 / Nenhum item lançado ainda".
- NÃO editável inline: o `month` de um item pendente (só no form de criação).

=====================================================================
11. TELA "COMPRAS PENDENTES" + MODAL DE IMPORTAÇÃO (App.jsx:933-961, 803-821, 1350-1442)
=====================================================================
- Acesso pelo botão da home; render dedicado (934-961): header com "←" (que ao voltar RECONTA pendingCount com novo count query head:true — linha 939), título "🛒 Compras pendentes", chip "aguardando próxima fatura", botão Sair; corpo = PurchaseItemsTab isPending=true.
- PendingImportModal (1351-1442): overlay fixed rgba(15,23,42,0.5) zIndex 10000, abre AUTOMATICAMENTE após importar fatura SE existirem pendentes (798-800). Título "🛒 Importar compras pendentes", subtítulo "Selecione quais itens incluir nesta fatura. Os não selecionados continuam pendentes."
- TODOS os itens começam SELECIONADOS (Set inicial com todos os ids, 1352). Agrupado por mês desc com checkbox de grupo (toggle-all do grupo, 1369-1378) e cabeçalho "📅 Mês/Ano (N)". Cada linha: checkbox, data DD/MM/YYYY (split("-").reverse().join("/")), descrição, payment_method, pílula cinza da categoria (sem cor TAG_COLORS aqui — só #f1f5f9), valor fmt quando não-null.
- Rodapé: "{X} de {Y} selecionados", botão "Pular" (onCancel → fecha sem atrelar nada) e "Importar selecionados".
- attachSelectedPending (804-821): `purchase_items.update({invoice_id: currentInvoice.id}).in("id", ids).select()`; sucesso → adiciona ao estado, decrementa pendingCount, e TROCA pra aba "compras" automaticamente. Confirmar com 0 selecionados = só fecha.

=====================================================================
12. EXPORTAÇÃO CSV/XLSX (App.jsx:143-195 + 197-252 ExportMenu)
=====================================================================
- Botão "⬇ Exportar ▼" no header da fatura, escuro #0f172a, desabilitado (opacity 0.4) sem transações. Dropdown com click-fora.
- Lógica de alvo (207-209): se filter !== "all" exporta os FILTRADOS com rótulo "Exportar filtrados (N)", e mostra seção extra "Exportar todos (N)". PEGADINHA: a decisão olha só `filter` — busca ativa com filter="all" exporta `transactions` completas, IGNORANDO a busca (mas `filtered` passado já tem a busca aplicada quando filter!=="all"... na real `filtered` sempre tem busca aplicada; o rótulo "todos" com busca ativa é o que ignora a busca).
- CSV (159-170): separador ";", header "Data;Descrição;Valor (R$);Categoria", valores com vírgula decimal, aspas duplicadas pra escape, sem categoria → literal "Sem categoria", CRLF, BOM \uFEFF (Excel pt-BR friendly), nome fixo "fatura_categorizada.csv", download via blob+URL.createObjectURL (190-195).
- XLSX (172-188): carrega SheetJS 0.18.5 de cdnjs EM RUNTIME (loadXLSX 145-156, script tag, promise cacheada — OFFLINE/CSP quebra o Excel export silenciosamente, só console.error). Sheet "Fatura", larguras de coluna fixas, formato numérico '#,##0.00' na coluna Valor, nome "fatura_categorizada.xlsx".
- Entradas do menu: "📊 Excel (.xlsx) / Abre direto no Excel" e "📄 CSV (.csv) / Compatível com qualquer app".

=====================================================================
13. ABA DASHBOARD (App.jsx:316-346 DonutChart + 348-442 Dashboard)
=====================================================================
- 4 cards de métrica (384-397): "Total gasto" (soma + "N lançamentos"), "Maior categoria" (valor + "nome · X.X%"), "Ticket médio" (total/N, "por lançamento"), "Sem categoria" (count; sub "tudo categorizado ✓" quando 0).
- Agrupamento por `t.category || "Sem categoria"` (354-360); entries ordenadas por total desc.
- Cores: pílula usa TAG_COLORS da categoria pelo ÍNDICE da categoria na lista (findIndex por nome); barra/donut usam CAT_CHART_COLORS[idx % 10]; "Sem categoria" → TAG_COLORS[9] (cinza) e CAT_CHART_COLORS[8] (#888780) (362-368).
- "Ranking por categoria" (400-420): linha = posição numérica, pílula colorida (116px, ellipsis), barra horizontal proporcional ao MAIOR total (não ao grand total), "X.X%", valor BRL, "N lanç.". Subtítulo "clique para ver os lançamentos".
- Donut SVG próprio (316-346): r=56/inner=34, paths calculados à mão, centro "TOTAL" + valor fmt; card "Distribuição" com legenda quadradinho+nome+% (422-438).
- CONTRATO drill-down (912-916 handleDashFilterClick): clicar numa categoria (ranking OU legenda) seta o filtro daquela categoria ("Sem categoria" → filtro "sem"), limpa busca e PULA pra aba Lançamentos.
- Empty: "📊 / Importe uma fatura para ver o dashboard" (373-380).
- Dashboard é POR FATURA (recebe `transactions` da fatura aberta) — não existe visão agregada multi-fatura/mensal.

=====================================================================
14. CONSTANTES (inventário literal)
=====================================================================
DEFAULT_CATEGORIES (App.jsx:71-81) — 9, com colorIndex:
  Compras Online=2 (azul), Educação=3 (amarelo), Ferramenta=4 (roxo), Imposto=9 (cinza), Operacional=6 (azul-claro), PF - Rafa=1 (verde), Taxa=7 (rosa), Tráfego Pago=5 (laranja), Viagem=0 (vermelho).

DEFAULT_PURCHASE_CATEGORIES (App.jsx:83-89) — 5:
  Estrutura=2, Operacional=6, Material de escritório=4, Viagem=0, Educação=3.

TAG_COLORS (App.jsx:92-103) — 10 trios {bg, text, border}:
  0 vermelho #fee2e2/#991b1b/#fca5a5; 1 verde #dcfce7/#166534/#86efac; 2 azul #dbeafe/#1e40af/#93c5fd; 3 amarelo #fef9c3/#854d0e/#fde047; 4 roxo #f3e8ff/#6b21a8/#d8b4fe; 5 laranja #ffedd5/#9a3412/#fdba74; 6 azul-claro #e0f2fe/#075985/#7dd3fc; 7 rosa #fce7f3/#9d174d/#f9a8d4; 8 esmeralda #ecfdf5/#065f46/#6ee7b7; 9 cinza #f1f5f9/#334155/#cbd5e1.

CAT_CHART_COLORS (App.jsx:105-108) — 10: #534AB7,#D4537E,#D85A30,#1D9E75,#378ADD,#BA7517,#3B6D11,#E24B4A,#888780,#075985.

DEFAULT_RULES (App.jsx:6-69) — 62 regras {keywords[], category}, match substring case-insensitive, primeira vence:
  Compras Online (1): [mercadolivre, mercado livre, mp*mercadoliv]
  Educação (1): [hotmart, "htm "] (note o espaço em "htm ")
  Ferramenta (37): adobe; airtable; [anthropic, claude.ai]; apify; [asa*utmify, utmify]; autentique; clinthub; digitalocean; dl*google; [hostinger, "dm *hostinger"]; canva; elevenlabs; framer.com; [ig*salvy, ig*turbocloud, "pg *turbo cloud", turbocloud]; inlead; instrack; lovable; manychat; [openai, chatgpt]; paddle.net; "pg *unnichat"; "pg *yoshiura"; railway; rapidapi; scrapingdog; sendpulse; short.io; soniox; stape; streamyard; supabase; uazapi; vidiq; visitorapi; vturb; ["yay! forms", yayforms]; [zoom.com, zoom.us]
  Imposto (1): [iof operacao, iof operação]
  Operacional (5): claro negoci; starlink; ["pg *br did telefonia", "br did"]; recvivo; zurich seguro
  PF - Rafa (2): guaritao; prudent*apol
  Taxa (2): [anuidade visa, anuidade mastercard, anuidade]; [protecao perda, proteção perda]
  Tráfego Pago (1): ["facebk "] (espaço final)
  Viagem (12): [americam plaza, american p a h]; auto posto sofia; captions.ai (sic — captions.ai como Viagem); elias do coco; [estac. sicoob, pedgio sicoob]; estanplaza; [mp*voeeconomy, voeeconomy]; radisson; [rest frangoassado, "rest. - cambui", restaurante do marqu, trembao restaurante]; [rodoposto, rodosnack]; tivoli ecoresort; scp estacionamento.
  NOTA: keywords contêm * e espaços significativos como TEXTO LITERAL (são substrings de memos Sicoob tipo "MP*MERCADOLIV"), não wildcards. No banco vivo `auto_rules.keywords` é array; o estado destas regras no banco já divergiu dos defaults (62 default vs 124 duplicadas em prod).

=====================================================================
SCHEMA TOCADO PELO APP (tabela.colunas realmente usadas)
=====================================================================
- categories: id, user_id, name, color_index, created_at (order)
- auto_rules: user_id, keywords (text[]), category — sem order
- purchase_item_categories: id, user_id, name, color_index, created_at
- invoices: id, user_id, name, total, transaction_count, imported_at — account_id existe no banco mas o app NÃO escreve/lê
- transactions: id, user_id, invoice_id, fit_id, memo, amount (lido com Number()), date (TEXTO DD/MM/YYYY), category (string-nome, não FK), auto_categorized, created_at (order)
- purchase_items: id, user_id, invoice_id (nullable), description, amount (nullable), category (string-nome), month (texto YYYY-MM, nullable), purchase_date (date, nullable), payment_method (texto, nullable), created_at (order)
- profiles: NUNCA tocada pelo front (só pelo trigger handle_new_user)
- auth: signInWithPassword, signUp, getSession, onAuthStateChange, signOut

=====================================================================
CONTRATOS A PRESERVAR (o que o usuário NOTA se mudar)
=====================================================================
1. Dados vivos intactos: 519 transações categorizadas, faturas, itens de compra e categorias existentes têm que renderizar idênticos no app novo (mesmos nomes, mesmas cores via color_index → TAG_COLORS, mesmas datas texto DD/MM/YYYY).
2. fit_id NÃO é chave: parcelamentos Sicoob repetem FITID entre faturas (R$ 22.475,33 legítimos). Qualquer dedupe/unique por fit_id no app novo DELETA/BLOQUEIA dinheiro real.
3. Parser OFX: mesmo recorte STMTTRN, Math.abs no valor, filtro de CREDIT>0 (pagamentos da fatura não aparecem), data como texto DD/MM/YYYY, unescape de &amp;. Mudar qualquer um muda totais/contagens visíveis.
4. Auto-categorização na importação: substring case-insensitive sobre o memo, primeira regra vence, badge "✦ auto" na linha. Regras vêm de auto_rules do banco (cuidado: ordem do select é indefinida hoje).
5. Categoria é STRING por nome em transactions.category e purchase_items.category — não FK. Migrar pra FK exige backfill por nome.
6. Seed-on-empty (9 categories, 62 rules, 5 purchase categories) só quando o select responde array VAZIO — no modelo de equipe using(true) o usuário novo já vê os dados do time e não pode re-seedar (duplicaria de novo). StrictMode dev dobra o effect — proteger contra seed duplo.
7. Fluxo pendentes→fatura: itens com invoice_id null são "pendentes"; importar fatura com pendentes existentes ABRE modal automaticamente, todos pré-selecionados, agrupados por mês desc, "Pular" mantém pendentes, confirmar atrela via update in(ids) e leva pra aba Compras. Badge "Compras pendentes (N)" na home.
8. Purchase items NUNCA entram em totais nem no dashboard (texto explícito na UI), valor é opcional (null ok), edição inline por blur, exclusão SEM confirm; exclusão de FATURA exige window.confirm com o texto "Excluir a fatura ... Essa ação não tem desfazer.".
9. Export: CSV com ";" + vírgula decimal + BOM + CRLF + "Sem categoria" como fallback, nomes fixos fatura_categorizada.csv/.xlsx; XLSX com formato numérico e mesmas colunas; menu distingue "filtrados (N)" vs "todos (N)".
10. Drill-down do dashboard: clicar categoria no ranking/legenda filtra e leva pra aba Lançamentos; pílula de filtro ativa adota as cores da categoria; clicar de novo desfaz o filtro.
11. Totais de fatura são fotos da importação (invoices.total/transaction_count) — não recalcular retroativamente sem avisar.
12. Env vars VITE_SUPABASE_URL + VITE_SUPABASE_PUBLISHABLE_KEY (não ANON_KEY) — port da base rb7 tem que renomear ou a Vercel quebra.
13. Filtros de pílula por categoria só mostram categorias com count>0 na fatura aberta; contagens entre parênteses em todos os filtros; footer sticky com total do que está exibido.
14. Comportamentos NEGATIVOS que o usuário pode estar explorando: reimportar o mesmo OFX cria fatura duplicada (sem dedupe); trocar categoria não limpa a badge auto; busca ativa + "exportar todos" ignora a busca. Decidir conscientemente se preserva ou corrige — qualquer correção muda comportamento observável.
15. Tudo roda sem loading/error feedback granular (erros engolidos com {data} sem error) — o app novo pode melhorar, mas falha de insert de invoice hoje simplesmente não faz nada; usuários estão acostumados a "clicou e apareceu".

LACUNAS (não existem hoje — não são regressão se o app novo também não tiver): editar/excluir transação individual, renomear/excluir/mesclar categorias, editar regras de auto-categorização pela UI, visão agregada multi-fatura, dedupe de importação, drag-and-drop real, reset de senha, edição do month de item pendente após criado, uso de invoices.account_id e das tabelas EN da Fase 1c (companies/accounts/entries/bank_transactions/hotmart_sales — zero referência no front atual).

Arquivos: C:\Users\luizrog3rio\projetos\categorizador-fatura\src\App.jsx, C:\Users\luizrog3rio\projetos\categorizador-fatura\src\components\Auth.jsx, C:\Users\luizrog3rio\projetos\categorizador-fatura\src\lib\supabase.js, C:\Users\luizrog3rio\projetos\categorizador-fatura\src\main.jsx