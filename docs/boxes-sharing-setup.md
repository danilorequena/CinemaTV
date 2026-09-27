# Compartilhamento de boxes

O app cria edições públicas no CloudKit e compartilha uma URL HTTPS de uma edição específica. Quem recebe pode ler a edição, guardar o original e criar uma versão inspirada nela. Publicar requer a conta iCloud dos Ajustes; não há cadastro de conta CinemaTV. A leitura da edição pública não exige login no iCloud.

## Configuração pendente para distribuição

O domínio de compartilhamento e o endereço real do CinemaTV na App Store precisam ser fornecidos pelo proprietário. Eles não são inventados nem publicados por este código. Configure `CinemaTVBoxesBaseURL` no Info.plist com a **origem HTTPS** escolhida, sem caminho, porta, credenciais, query ou fragmento. Enquanto a origem não estiver configurada, `publish` falha antes de consultar o iCloud ou salvar registros.

1. No Apple Developer e no target do app, habilite iCloud/CloudKit para `iCloud.com.danilorequena.CinemaTV`. O identificador pode ser trocado no inicializador do serviço se o container de produção for outro. Confirme que o provisioning profile contém esse container.
2. No CloudKit Console, crie o tipo `CinemaTVBoxEdition` na base **pública**, com os campos abaixo. O app faz lookup pelo record ID e não precisa de índices para consultas nesses campos.
3. Configure permissões do tipo: **World: Read; Authenticated: Create; Creator: Write**. Não conceda Write para World nem Authenticated. Promova o schema de development para production antes de distribuir via TestFlight/App Store; a promoção de schema não publica os registros de desenvolvimento.
4. Adicione `applinks:<DOMINIO_ESCOLHIDO>` em Associated Domains e hospede o AASA correspondente. Registre também o URL scheme `cinematv` para abrir explicitamente a edição a partir da landing page.
5. Publique a landing page `/boxes/<UUID>` no domínio escolhido, configure a URL real da App Store e valide o fluxo em dispositivo assinado.

| Campo | Tipo | Uso |
| --- | --- | --- |
| `schemaVersion` | Int64 | `1`; versões desconhecidas são rejeitadas |
| `editionID` | String | UUID canônico da edição |
| `payload` | Asset | JSON de `BoxEdition`, limitado a 8 MiB |

Record name: `box-<uuid-em-minúsculas>`. O app cria um novo record sem change tag com `.ifServerRecordUnchanged`, nunca atualiza uma edição existente. Repetir a publicação da mesma edição só retorna sucesso se o snapshot armazenado for igual. Um UUID já ocupado por conteúdo diferente resulta em conflito. Editar o box de origem exige uma nova edição para publicar mudanças.

As permissões Creator Write permitem ao criador alterar registros com outras ferramentas autorizadas. A imutabilidade aqui é garantida pelo comportamento do serviço/app, não por uma política CloudKit de append-only contra clientes modificados. Uma garantia contra o próprio criador exigiria publicação mediada por servidor ou verificações criptográficas adicionais.

O payload público conserva os nomes de exibição e o conteúdo editorial. IDs internos dos autores são substituídos por um pseudônimo limitado à edição. O nome de record do usuário iCloud nunca é copiado para campos públicos ou para a URL. O CloudKit mantém seus próprios metadados de criação/autorização. Não mostre nem exporte esses metadados na landing page.

Referências Apple: [schema e permissões](https://developer.apple.com/documentation/cloudkit/integrating-a-text-based-schema-into-your-workflow), [CKAsset](https://developer.apple.com/documentation/cloudkit/ckasset), [savePolicy](https://developer.apple.com/documentation/cloudkit/ckmodifyrecordsoperation/savepolicy).

## Universal Links e landing page

Sirva `https://<DOMINIO_ESCOLHIDO>/.well-known/apple-app-site-association` por HTTPS válido, sem redirects, com JSON como este, substituindo os placeholders pelo application identifier assinado e o domínio reais:

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["<TEAM_ID>.<BUNDLE_ID>"],
        "components": [{ "/": "/boxes/*" }]
      }
    ]
  }
}
```

A landing page deve identificar a edição pelo UUID do caminho e oferecer “Abrir no CinemaTV”, usando `cinematv://box/<UUID>`, e “Baixar na App Store”, apontando para a ficha real do app. Ela pode começar como uma página simples, sem expor o conteúdo público completo no browser. Se renderizar títulos, nomes ou resenhas, trate-os como texto não confiável e faça escape; nunca interprete esse conteúdo como HTML. Para buscar dados com CloudKit JS, configure uma chave web restrita ao domínio e use acesso de leitura à base pública. Nenhuma chave de servidor deve ser incorporada no app ou JavaScript público.

Com o app instalado, tocar no Universal Link entrega a edição diretamente ao fluxo de recebimento. Sem o app, o sistema abre a landing page. A instalação pela App Store **não repassa automaticamente** esse UUID no primeiro lançamento. A página deve orientar: “Depois de instalar, volte a este link para abrir o box.” Mantenha o UUID na URL e o botão de abertura; não use fingerprinting ou leitura automática da área de transferência para tentar recuperar o contexto.

O parser do app aceita somente `cinematv://box/<UUID>` ou `https://<DOMINIO_CONFIGURADO>/boxes/<UUID>`, com caminho exato. Schemes e hosts são comparados sem distinguir maiúsculas, e `/boxes/` diferencia maiúsculas. Queries/fragments de rastreamento são ignorados e nunca substituem o UUID do caminho. Links gerados são canônicos, sem parâmetros.

Referências Apple: [Associated Domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains), [comportamento e diagnóstico de Universal Links](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links).

## Validação antes de distribuição

Os testes automatizados locais verificam geração, parsing, limites de host, caminhos ambíguos e queries sem escrever no CloudKit. Nenhuma publicação real é necessária para executá-los.

Depois de configurar o ambiente de desenvolvimento, valide manualmente com dados fictícios: publicar; repetir a mesma edição; editar o box e publicar uma nova edição; receber em um segundo aparelho; guardar o original; adaptar preservando resenhas e autoria; abrir sem iCloud autenticado; abrir sem app instalado; voltar ao mesmo link após instalar. Confirme também que um usuário diferente não consegue alterar a edição pública original e que o schema de produção foi promovido.
