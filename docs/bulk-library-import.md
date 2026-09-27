# Importar filmes e séries em lote

O CinemaTV oferece duas ações de App Intents e a entrada **Biblioteca → + → Importar**. Texto e imagens usam o mesmo fluxo: extrair títulos, consultar o TMDB, revisar as correspondências e salvar. A leitura do texto das imagens usa Vision no aparelho; a interpretação de uma lista ditada usa o AgentEngine com um modelo local. As imagens não são enviadas ao TMDB: somente os termos de busca.

## Pela Siri

1. Diga **“Adicionar filmes e séries no CinemaTV”** ou **“Importar uma lista no CinemaTV”**.
2. Quando a Siri perguntar pelos títulos, dite a lista. Também é possível fornecer texto para a ação no app Atalhos.
3. Escolha **Assistidos** ou **Quero assistir**.
4. Se houver versões com nomes semelhantes, escolha a correspondência ou pule o título.
5. Confira os títulos e confirme a adição. O resultado distingue conteúdos salvos, já existentes, ignorados e falhas.

Lotes de até dez títulos são revisados na Siri. Acima disso, a Siri abre a revisão no CinemaTV com os nomes e o destino já preenchidos. Nada é salvo nessa passagem para o app.

Sem o modelo local disponível, use uma lista com um título por linha ou separado por ponto e vírgula. Não dividimos automaticamente títulos em vírgulas ou palavras como “e”, pois elas podem fazer parte do nome.

## Prints com um atalho acionado pela Siri

No app Atalhos, crie um atalho com estas ações:

1. **Obter capturas de tela mais recentes**, escolhendo a quantidade desejada, ou **Selecionar Fotos**, permitindo múltipla seleção.
2. A ação do CinemaTV **Adicionar filmes e séries de prints**, recebendo as imagens da ação anterior.
3. Configure **Adicionar como** para Assistidos ou Quero assistir; alternativamente, use Perguntar Sempre.

Salve o atalho com um nome como **“Importar meus prints”**. Depois de tirar o print, diga **“Siri, importar meus prints”**. O atalho fornece explicitamente os arquivos ao CinemaTV. Os nomes das ações do sistema podem variar conforme o idioma do iOS.

Para usar pelo compartilhamento, habilite **Mostrar na Folha de Compartilhamento** em um atalho que aceite imagens e conecte a Entrada do Atalho à ação de importação do CinemaTV. Essa é uma ação de Atalhos; o app não instala uma extensão própria na folha de compartilhamento.

Também é possível selecionar até 10 prints em **Biblioteca → + → Escolher prints**. Não é necessário dar acesso irrestrito à fototeca.

## Visual Intelligence

A busca visual existente continua sem alterar a biblioteca. Ao receber a continuação de busca de conteúdo semântico (“mais resultados”), o CinemaTV abre a revisão dos títulos reconhecidos na área selecionada. A gravação acontece somente depois de confirmar no app.

Não se deve anunciar que um pedido livre como “adicione tudo desta tela” permite ao CinemaTV capturar automaticamente a tela de qualquer outro app. A Siri e o Visual Intelligence são superfícies distintas; o acesso a imagens depende da entrada fornecida pelo sistema/atalho. Os novos recursos de Siri AI também dependem de idioma, aparelho e disponibilidade do sistema. As frases localizadas de App Shortcuts são a integração explícita para português.

## Regras de importação

- Até 50 títulos ou 10 imagens por execução. Cada imagem tem limite de 20 MB. Limites são comunicados, sem corte silencioso da lista.
- Filmes e séries são identificados pelo tipo e ID do TMDB. Repetir o mesmo print não deve criar duplicatas.
- Adicionar à fila não transforma um filme já assistido em pendente.
- Assistidos: filmes precisam ter estreado; séries incluem os episódios já exibidos das temporadas regulares. Especiais e episódios futuros ficam de fora. A confirmação explica essa regra.
- As datas e o progresso já existentes são preservados. Uma falha na consulta de um título aparece na revisão, sem impedir a seleção dos demais.
- Históricos sem data de visualização mantêm essa data desconhecida; a biblioteca usa o progresso dos episódios para separar séries pendentes, em andamento e concluídas.
- Cancelar a revisão não salva nenhum item. Falhas durante a gravação são apresentadas por conteúdo.

## Validação em aparelho

- Siri em português: invocar a frase, ditar dois filmes e uma série, escolher o destino, cancelar e conferir que a biblioteca não mudou. Repetir e confirmar.
- Siri: usar um nome ambíguo com e sem ano, conferir a escolha e a possibilidade de pular.
- Atalhos: fornecer um e vários prints pela ação de Fotos e pela folha de compartilhamento. Repetir a importação para verificar duplicatas.
- Prints: testar lista de uma coluna, grade, títulos curtos, anos separados do título e screenshots com barras de navegação. Corrigir/remover correspondências na revisão quando necessário.
- Importação de série como assistida: confirmar que episódios futuros e especiais continuam desmarcados e o progresso anterior foi preservado.
- Testar sem rede, com Apple Intelligence desligada e com arquivo inválido. Mensagens devem diferenciar falta de títulos de falha de consulta.
- Visual Intelligence exige aparelho compatível; o SDK do Simulator não inclui o framework. Validar a continuação de busca e a revisão em um aparelho real.

## Verificação automatizada

Em 14/09/2026: 13 testes de domínio e 20 testes do app passaram, incluindo uma imagem PNG de lista → Vision → títulos e anos, cancelamento, preservação do histórico, falhas parciais e deduplicação. Builds do iOS Simulator e do SDK de iPhone concluídos, incluindo o código de Visual Intelligence. O app também iniciou no simulador; a conferência por toques ficou impedida porque o Mac estava bloqueado. O fluxo conversacional da Siri e a continuação do Visual Intelligence ainda precisam de validação em aparelho compatível.

## Referências da Apple

- [Parâmetros de App Intents, incluindo coleções](https://developer.apple.com/documentation/appintents/adding-parameters-to-an-app-intent)
- [IntentFile](https://developer.apple.com/documentation/appintents/intentfile)
- [Integração com Visual Intelligence](https://developer.apple.com/documentation/visualintelligence/integrating-your-app-with-visual-intelligence)
- [App Intents avançados e contexto de tela, WWDC26](https://developer.apple.com/videos/play/wwdc2026/343/)
- [Integração de busca visual e continuação no app, WWDC25](https://developer.apple.com/videos/play/wwdc2025/275/)
