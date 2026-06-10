import type { CSSProperties } from 'react'

// Estilos do app original (App.jsx) — preservados 1:1 pela fidelidade visual
// dos contratos da portagem (docs/fase2/contratos-app-antigo.md).
export const S: Record<string, CSSProperties> = {
  header: { background: '#fff', borderBottom: '1px solid #e2e8f0', padding: '12px 20px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, position: 'sticky', top: 0, zIndex: 100 },
  chip: { background: '#f1f5f9', color: '#64748b', border: '1px solid #e2e8f0', padding: '3px 10px', borderRadius: 20, fontSize: 12, fontWeight: 600 },
  newBtn: { display: 'inline-block', background: '#f1f5f9', color: '#334155', border: '1px solid #e2e8f0', padding: '7px 16px', borderRadius: 8, cursor: 'pointer', fontWeight: 600, fontSize: 13 },
  filterBar: { background: '#fff', borderBottom: '1px solid #e2e8f0', padding: '10px 20px' },
  search: { border: '1px solid #e2e8f0', borderRadius: 8, padding: '7px 14px', fontSize: 13, outline: 'none', color: '#334155', maxWidth: 340, background: '#f8fafc', width: '100%' },
  // borda em propriedades separadas (não shorthand): o estado ativo sobrepõe
  // só borderColor, e o React 19 acusa mistura de shorthand + não-shorthand
  tab: { padding: '4px 12px', borderRadius: 20, borderWidth: 1, borderStyle: 'solid', borderColor: '#e2e8f0', background: 'transparent', color: '#64748b', cursor: 'pointer', fontSize: 12, fontWeight: 600 },
  tabOn: { background: '#eff6ff', color: '#1d4ed8', borderColor: '#bfdbfe' },
  table: { width: '100%', borderCollapse: 'collapse', minWidth: 560, background: '#fff' },
  th: { padding: '10px 14px', textAlign: 'left', fontSize: 11, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', letterSpacing: '0.06em', borderBottom: '2px solid #e2e8f0', background: '#f8fafc' },
  row: { borderBottom: '1px solid #f1f5f9', transition: 'background 0.1s', background: '#fff' },
  td: { padding: '10px 14px', verticalAlign: 'middle' },
  footer: { background: '#fff', borderTop: '1px solid #e2e8f0', padding: '12px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', position: 'sticky', bottom: 0 },
}
