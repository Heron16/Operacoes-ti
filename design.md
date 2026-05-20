# Design Técnico — Digitalização do Controle de Rotinas

## Visão Geral

O sistema é uma aplicação web estática (HTML + CSS + JS puro, sem framework, sem backend). Toda a persistência é feita via `localStorage`. O design a seguir descreve as mudanças nos três arquivos existentes: `dashboard.html`, `style.css` e `data.js`.

---

## 1. Estrutura de Abas (Requisito 10 — Painel Duplo)

### Estado Atual
7 abas separadas: Uniface Diária | Uniface Mensal | Unimed | Serasa | Corvu Diário | Final de Semana | Corvu F. Semana

### Nova Estrutura
5 abas:

| Aba | Conteúdo | Visibilidade |
|-----|----------|--------------|
| 📋 Diário | Painel duplo: Uniface Diária (esq) + Corvu Diário (dir) | Sempre visível |
| 📆 Final de Semana | Painel duplo: Uniface FDS (esq) + Corvu FDS (dir) | Sempre visível |
| 📅 Mensal | Rotinas Mensais | Bloqueada por padrão |
| 🏥 Unimed | Rotinas Unimed | Bloqueada por padrão |
| 🔍 Serasa | Rotinas Serasa | Bloqueada por padrão |

O botão "Horários" permanece como link externo para `horarios.html`.

### Layout Painel Duplo (CSS Grid)
```
┌─────────────────────────────────────────────────────┐
│  Movimento do Dia 10/05/2026 (Sábado)               │
├──────────────────────────┬──────────────────────────┤
│  📋 Rotinas Uniface      │  🖥️ Corvu                │
│  (scroll independente)   │  (scroll independente)   │
│                          │                          │
└──────────────────────────┴──────────────────────────┘
```

CSS:
```css
.painel-duplo {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  align-items: start;
}
.painel-coluna {
  overflow-y: auto;
  max-height: calc(100vh - 160px);
}
@media (max-width: 900px) {
  .painel-duplo { grid-template-columns: 1fr; }
}
```

---

## 2. Cabeçalho de Data do Movimento (Requisito 12)

Cada aba exibe no topo:
```
📅 Movimento do Dia 10/05/2026 (Sábado)
```

Implementação: função `getMovimentoHeader()` retorna a string formatada. Chamada no `renderAll()` e atualizada pelo `setInterval` de virada de dia.

```javascript
function getMovimentoHeader() {
  const d = new Date();
  return '📅 Movimento do Dia ' + d.toLocaleDateString('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric', weekday: 'long'
  });
}
```

---

## 3. Controle de Visibilidade de Categorias (Requisito 11)

### Chaves no localStorage
```
cat_liberada_mensal   → "true" | ausente
cat_liberada_unimed   → "true" | ausente
cat_liberada_serasa   → "true" | ausente
```

### Lógica de renderização das abas
```javascript
function isCatLiberada(prefix) {
  // Diário e FDS sempre liberados
  if (prefix === 'diario' || prefix === 'fds') return true;
  return localStorage.getItem('cat_liberada_' + prefix) === 'true';
}

function renderTabs() {
  // Para operador: só exibe abas liberadas
  // Para admin: exibe todas, com ícone 🔒 nas bloqueadas
}
```

### Painel de Controle do Admin
Exibido no topo do dashboard apenas para `role === 'admin'`. Mostra cada categoria bloqueável com botão toggle Liberar/Bloquear.

```
┌─────────────────────────────────────────────────────┐
│ 🔧 Controle de Categorias (Admin)                   │
│  Mensal   [🔒 Bloqueada] [Liberar]                  │
│  Unimed   [✅ Liberada]  [Bloquear]                 │
│  Serasa   [🔒 Bloqueada] [Liberar]                  │
└─────────────────────────────────────────────────────┘
```

### Verificação periódica para operadores
`setInterval` a cada 30 segundos relê o `localStorage` e re-renderiza as abas. Isso faz com que quando o admin libera uma categoria, os operadores vejam a aba aparecer em até 30 segundos sem precisar recarregar.

---

## 4. Estrutura de Dados no localStorage

### Rotinas Diárias (por dia)
```javascript
// Chave: "status_diaria_2026-05-10"
{
  "d1": {
    "status": "encerrado",   // "", "executando", "encerrado", "erro"
    "inicio": "01:05",
    "fim": "01:47",
    "msg": "",               // descrição do erro
    "chamado": "INC0012345", // número do chamado (só quando erro)
    "campoval": "",          // campo único (propriedade `campo`)
    "srv": "PD121",          // campos dinâmicos (propriedade `campos`)
    "ter": "1"
  },
  "d2": { ... }
}
```

### Rotinas Mensais / Unimed / Serasa / FDS (chave fixa)
```javascript
// Chave: "status_mensal", "status_unimed", "status_serasa", "status_fds"
{ "m1": { "status": "encerrado", "inicio": "18:05", "fim": "18:30", ... } }
```

### Corvu (chave fixa por categoria)
```javascript
// Chave: "corvu_dados_corvu" | "corvu_dados_corvufds"
{
  "0": { "inicio": "07:00", "fim": "07:45", "servidor": "PD121", "usuario": "op1", "terminal": "1" },
  "1": { ... }
}
```

### Bloqueio de Rotinas Individuais
```javascript
// Chave: "blocked_diaria_2026-05-10" (diária: escopo por dia)
// Chave: "blocked_mensal", "blocked_unimed", "blocked_fds" (fixo)
["d1", "d5", "d16"]  // array de IDs bloqueados
```

### Visibilidade de Categorias
```javascript
// Chave: "cat_liberada_mensal" → "true"
// Ausência da chave = bloqueada
```

---

## 5. Campos de Início, Fim e Chamado (Requisitos 1, 3)

### Regras de auto-preenchimento
| Evento | Ação |
|--------|------|
| Status → `executando` | Preenche `inicio` com hora atual **se ainda não tiver valor** |
| Status → `encerrado` | Preenche `fim` com hora atual **se ainda não tiver valor** |
| Status → `erro` | Preenche `inicio` com hora atual **se ainda não tiver valor** |
| Status → qualquer outro | Mantém `inicio` e `fim` no localStorage, oculta `fim` da tela se voltar para `executando` |

### Exibição condicional
```
status = ""          → nenhum campo de hora visível
status = executando  → Início visível (editável)
status = encerrado   → Início + Fim visíveis (editáveis)
status = erro        → Início + Fim + Chamado + Descrição visíveis
```

### Campo Chamado
Aparece abaixo da textarea de descrição de erro. Input `type="text"`, placeholder "Nº do Chamado (ex: INC0012345)". Persiste em `s[id].chamado`.

---

## 6. Campos Especiais: `campos` e `campo` (Requisitos 4, 5)

### Propriedade `campos` (array — ex: Servidor + Terminal)
Renderiza um input por item do array, com o `label` como rótulo. Sempre visível independente do status.

```html
<!-- Para r.campos = [{k:'srv', label:'Servidor'}, {k:'ter', label:'Terminal'}] -->
<span class="campo-label">Servidor</span>
<input type="text" placeholder="ex: PD121" value="..." onchange="...">
<span class="campo-label">Terminal</span>
<input type="text" placeholder="ex: 1" value="..." onchange="...">
```

### Propriedade `campo` (string — ex: "OK ___")
Renderiza um único input com o valor de `campo` como placeholder. Sempre visível.

```html
<input type="text" placeholder="OK ___" value="..." onchange="...">
```

---

## 7. Rotinas do Dia Anterior (Requisito 7)

### Detecção
Ao renderizar a aba Diário, verifica se `status_diaria_{diaAnterior}` contém algum item com `status === 'executando'`.

### Renderização
```
┌─────────────────────────────────────────────────────┐
│ ⚠️ Rotinas pendentes de 09/05/2026 — 3 em execução  │
│  [lista das rotinas pendentes com badge de data]    │
├─────────────────────────────────────────────────────┤
│ 📅 Movimento do Dia 10/05/2026                      │
│  [lista das rotinas do dia atual]                   │
└─────────────────────────────────────────────────────┘
```

### Badge de data
Cada rotina pendente do dia anterior exibe ao lado do nome:
```html
<span class="badge-dia-anterior">Rotinas 09/05/2026</span>
```

---

## 8. Bloqueio Individual de Rotinas (Requisito 2)

### Escopo do bloqueio
- **Aba Diário**: chave `blocked_diaria_{DiaKey}` — reseta a cada dia
- **Demais abas**: chave `blocked_{prefix}` — persiste indefinidamente

### Comportamento visual
- Rotina bloqueada: classe `rotina-item blocked` (CSS já existente: opacidade reduzida, texto riscado, label "BLOQUEADA")
- Select de status: `disabled`
- Botão: alterna entre 🔒 e 🔓

---

## 9. Arquivos Modificados

| Arquivo | Mudanças |
|---------|----------|
| `dashboard.html` | Reestruturação completa das abas, painel duplo, toda a lógica JS atualizada |
| `style.css` | Adicionar: `.painel-duplo`, `.painel-coluna`, `.badge-dia-anterior`, `.movimento-header`, `.admin-panel`, `.cat-badge` |
| `data.js` | Sem mudanças nos dados — apenas verificar se `ROTINAS_FDS` e `ROTINAS_CORVU_FDS` estão definidos |

---

## 10. Funções JavaScript Principais

```javascript
// Navegação
abrirTab(id)                          // troca aba ativa
renderTabs()                          // re-renderiza barra de abas (visibilidade por perfil)

// Renderização
renderAll()                           // renderiza todas as abas ativas
renderPainelDuplo(prefix)             // renderiza painel duplo (uniface + corvu lado a lado)
renderRotinas(containerId, rotinas, prefix, diaKey)
renderCorvu(containerId, prefix)
renderBlocoDiaAnterior(container)     // bloco de rotinas pendentes do dia anterior

// Estado
mudarStatus(prefix, id, valor, diaKey)
mudarCampo(prefix, id, campo, valor, diaKey)
toggleBlock(prefix, id)               // bloqueia/desbloqueia rotina individual

// Admin — categorias
toggleCategoria(prefix)               // libera ou bloqueia categoria inteira
isCatLiberada(prefix)                 // retorna true/false
renderPainelAdmin()                   // painel de controle de categorias

// Utilitários
getDiaKey()                           // "2026-05-10"
getDiaAnteriorKey(key)                // "2026-05-09"
formatarDataKey(key)                  // "10/05/2026"
getMovimentoHeader()                  // "📅 Movimento do Dia 10/05/2026 (Sábado)"
temExecutandoNoDia(diaKey)            // boolean
getBlocked(prefix, diaKey)            // array de IDs
getStatus(prefix, diaKey)             // objeto de status
```
