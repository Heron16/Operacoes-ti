# Lista de Tarefas — Digitalização do Controle de Rotinas

## Tarefa 1: Atualizar style.css com novos estilos

- [ ] Adicionar classe `.painel-duplo` (grid 2 colunas, gap 16px)
- [ ] Adicionar classe `.painel-coluna` (overflow-y auto, max-height calc(100vh - 160px))
- [ ] Adicionar media query `@media (max-width: 900px)` para empilhar colunas
- [ ] Adicionar classe `.painel-coluna-header` (título de cada coluna: "Rotinas Uniface" / "Corvu")
- [ ] Adicionar classe `.movimento-header` (cabeçalho de data do movimento — cor #4fc3f7, padding, border-bottom)
- [ ] Adicionar classe `.badge-dia-anterior` (badge laranja com data da rotina pendente)
- [ ] Adicionar classe `.admin-panel` (painel de controle de categorias — fundo escuro, borda azul)
- [ ] Adicionar classe `.cat-item` (linha de cada categoria no painel admin)
- [ ] Adicionar classe `.cat-badge-bloqueada` (badge vermelho "BLOQUEADA")
- [ ] Adicionar classe `.cat-badge-liberada` (badge verde "LIBERADA")
- [ ] Adicionar classe `.btn-cat-toggle` (botão Liberar/Bloquear categoria)
- [ ] Adicionar classe `.chamado-input` (input de número de chamado — estilo similar ao erro-desc)
- [ ] Adicionar classe `.tab-btn-bloqueada` (aba com ícone 🔒 para admin — opacidade reduzida)

## Tarefa 2: Reestruturar abas no dashboard.html

- [ ] Remover abas separadas: "Uniface Diária", "Corvu Diário", "Final de Semana", "Corvu F. Semana"
- [ ] Adicionar aba "📋 Diário" (substitui as 2 abas diárias)
- [ ] Adicionar aba "📆 Final de Semana" (substitui as 2 abas de FDS)
- [ ] Manter abas: "📅 Mensal", "🏥 Unimed", "🔍 Serasa"
- [ ] Manter botão "🗓️ Horários" como link para horarios.html
- [ ] Criar divs de conteúdo: `#tab-diario`, `#tab-fds`, `#tab-mensal`, `#tab-unimed`, `#tab-serasa`
- [ ] Remover divs antigos: `#tab-diaria`, `#tab-corvu`, `#tab-corvufds`
- [ ] Adicionar div `#admin-panel` acima das abas (visível apenas para admin)

## Tarefa 3: Implementar cabeçalho "Movimento do Dia" (Requisito 12)

- [ ] Criar função `getMovimentoHeader()` que retorna string formatada com data atual em pt-BR
- [ ] Criar função `renderMovimentoHeader(containerId)` que injeta o cabeçalho no topo de cada aba
- [ ] Chamar `renderMovimentoHeader` em `renderAll()` para todas as abas visíveis
- [ ] Incluir atualização automática do cabeçalho no `setInterval` de virada de dia (já existente)
- [ ] Remover o `#dataAtualBar` antigo e substituir pelo novo cabeçalho padronizado

## Tarefa 4: Implementar painel duplo Diário (Requisito 10)

- [ ] Criar função `renderPainelDuplo(tabId, rotinasList, corvuList, prefixRotinas, prefixCorvu, diaKey)`
- [ ] Renderizar coluna esquerda com cabeçalho "📋 Rotinas Uniface" + lista de rotinas
- [ ] Renderizar coluna direita com cabeçalho "🖥️ Corvu" + tabela Corvu
- [ ] Aplicar `.painel-duplo` e `.painel-coluna` ao container
- [ ] Chamar `renderPainelDuplo` para aba "Diário" com `ROTINAS_DIARIA` + `ROTINAS_CORVU`
- [ ] Chamar `renderPainelDuplo` para aba "Final de Semana" com `ROTINAS_FDS` + `ROTINAS_CORVU_FDS`
- [ ] Verificar se `ROTINAS_FDS` e `ROTINAS_CORVU_FDS` existem no data.js; criar arrays vazios se ausentes

## Tarefa 5: Implementar controle de visibilidade de categorias (Requisito 11)

- [ ] Criar função `isCatLiberada(prefix)` — retorna `true` para 'diario' e 'fds' sempre; para outros lê `localStorage.getItem('cat_liberada_' + prefix) === 'true'`
- [ ] Criar função `toggleCategoria(prefix)` — alterna entre liberar e bloquear, persiste no localStorage
- [ ] Criar função `renderTabs()` — renderiza a barra de abas filtrando por perfil e estado de liberação
  - Operador: só exibe abas liberadas
  - Admin: exibe todas, com ícone 🔒 nas bloqueadas
- [ ] Criar função `renderPainelAdmin()` — renderiza o painel de controle de categorias para admin
  - Lista: Mensal, Unimed, Serasa com estado atual e botão toggle
- [ ] Chamar `renderTabs()` no `setInterval` de 30 segundos para operadores detectarem liberações
- [ ] Chamar `renderPainelAdmin()` no carregamento inicial se `role === 'admin'`
- [ ] Garantir que abas bloqueadas não sejam acessíveis por clique direto para operadores

## Tarefa 6: Atualizar função renderRotinas com novos campos (Requisitos 1, 3, 4, 5)

- [ ] Adicionar parâmetro `diaKey` opcional em `renderRotinas` e `buildRotinaHtml`
- [ ] **Campos de início/fim**: exibir condicionalmente conforme status (executando → início; encerrado/erro → início + fim)
- [ ] **Auto-preenchimento**: em `mudarStatus`, preencher `inicio` ao selecionar `executando` ou `erro` (se ainda vazio); preencher `fim` ao selecionar `encerrado` (se ainda vazio)
- [ ] **Campo chamado**: exibir input `chamado` abaixo da textarea de erro quando `status === 'erro'`
- [ ] Persistir `chamado` via `mudarCampo` no evento `blur` do input
- [ ] Exibir valor do chamado em rótulo de leitura quando preenchido e status for erro
- [ ] **Propriedade `campos`**: renderizar um input por item `{k, label}`, sempre visível
- [ ] **Propriedade `campo`**: renderizar input único com placeholder, sempre visível
- [ ] Restaurar valores de `campos` e `campo` do localStorage ao renderizar
- [ ] Desabilitar select de status quando rotina estiver bloqueada (`disabled`)

## Tarefa 7: Atualizar lógica de bloqueio individual (Requisito 2)

- [ ] Atualizar `getBlocked(prefix, diaKey)` — para prefix 'diaria' usar chave `blocked_diaria_{diaKey}`; para demais usar `blocked_{prefix}`
- [ ] Atualizar `toggleBlock(prefix, id, diaKey)` — passar diaKey para rotinas diárias
- [ ] Garantir que bloqueio diário não persista para o dia seguinte (chave inclui DiaKey)
- [ ] Garantir que bloqueio de outras abas persista indefinidamente
- [ ] Atualizar chamadas de `toggleBlock` no HTML gerado para passar diaKey quando necessário

## Tarefa 8: Implementar bloco de rotinas do dia anterior (Requisito 7)

- [ ] Atualizar função `renderBlocoDiaAnterior(container)`:
  - Verificar `status_diaria_{diaAnterior}` por itens com `status === 'executando'`
  - Renderizar bloco separado acima das rotinas do dia atual
  - Exibir cabeçalho "⚠️ Rotinas pendentes de DD/MM/AAAA — X ainda em execução"
  - Atualizar contador X dinamicamente ao encerrar rotinas
- [ ] Adicionar badge `<span class="badge-dia-anterior">Rotinas DD/MM/AAAA</span>` ao lado do nome de cada rotina pendente
- [ ] Exibir bloco imediatamente no carregamento da aba (sem aguardar setInterval)
- [ ] Ocultar bloco automaticamente quando X chegar a zero
- [ ] Incluir verificação do bloco no `setInterval` de 60 segundos já existente

## Tarefa 9: Atualizar função renderAll e inicialização

- [ ] Atualizar `renderAll()` para chamar `renderPainelDuplo` nas abas Diário e FDS
- [ ] Atualizar `renderAll()` para chamar `renderRotinas` nas abas Mensal, Unimed, Serasa
- [ ] Chamar `renderMovimentoHeader` para cada aba no início de cada render
- [ ] Chamar `renderBlocoDiaAnterior` na aba Diário antes das rotinas do dia atual
- [ ] Chamar `renderTabs()` na inicialização e no setInterval de 30s
- [ ] Chamar `renderPainelAdmin()` na inicialização se admin
- [ ] Remover referências às abas antigas (diaria, corvu, corvufds separados)
- [ ] Ajustar `abrirTab()` para os novos IDs de aba

## Tarefa 10: Verificação final e testes manuais

- [ ] Verificar que operador não vê abas bloqueadas (Mensal, Unimed, Serasa) antes de liberação
- [ ] Verificar que admin vê todas as abas com indicador 🔒 nas bloqueadas
- [ ] Verificar que ao admin liberar categoria, operador vê a aba em até 30s
- [ ] Verificar painel duplo: Uniface e Corvu lado a lado na aba Diário
- [ ] Verificar painel duplo: Uniface FDS e Corvu FDS lado a lado na aba Final de Semana
- [ ] Verificar responsividade: em tela < 900px colunas empilham verticalmente
- [ ] Verificar cabeçalho "Movimento do Dia DD/MM/AAAA" em todas as abas
- [ ] Verificar auto-preenchimento de início ao marcar Executando
- [ ] Verificar auto-preenchimento de fim ao marcar Encerrado
- [ ] Verificar campo Chamado aparece e persiste ao marcar Erro
- [ ] Verificar campos Terminal/Servidor nas rotinas Credicoamo (d1–d5)
- [ ] Verificar campos `campo` (OK, Sem Arquivo, etc.) nas rotinas correspondentes
- [ ] Verificar bloqueio individual: rotina bloqueada fica riscada e select desabilitado
- [ ] Verificar que bloqueio diário não persiste no dia seguinte
- [ ] Verificar bloco de rotinas do dia anterior com badge de data
- [ ] Verificar que dados persistem após recarregar a página (F5)
