# CinemaTV Boxes — Colecionador

Direção visual atualizada em 07/09/2026: estante escura, capas formadas pelos próprios conteúdos como cards empilhados, com destaque âmbar. Biblioteca pessoal, sem conta, feed ou seguidores.

## Comportamento aprovado

- Montagem livre com título, descrição e sequência de filmes, séries, temporadas, episódios, trailers, trilhas e impressões. A sequência forma a capa: primeiro item na frente; até cinco cards ficam visíveis, com contagem total. Reordenar ou remover itens atualiza a composição.
- Persistência pessoal SwiftData com a configuração iCloud existente; criação e edição locais também funcionam sem iCloud.
- Compartilhar cria uma edição fixa. Alterações posteriores não mudam o link já enviado.
- Quem recebe pode guardar o original somente para leitura, criar uma adaptação independente com crédito “Inspirado em”, ou fechar.
- Compartilhamento voluntário pela folha do sistema, com arte 9:16 ou 4:5 e link. Nome escolhido pelo usuário, sem cadastro.

## Implementação

1. Modelos, armazenamento e testes de persistência, edição fixa, importação e autoria.
2. Publicação CloudKit, leitura pública por UUID e validação de links; documentar implantação externa necessária.
3. Seleção com busca real TMDB e Apple Music, trailers, temporadas, episódios e impressões.
4. Capas de produção, estante na Biblioteca, compositor, detalhe, importação e compartilhamento.
5. Rotas, inclusão no projeto Xcode, localização em português e testes/build do app.

## Validação e limites de implantação

Executar testes do pacote e build iOS Simulator. Inspecionar telas e estados vazios/erros. Não publicar fixtures nem inventar domínio ou ID da App Store. Links HTTPS exigem domínio, Associated Domains, AASA e página com destino correto na loja; CloudKit requer schema público implantado. A reinstalação não recupera automaticamente um Universal Link: oferecer reabertura do link na página/mensagem.

## Resultado validado

- Build iOS Simulator aprovado com Xcode beta/iOS 27.
- 44 testes de domínio, links e navegação aprovados em 06/09/2026; fontes do pacote também incluídas no host CinemaTVTests para o export de test products do Xcode.
- Teste de interface completo aprovado: criar box com impressão, relançar, reabrir dados persistidos, editar impressão e apresentar compartilhamento da capa.
- Canvas nativo do Xcode renderizou “Boxes · Biblioteca integrada”. Previews usam armazenamento isolado em memória desde o lançamento do app.
- Falhas reais em SQLite somente leitura verificam recuperação sem descartar alterações pendentes de outras features. O teste compara IDs retornados pela UI e por um contexto novo.
- CloudKit público, Associated Domains e ida à App Store ainda requerem as configurações descritas em `docs/boxes-sharing-setup.md`; não houve publicação remota.

## Capas com conteúdo — 07/09/2026

- Componente único para estante, detalhe, montagem e compartilhamento. Impressões usam texto e autoria; itens sem pôster usam título e símbolo do tipo. Boxes vazios mostram cards por preencher.
- Seletores de capas prontas removidos. Campos antigos de estilo permanecem no modelo para compatibilidade com boxes e edições já salvas.
- Exportação carrega os pôsteres dos cards visíveis e usa as mesmas imagens da prévia; uma imagem indisponível mantém seu card de conteúdo. O carregamento é cancelado ao fechar a tela.
- Preview interativo “Boxes · Cards empilhados” permite alternar o conteúdo da frente e comparar um item único com um box vazio. O pôster de exemplo vem da [página pública de Interestelar no TMDB](https://www.themoviedb.org/movie/157336-interstellar/images/posters?language=fr-FR).
- Build iOS Simulator aprovado e teste de interface de criação, reabertura, edição e exportação aprovado em 07/09/2026 (1 teste, 0 falhas). Canvas nativo renderizou a composição com o pôster carregado.
