# Integração com a API do Trakt

Última revisão: 30 de agosto de 2026.

Este documento registra o contrato da integração Trakt → CinemaTV. A integração
é opcional, somente de importação e nunca envia alterações da biblioteca local
ao Trakt.

## Fontes oficiais

- Introdução: <https://docs.trakt.tv/docs/getting-started>
- Autenticação OAuth: <https://docs.trakt.tv/docs/authentication-oauth>
- Referência de autenticação: <https://docs.trakt.tv/reference/auth>
- Troca e renovação de token: <https://docs.trakt.tv/reference/postoauthtoken>
- Índice legível por ferramentas: <https://docs.trakt.tv/llms.txt>
- Discussões e anúncios da API: <https://github.com/trakt/trakt-api/discussions>

Antes de alterar endpoints ou modelos, conferir novamente essas fontes. O Trakt
mudou autenticação e paginação em 2026.

## Cadastro e configuração

O aplicativo deve ser cadastrado em <https://app.trakt.tv/settings/apps> com:

- Redirect URI: `cinematv://trakt-auth`.
- Client ID e client secret copiados para `Trakt.plist`.
- O redirect URI deve ser idêntico, inclusive em maiúsculas/minúsculas, no
  cadastro, autorização e troca de token.

`Trakt.plist` versionado contém somente placeholders. Credenciais reais não
devem ser commitadas.

### Limitação conhecida

O endpoint de token exige `client_secret`. Nesta versão, por decisão de
arquitetura, a troca acontece diretamente no app. Um segredo dentro de um bundle
iOS pode ser extraído e não deve ser considerado confidencial. A evolução
recomendada é mover troca e refresh para um backend controlado pelo CinemaTV.

## OAuth 2.0

O app usa Authorization Code Flow porque pode abrir um navegador e receber um
callback.

1. Abrir `https://trakt.tv/oauth/authorize` com `response_type=code`,
   `client_id`, `redirect_uri` e um `state` aleatório.
2. Receber o callback por `ASWebAuthenticationSession`.
3. Rejeitar callbacks cujo `state` seja diferente.
4. Enviar o código para `POST https://auth.trakt.tv/oauth/token`.
5. Guardar access token, refresh token e expiração no Keychain.

Access tokens são válidos por 7 dias. Refresh tokens são de uso único: todo
refresh bem-sucedido devolve um novo par e invalida imediatamente o refresh
token anterior. O app substitui os dois valores juntos no Keychain. Um
`invalid_grant` exige nova autorização.

Desconectar remove os tokens e metadados locais da conta, mas preserva os itens
já incorporados à biblioteca.

## Headers

Toda chamada à API v2 envia:

```http
trakt-api-key: <client-id>
trakt-api-version: 2
Authorization: Bearer <access-token>
Content-Type: application/json
```

Base URL dos dados: `https://api.trakt.tv`.

## Endpoints usados

| Finalidade | Endpoint | Extended |
| --- | --- | --- |
| Watchlist de filmes | `GET /users/me/watchlist/movies` | `min` |
| Watchlist de séries | `GET /users/me/watchlist/shows` | `min` |
| Filmes assistidos | `GET /sync/watched/movies` | `min` |
| Séries e episódios assistidos | `GET /sync/watched/shows` | `progress` |
| Identidade da conta | `GET /users/settings` | `min` |

Todos os endpoints de listas são chamados com `page` e `limit` explícitos.
O modo `progress` usa limite 100; os demais solicitam 250.

### Paginação vigente

Desde julho de 2026, os endpoints watched paginam filmes, séries e episódios.
Sem parâmetros, eles retornam somente a primeira página, com até 100 itens.
O limite geral aplicado é no máximo 250, enquanto `extended=progress` é
limitado a 100.

O cliente usa os headers `X-Pagination-Page-Count` devolvidos pela resposta e
também encerra ao receber um array vazio. Nunca presume que o limite solicitado
foi aplicado.

## Rate limiting e erros

- `401`: tentar refresh uma vez; se a sessão não puder ser renovada, pedir
  nova conexão.
- `429`: respeitar `Retry-After`; não avançar a data da última sincronização.
- `5xx` e falhas de transporte: preservar a biblioteca e permitir nova
  tentativa.
- Erro de decoding ou página incompleta: não considerar a sincronização
  concluída.

Os limites numéricos podem mudar. Usar os headers da resposta como fonte de
verdade em vez de codificar uma cota fixa.

## Identidade, hidratação e merge

Objetos Trakt incluem `ids.trakt`, `ids.slug`, `ids.imdb` e
`ids.tmdb`. O CinemaTV usa exclusivamente `ids.tmdb` como identidade
canônica, porque sua biblioteca e seus detalhes já são baseados no TMDB.

- Nunca deduplicar apenas por título ou ano.
- Um item sem TMDB ID é ignorado e contabilizado no resultado.
- Os dados do Trakt fornecem identidade e progresso.
- O TMDB hidrata título localizado, datas, imagens, temporadas e episódios.
- Imagens do Trakt não são usadas.

### Filmes

- Watchlist remota adiciona o filme somente se ele não estiver na fila nem em
  assistidos.
- Assistido remoto remove uma eventual entrada da fila e cria ou atualiza uma
  única entrada em assistidos.
- Reimportar o mesmo payload é idempotente.
- Quando existem datas local e remota, preserva-se a data assistida mais antiga.

### Séries

- Uma única `TVShowWatchingModel` existe por TMDB show ID.
- Temporada 0/especiais é ignorada, acompanhando o modelo local existente.
- Episódios são identificados por
  `(showID, seasonNumber, episodeNumber)`.
- O conjunto final é a união do progresso local e remoto. A ausência de um
  episódio no Trakt nunca apaga progresso local.
- Depois do merge, os caches de progresso, última atividade e Up Next são
  recalculados pelos stores.

## Ciclo de sincronização

- A primeira importação ocorre imediatamente após o opt-in e OAuth concluído.
- Settings oferece `Sync Now` sem throttle.
- Ao abrir a Library, uma atualização silenciosa roda no máximo uma vez a cada
  24 horas.
- A data de sucesso só é atualizada depois de baixar, hidratar e mesclar todas
  as categorias.
- Nenhuma mutação local é exportada para o Trakt nesta versão.
