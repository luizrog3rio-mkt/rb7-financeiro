-- APLICADA: 20260630115851
-- Auditoria financeira: lancamentos com ano-lixo (6, 20026, 20226 = R$8.330,80) que somem
-- de qualquer ano selecionavel na DRE. Guarda de integridade contra datas absurdas daqui pra
-- frente. NOT VALID: vale pra novos/editados; nao bloqueia nem mexe nos registros antigos
-- (que seguem invisiveis na DRE). Aprovado pelo Luiz em 2026-06-30.
alter table public.entries
  add constraint entries_datas_sanas check (
        due_date          between '2015-01-01' and '2040-01-01'
    and (issue_date      is null or issue_date      between '2015-01-01' and '2040-01-01')
    and (competency_date is null or competency_date between '2015-01-01' and '2040-01-01')
    and (payment_date    is null or payment_date    between '2015-01-01' and '2040-01-01')
  ) not valid;
