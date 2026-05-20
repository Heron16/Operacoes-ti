# Documento de Requisitos

## Introdução

A Coamo executa diariamente centenas de rotinas batch e Corvu distribuídas ao longo de 24 horas. Hoje, o controle dessas execuções é feito em papel: os operadores anotam horários de início e fim, registram o terminal e servidor utilizados, marcam campos específicos por rotina (ex.: "OK", "Sem Arquivo") e anotam números de chamado quando ocorrem erros.

O objetivo desta feature é digitalizar esse controle no sistema web já existente (`dashboard.html`, `data.js`, `style.css`), que já possui login, abas por categoria de rotina, seleção de status (Executando, Encerrado, Erro) e bloqueio básico de rotinas. As melhorias devem ser integradas ao fluxo atual sem quebrar funcionalidades existentes.

---

## Glossário

- **Sistema**: A aplicação web de controle de rotinas da Coamo (dashboard.html + data.js + style.css).
- **Rotina**: Uma tarefa batch ou Corvu agendada para execução em um horário específico, representada por um objeto no `data.js`.
- **Operador**: Usuário autenticado com role `operador` que registra a execução das rotinas.
- **Admin/Supervisor**: Usuário autenticado com role `admin` — equivale ao supervisor; possui permissões exclusivas de liberar categorias de rotinas para visualização dos operadores.
- **Status**: Estado atual de uma rotina — pode ser vazio (não iniciada), `executando`, `encerrado` ou `erro`.
- **Chamado**: Número de ticket de suporte aberto quando uma rotina apresenta erro (ex.: INC0012345).
- **Campo Especial**: Campo adicional específico de uma rotina, definido pelas propriedades `campo` ou `campos` no `data.js` (ex.: Terminal, Servidor, OK, Sem Arquivo).
- **Bloqueio de Rotina**: Marcação individual que indica que uma rotina específica não deve ser executada em um determinado dia (feriado ou final de semana).
- **Categoria Bloqueada**: Estado de uma categoria inteira (ex.: Mensal, Unimed) em que todas as rotinas ficam ocultas para operadores até o admin liberar.
- **Liberar Categoria**: Ação exclusiva do admin que torna uma categoria visível para todos os operadores simultaneamente.
- **Prefix**: Identificador da categoria de rotinas usado como chave no `localStorage` (ex.: `diaria`, `mensal`, `fds`, `corvu`).
- **DiaKey**: String no formato `YYYY-MM-DD` que identifica o dia de execução das rotinas diárias.
- **localStorage**: Mecanismo de persistência de dados no navegador utilizado pelo Sistema.
- **Painel Duplo**: Layout de tela dividida em duas colunas que exibe simultaneamente as rotinas Uniface e as rotinas Corvu da mesma categoria (Diário ou Final de Semana).

---

## Requisitos

### Requisito 1: Registro de Horário de Início e Fim

**User Story:** Como operador, quero registrar o horário de início e fim de cada rotina diretamente no sistema, para que eu não precise mais anotar em papel e o histórico fique digitalizado.

#### Critérios de Aceitação

1. WHEN o operador seleciona o status `executando` para uma rotina que ainda não possui horário de início registrado, THE Sistema SHALL preencher automaticamente o campo "Início" com o horário atual no formato `HH:MM` e persistir o valor no `localStorage`.
2. WHEN o operador seleciona o status `encerrado` para uma rotina que ainda não possui horário de fim registrado, THE Sistema SHALL preencher automaticamente o campo "Fim" com o horário atual no formato `HH:MM` e persistir o valor no `localStorage`.
3. WHEN o operador seleciona o status `erro` para uma rotina que ainda não possui horário de início registrado, THE Sistema SHALL preencher automaticamente o campo "Início" com o horário atual no formato `HH:MM` e persistir o valor no `localStorage`.
4. WHILE o status de uma rotina for `executando`, `encerrado` ou `erro`, THE Sistema SHALL exibir o campo "Início" como um input de texto editável com o valor atual.
5. WHILE o status de uma rotina for `encerrado` ou `erro`, THE Sistema SHALL exibir o campo "Fim" como um input de texto editável com o valor atual.
6. WHEN o operador edita manualmente o campo "Início" ou "Fim" (evento `change` no input), THE Sistema SHALL persistir o novo valor no `localStorage`, sobrescrevendo o valor anterior para aquele campo.
7. IF o operador alterar o status de `encerrado` ou `erro` de volta para `executando`, THEN THE Sistema SHALL manter o horário de início já registrado no `localStorage` e ocultar o campo "Fim" da interface.
8. IF o operador alterar o status de `encerrado` ou `erro` de volta para `executando`, THEN THE Sistema SHALL manter o valor de "Fim" previamente registrado no `localStorage` sem exibi-lo na interface.
9. THE Sistema SHALL aplicar os campos de início e fim às rotinas das abas Uniface Diária e Final de Semana.

---

### Requisito 2: Bloqueio de Rotinas para Feriados e Finais de Semana

**User Story:** Como operador, quero bloquear rotinas que não devem ser executadas em feriados ou finais de semana, para que a equipe saiba visualmente quais rotinas estão suspensas naquele dia.

#### Critérios de Aceitação

1. THE Sistema SHALL exibir um botão de bloqueio (🔒) em cada rotina de todas as abas quando a rotina estiver desbloqueada.
2. WHEN o operador clica no botão 🔒 de uma rotina desbloqueada, THE Sistema SHALL adicionar o `id` da rotina ao array persistido no `localStorage` sob a chave `blocked_{prefix}` e atualizar o botão para exibir 🔓.
3. WHEN o operador clica no botão 🔓 de uma rotina bloqueada, THE Sistema SHALL remover o `id` da rotina do array em `blocked_{prefix}` no `localStorage` e atualizar o botão para exibir 🔒.
4. WHILE uma rotina estiver bloqueada, THE Sistema SHALL aplicar a classe CSS `rotina-item blocked` ao elemento da rotina, exibindo-a com opacidade reduzida, texto riscado e o rótulo "BLOQUEADA".
5. WHILE uma rotina estiver bloqueada, THE Sistema SHALL renderizar o seletor de status como desabilitado (`disabled`), preservando os dados de status, início e fim já registrados sem permitir novas alterações.
6. IF o operador tentar alterar o status de uma rotina bloqueada via código (ex.: chamada direta à função de atualização), THEN THE Sistema SHALL ignorar a ação e manter o estado bloqueado sem alterar o `localStorage`.
7. THE Sistema SHALL persistir o estado de bloqueio de forma independente por categoria (`prefix`), de modo que bloquear uma rotina na aba Diária não afete a mesma rotina na aba Final de Semana.
8. THE Sistema SHALL persistir o bloqueio de rotinas diárias com escopo por `DiaKey`, de modo que uma rotina bloqueada em um dia não apareça como bloqueada no dia seguinte; para as demais abas (Mensal, Unimed, Final de Semana), o bloqueio persiste indefinidamente até ser removido manualmente.

---

### Requisito 3: Registro de Número de Chamado

**User Story:** Como operador, quero registrar o número do chamado (ticket) quando uma rotina apresenta erro, para que o histórico de incidentes fique vinculado à rotina correspondente.

#### Critérios de Aceitação

1. WHILE o status de uma rotina for `erro`, THE Sistema SHALL exibir um campo de texto para o número do chamado com placeholder "Nº do Chamado (ex: INC0012345)" abaixo do campo de descrição de erro existente.
2. WHEN o operador preenche o campo de número de chamado e o campo perde o foco (evento `blur`), THE Sistema SHALL persistir o valor no `localStorage` sob a chave `chamado` no objeto de status da rotina correspondente.
3. WHILE o status de uma rotina for `erro` e a chave `chamado` no `localStorage` estiver preenchida com valor não vazio, THE Sistema SHALL exibir o número do chamado em um rótulo de leitura abaixo da descrição de erro.
4. WHEN o operador altera o status de `erro` para qualquer outro valor, THE Sistema SHALL ocultar o campo de número de chamado e o rótulo de exibição, mantendo o valor persistido no `localStorage` sem alteração.
5. THE Sistema SHALL exibir o campo de número de chamado em todas as abas que possuem seleção de status: Uniface Diária, Uniface Mensal, Unimed, Serasa e Final de Semana.

---

### Requisito 4: Campos Especiais por Rotina — Terminal e Servidor

**User Story:** Como operador, quero registrar o Terminal e o Servidor onde as rotinas Credicoamo foram executadas, para que o controle operacional fique completo e rastreável.

#### Critérios de Aceitação

1. THE Sistema SHALL renderizar um input de texto para cada objeto `{k, label}` presente no array `campos` de uma rotina no `data.js`, usando `label` como texto de rótulo visível e `k` como atributo `data-key` do input.
2. WHEN o operador preenche um input de `campos` e o campo perde o foco (evento `blur`), THE Sistema SHALL persistir o valor no `localStorage` sob a chave `k` dentro do objeto de status da rotina correspondente.
3. THE Sistema SHALL exibir os inputs de `campos` na área de ações da rotina, visíveis independentemente do status atual da rotina (inclusive quando status for vazio).
4. THE Sistema SHALL aplicar a renderização de `campos` exclusivamente às rotinas das abas Uniface Diária e Final de Semana que possuem a propriedade `campos` definida no `data.js`; rotinas sem essa propriedade não exibem esses inputs.
5. WHEN a página é carregada ou recarregada, THE Sistema SHALL restaurar o valor de cada chave `k` a partir do objeto de status da rotina no `localStorage` e preencher o input correspondente; se a chave não existir, o input SHALL ser exibido vazio.

---

### Requisito 5: Campos Especiais por Rotina — Campo Único (`campo`)

**User Story:** Como operador, quero preencher campos específicos de rotinas como "OK", "Sem Arquivo" ou outros indicadores, para que o controle fique completo sem precisar de anotações em papel.

#### Critérios de Aceitação

1. IF uma rotina possuir a propriedade `campo` definida no `data.js` com valor não vazio, THEN THE Sistema SHALL renderizar um único input de texto para essa rotina, usando o valor de `campo` como atributo `placeholder` do input.
2. WHEN o operador preenche o input de campo único e o campo perde o foco (evento `blur`), THE Sistema SHALL persistir o valor no `localStorage` sob a chave `campoval` no objeto de status da rotina correspondente; o valor persistido SHALL ser limitado a 100 caracteres.
3. THE Sistema SHALL exibir o input de campo único na área de ações da rotina, visível independentemente do status atual da rotina (inclusive quando status for vazio).
4. WHEN a página é carregada ou recarregada, THE Sistema SHALL restaurar o valor de `campoval` a partir do objeto de status da rotina no `localStorage` e preencher o input; se a chave não existir ou for vazia, o input SHALL ser exibido vazio com o placeholder original.
5. IF uma rotina não possuir a propriedade `campo` definida no `data.js`, THEN THE Sistema SHALL não renderizar o input de campo único para essa rotina.

---

### Requisito 6: Persistência e Restauração de Estado

**User Story:** Como operador, quero que todos os dados registrados durante o turno sejam preservados ao recarregar a página, para que nenhuma informação seja perdida por acidente.

#### Critérios de Aceitação

1. THE Sistema SHALL persistir todos os campos de controle (status, início, fim, chamado, campoval, e cada chave `k` de `campos`) no `localStorage` do navegador como um objeto JSON indexado pelo `id` da rotina.
2. WHEN a página é carregada ou recarregada, THE Sistema SHALL restaurar os valores de status, início, fim, chamado, campoval e campos dinâmicos (`k`) a partir do `localStorage` e renderizar cada rotina com os dados salvos antes de exibir a interface ao operador.
3. THE Sistema SHALL usar a chave `status_diaria_{DiaKey}` (onde `DiaKey` é a data no formato `YYYY-MM-DD`) para rotinas diárias, garantindo que cada dia possua um registro independente no `localStorage`.
4. THE Sistema SHALL usar chaves fixas no formato `status_{prefix}` para rotinas mensais, Unimed, Serasa e Final de Semana; esses dados persistem no `localStorage` até que o operador altere ao menos um campo manualmente.
5. IF a tentativa de leitura de uma chave no `localStorage` resultar em erro de parse JSON (valor não é JSON válido) ou retornar `null`/`undefined`, THEN THE Sistema SHALL inicializar o estado daquela chave com um objeto vazio `{}` e renderizar as rotinas correspondentes sem dados preenchidos, sem exibir mensagem de erro ao operador.
6. IF o `localStorage` estiver indisponível (ex.: modo de navegação privada com cota zero ou exceção de segurança ao acessar `window.localStorage`), THEN THE Sistema SHALL operar em modo de memória volátil (estado apenas em variável JavaScript), exibir um aviso não bloqueante informando que os dados não serão salvos ao recarregar, e permitir que o operador continue usando todas as funcionalidades normalmente.

---

### Requisito 7: Visualização de Rotinas com Dia Anterior em Execução

**User Story:** Como operador do turno da madrugada, quero ver as rotinas do dia anterior que ainda estão em execução junto com as do dia atual, identificadas pela data a que pertencem, para que eu possa encerrar rotinas pendentes sem perder o contexto do novo dia.

#### Critérios de Aceitação

1. WHEN o dia muda (a `DiaKey` atual difere da `DiaKey` do último acesso registrado) e existem rotinas do dia anterior com status `executando` no `localStorage`, THE Sistema SHALL exibir um bloco separado posicionado acima da lista de rotinas do dia atual na aba "Diário", contendo apenas as rotinas pendentes do dia anterior.
2. WHEN a aba "Diário" é carregada ou recarregada e existem rotinas do dia anterior com status `executando` no `localStorage`, THE Sistema SHALL exibir imediatamente o bloco do dia anterior sem aguardar o ciclo de verificação periódica.
3. WHILE o bloco do dia anterior estiver visível, THE Sistema SHALL exibir um rótulo de aviso no cabeçalho do bloco com o texto "⚠️ Rotinas pendentes de DD/MM/AAAA — X ainda em execução", onde `DD/MM/AAAA` é a data do dia anterior no formato brasileiro e `X` é o número atual de rotinas com status `executando` naquele dia.
4. THE Sistema SHALL exibir, ao lado do nome de cada rotina pendente do dia anterior, um badge com o texto "Rotinas DD/MM/AAAA" (ex.: "Rotinas 09/05/2026"), onde `DD/MM/AAAA` é a data do dia a que a rotina pertence, para distingui-la visualmente das rotinas do dia atual.
5. WHEN o operador altera o status de uma rotina pendente do dia anterior para `encerrado` ou `erro`, THE Sistema SHALL decrementar o contador `X` no rótulo de aviso e, se `X` chegar a zero, ocultar o bloco do dia anterior e remover todos os badges de data anterior.
6. THE Sistema SHALL verificar a existência de rotinas pendentes do dia anterior a cada 60 segundos e atualizar o bloco e o contador automaticamente.

---

### Requisito 8: Controle de Rotinas Corvu

**User Story:** Como operador, quero registrar início, fim, servidor, usuário e terminal para cada rotina Corvu, para que o controle dessas execuções também seja digitalizado.

#### Critérios de Aceitação

1. THE Sistema SHALL exibir cada rotina Corvu como uma linha de tabela com as seguintes colunas na ordem: Rotina (texto fixo, somente leitura), Início (input `time`), Fim (input `time`), Servidor (input `text`), Usuário (input `text`), Terminal (input `text`).
2. WHEN o operador preenche qualquer campo editável de uma rotina Corvu e o campo perde o foco (evento `blur`), THE Sistema SHALL persistir o objeto completo da rotina (com todos os cinco campos) no `localStorage` sob a chave `corvu_dados_corvu` para a aba "Corvu Diário" e `corvu_dados_corvufds` para a aba "Corvu Final de Semana", indexado pelo nome da rotina.
3. THE Sistema SHALL aplicar o layout de tabela com as colunas definidas no critério 1 às abas "Corvu Diário" e "Corvu Final de Semana"; outras abas não são afetadas.
4. WHEN a página é carregada ou recarregada, THE Sistema SHALL restaurar os valores de Início, Fim, Servidor, Usuário e Terminal de cada rotina Corvu a partir do objeto indexado pelo nome da rotina na chave correspondente do `localStorage`; campos sem valor salvo SHALL ser exibidos vazios.
5. THE Sistema SHALL usar as chaves `corvu_dados_corvu` e `corvu_dados_corvufds` sem sufixo de data, de modo que os dados Corvu persistam entre dias até que o operador sobrescreva ou limpe os campos manualmente.
6. IF a chave Corvu no `localStorage` não existir ou contiver JSON inválido, THEN THE Sistema SHALL inicializar o estado com um objeto vazio e exibir todos os campos da tabela Corvu vazios, sem bloquear a interface.

---

### Requisito 9: Controle de Acesso por Perfil

#### Critérios de Aceitação

1. WHEN um usuário não autenticado tenta acessar o dashboard (ausência de `user` no `sessionStorage`), THE Sistema SHALL redirecionar imediatamente para `index.html` sem renderizar o conteúdo do dashboard.
2. WHEN o dashboard é carregado após autenticação bem-sucedida, THE Sistema SHALL exibir no cabeçalho o nome do usuário autenticado e seu perfil (role) lidos do `sessionStorage`.
3. IF o usuário autenticado possuir role `operador` ou `admin`, THEN THE Sistema SHALL habilitar os botões de bloqueio (🔒/🔓) em todas as rotinas de todas as abas visíveis.
4. IF o usuário autenticado possuir role `operador` ou `admin`, THEN THE Sistema SHALL habilitar os seletores de status, campos de início/fim, campos de chamado e campos especiais em todas as rotinas não bloqueadas.
5. WHEN o operador clica em "Sair", THE Sistema SHALL executar `sessionStorage.clear()` e redirecionar para `index.html`.
6. IF o `sessionStorage` contiver a chave `user` mas a chave `role` estiver ausente ou contiver valor diferente de `operador` ou `admin`, THEN THE Sistema SHALL redirecionar para `index.html` e exibir a mensagem "Sessão inválida. Faça login novamente." no campo de erro da tela de login.

---

### Requisito 10: Layout Painel Duplo — Diário e Final de Semana

**User Story:** Como operador, quero ver as rotinas Uniface e as rotinas Corvu do mesmo turno lado a lado na mesma tela, para que eu não precise alternar entre abas durante a execução.

#### Critérios de Aceitação

1. THE Sistema SHALL substituir as abas separadas "Uniface Diária" e "Corvu Diário" por uma única aba chamada "Diário" que exibe as duas listas em um layout de duas colunas lado a lado: coluna esquerda com as rotinas Uniface Diária e coluna direita com as rotinas Corvu Diário.
2. THE Sistema SHALL substituir as abas separadas "Final de Semana" e "Corvu Final de Semana" por uma única aba chamada "Final de Semana" que exibe as duas listas em um layout de duas colunas lado a lado: coluna esquerda com as rotinas Uniface Final de Semana e coluna direita com as rotinas Corvu Final de Semana.
3. WHILE a largura da janela for inferior a 900px, THE Sistema SHALL empilhar as duas colunas verticalmente (Uniface acima, Corvu abaixo) para manter a legibilidade em telas menores.
4. THE Sistema SHALL exibir um cabeçalho de seção acima de cada coluna identificando o conteúdo: "Rotinas Uniface" para a coluna esquerda e "Corvu" para a coluna direita.
5. THE Sistema SHALL aplicar scroll independente em cada coluna, de modo que o operador possa rolar uma lista sem mover a outra.
6. THE Sistema SHALL manter todas as funcionalidades existentes (status, início/fim, bloqueio de rotina individual, campos especiais, chamado) em ambas as colunas do painel duplo.

---

### Requisito 11: Controle de Visibilidade de Categorias pelo Admin

**User Story:** Como admin (supervisor), quero controlar quais categorias de rotinas os operadores podem visualizar, para que rotinas que não se aplicam ao dia (ex.: Mensais em dia normal) não apareçam e não causem confusão.

#### Critérios de Aceitação

1. THE Sistema SHALL manter as seguintes categorias **sempre visíveis** para todos os perfis autenticados, sem necessidade de liberação: "Diário" (painel duplo Uniface + Corvu) e "Final de Semana" (painel duplo Uniface + Corvu).
2. THE Sistema SHALL manter as seguintes categorias **bloqueadas por padrão** (ocultas para operadores até liberação pelo admin): Mensal, Unimed, e qualquer outra categoria além das listadas no critério 1.
3. WHILE uma categoria estiver bloqueada, THE Sistema SHALL ocultar completamente a aba e todo o conteúdo dessa categoria para usuários com role `operador`; a aba não SHALL aparecer na barra de navegação nem ser acessível por URL direta.
4. WHILE uma categoria estiver bloqueada, THE Sistema SHALL exibir a aba para o admin com um indicador visual (ex.: ícone 🔒 ao lado do nome da aba) sinalizando que a categoria está oculta para operadores.
5. WHEN o admin clica no botão "Liberar categoria" de uma categoria bloqueada, THE Sistema SHALL marcar a categoria como liberada no `localStorage` sob a chave `cat_liberada_{prefix}` com valor `true` e tornar a aba imediatamente visível para todos os operadores que estiverem com o dashboard aberto (via verificação periódica a cada 30 segundos) ou na próxima vez que carregarem a página.
6. WHEN o admin clica no botão "Bloquear categoria" de uma categoria liberada, THE Sistema SHALL remover a chave `cat_liberada_{prefix}` do `localStorage` e ocultar a aba para todos os operadores na próxima verificação periódica ou recarregamento de página.
7. THE Sistema SHALL exibir, na tela do admin, um painel de controle de categorias com a lista de todas as categorias bloqueáveis, seu estado atual (bloqueada/liberada) e os botões de ação correspondentes.
8. WHEN a página é carregada, THE Sistema SHALL ler o estado de liberação de cada categoria a partir do `localStorage` e renderizar a barra de navegação de acordo com o perfil do usuário e o estado de cada categoria.
9. IF o admin liberar uma categoria e depois fizer logout, THEN THE Sistema SHALL manter a categoria liberada no `localStorage` até que o admin a bloqueie explicitamente; a liberação não expira automaticamente.

---

### Requisito 12: Cabeçalho de Data do Movimento

**User Story:** Como operador, quero ver claramente a data do movimento em todas as abas do sistema, para que eu tenha certeza de que estou registrando as rotinas no dia correto.

#### Critérios de Aceitação

1. THE Sistema SHALL exibir, no topo de cada aba, um cabeçalho com o texto "Movimento do Dia DD/MM/AAAA" onde `DD/MM/AAAA` é a data atual do sistema no formato brasileiro (ex.: "Movimento do Dia 10/05/2026").
2. THE Sistema SHALL atualizar o cabeçalho de data automaticamente à meia-noite sem necessidade de recarregar a página, de modo que operadores do turno da madrugada vejam a data correta ao virar o dia.
3. THE Sistema SHALL exibir o cabeçalho de data em todas as abas visíveis: Diário, Final de Semana, Mensal, Unimed e qualquer outra categoria presente no sistema.
4. THE Sistema SHALL posicionar o cabeçalho de data abaixo da barra de abas e acima do conteúdo da aba, de forma que fique sempre visível sem ocupar espaço excessivo.
5. THE Sistema SHALL aplicar ao cabeçalho de data um estilo visual destacado (ex.: cor azul `#4fc3f7`, fonte levemente maior que o corpo do texto) consistente com o design existente do sistema.
