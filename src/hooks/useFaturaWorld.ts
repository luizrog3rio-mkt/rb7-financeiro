import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { useApp } from '../contexts/AppContext'
import {
  DEFAULT_CATEGORIES,
  DEFAULT_PURCHASE_CATEGORIES,
  DEFAULT_RULES,
  TAG_COLORS,
  corDaCategoria,
  type CatUI,
  type RegraUI,
} from '../lib/fatura'

// Mundo compartilhado das telas de fatura/compras: categorias dos DOIS
// vocabulários vivos + regras de auto-categorização.
// Contrato #6: seed SÓ quando o select respondeu array vazio (erro engolido
// NÃO semeia) — e com proteção contra o double-effect do StrictMode.
const seedFeito = { categories: false, purchase: false, rules: false }

interface CatRow {
  id: string
  name: string
  color_index: number
}

const paraUI = (rows: CatRow[]): CatUI[] =>
  rows.map((c) => ({ id: c.id, name: c.name, color: corDaCategoria(c.color_index), colorIndex: c.color_index }))

export function useFaturaWorld() {
  const { session } = useApp()
  const userId = session?.user.id
  const [categorias, setCategorias] = useState<CatUI[]>([])
  const [purchaseCategorias, setPurchaseCategorias] = useState<CatUI[]>([])
  const [regras, setRegras] = useState<RegraUI[]>([])
  const [erro, setErro] = useState<string | null>(null)
  const [carregado, setCarregado] = useState(false)

  const carregar = useCallback(async () => {
    if (!userId) return

    const { data: cats, error: e1 } = await supabase.from('categories').select('*').order('created_at')
    if (e1) setErro('Erro ao carregar categorias: ' + e1.message)
    else if (cats.length > 0) setCategorias(paraUI(cats))
    else if (!seedFeito.categories) {
      seedFeito.categories = true
      const { data: ins, error } = await supabase
        .from('categories')
        .insert(DEFAULT_CATEGORIES.map((c) => ({ user_id: userId, name: c.name, color_index: c.colorIndex })))
        .select()
      if (!error && ins) setCategorias(paraUI(ins))
    }

    const { data: rules, error: e2 } = await supabase.from('auto_rules').select('*').order('created_at')
    if (e2) setErro('Erro ao carregar regras: ' + e2.message)
    else if (rules.length > 0) setRegras(rules.map((r) => ({ keywords: r.keywords, category: r.category })))
    else if (!seedFeito.rules) {
      seedFeito.rules = true
      const { error } = await supabase
        .from('auto_rules')
        .insert(DEFAULT_RULES.map((r) => ({ user_id: userId, keywords: r.keywords, category: r.category })))
      if (!error) setRegras(DEFAULT_RULES)
    }

    const { data: pcats, error: e3 } = await supabase.from('purchase_item_categories').select('*').order('created_at')
    if (e3) setErro('Erro ao carregar categorias de compra: ' + e3.message)
    else if (pcats.length > 0) setPurchaseCategorias(paraUI(pcats))
    else if (!seedFeito.purchase) {
      seedFeito.purchase = true
      const { data: ins, error } = await supabase
        .from('purchase_item_categories')
        .insert(DEFAULT_PURCHASE_CATEGORIES.map((c) => ({ user_id: userId, name: c.name, color_index: c.colorIndex })))
        .select()
      if (!error && ins) setPurchaseCategorias(paraUI(ins))
    }

    setCarregado(true)
  }, [userId])

  useEffect(() => {
    carregar()
  }, [carregar])

  const addCategoria = async (name: string) => {
    if (categorias.find((c) => c.name === name)) return
    const colorIndex = categorias.length % TAG_COLORS.length
    const { data, error } = await supabase
      .from('categories')
      .insert({ user_id: userId, name, color_index: colorIndex })
      .select()
      .single()
    if (error) { setErro('Erro ao criar categoria: ' + error.message); return }
    if (data) setCategorias((prev) => [...prev, ...paraUI([data])])
  }

  const addPurchaseCategoria = async (name: string) => {
    if (purchaseCategorias.find((c) => c.name === name)) return
    const colorIndex = purchaseCategorias.length % TAG_COLORS.length
    const { data, error } = await supabase
      .from('purchase_item_categories')
      .insert({ user_id: userId, name, color_index: colorIndex })
      .select()
      .single()
    if (error) { setErro('Erro ao criar categoria de compra: ' + error.message); return }
    if (data) setPurchaseCategorias((prev) => [...prev, ...paraUI([data])])
  }

  return { categorias, purchaseCategorias, regras, erro, carregado, addCategoria, addPurchaseCategoria }
}
