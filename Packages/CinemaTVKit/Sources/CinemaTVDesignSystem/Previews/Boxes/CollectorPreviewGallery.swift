#if DEBUG && os(iOS)
import SwiftUI

/// The chosen direction, with a connected in-memory shelf and standalone Canvas states.
public struct CollectorPreviewGallery: View {
    public init() {}
    public var body: some View { BoxesCollectorPreview() }
}

#Preview("Colecionador · Estante interativa") { CollectorPreviewGallery() }
#Preview("Colecionador · Interior") { NavigationStack { CollectorBoxDetailPreview(received: false) } }
#Preview("Colecionador · Capa e identidade") { CollectorBoxComposerPreview() }
#Preview("Colecionador · Escolha da capa") {
    @Previewable @State var artwork: BoxesArtworkKind = .space
    CollectorCoverPicker(title: "Além do tempo", selection: $artwork)
}
#Preview("Colecionador · Sequência") { CollectorBoxComposerPreview(initialStep: 1) }
#Preview("Colecionador · Revisão") { CollectorBoxComposerPreview(initialStep: 2) }
#Preview("Colecionador · Edição recebida") { NavigationStack { CollectorBoxDetailPreview(received: true) } }
#Preview("Colecionador · Minha adaptação") { CollectorBoxComposerPreview(draft: CollectorEdition.sample.personalized()) }
#Preview("Colecionador · Arte da edição") { CollectorSharePreview(edition: .sample) }
#endif
