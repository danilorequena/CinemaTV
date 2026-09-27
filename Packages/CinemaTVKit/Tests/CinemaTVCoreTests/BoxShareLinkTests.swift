import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct BoxShareLinkTests {
    @Test(arguments: [nil, URL(string: "https://share.example/not-an-origin")] as [URL?])
    func missingConfigurationFailsBeforeAccessingICloud(_ origin: URL?) async {
        let service = BoxSharingService(containerIdentifier: "invalid.must.not.be.accessed", baseURL: origin)
        do {
            _ = try await service.publish(BoxEdition(box: BoxDraft()))
            Issue.record("Publishing must fail before accessing CloudKit without a usable origin")
        } catch let error as BoxSharingError {
            guard case .sharingNotConfigured = error else {
                Issue.record("Expected a configuration error, received: \(error)")
                return
            }
        } catch {
            Issue.record("Expected an early configuration error, received: \(error)")
        }
    }
    private let id = UUID(uuidString: "F431CF9D-F81A-4F80-86C1-DAB5AEF62E23")!

    @Test func buildsCanonicalWebAndAppLinks() throws {
        let web = try BoxShareLink.url(for: id, baseURL: URL(string: "https://share.example/")!)
        #expect(web.absoluteString == "https://share.example/boxes/f431cf9d-f81a-4f80-86c1-dab5aef62e23")
        #expect(BoxShareLink.deepLink(for: id).absoluteString == "cinematv://box/f431cf9d-f81a-4f80-86c1-dab5aef62e23")
    }

    @Test(arguments: [
        "cinematv://box/f431cf9d-f81a-4f80-86c1-dab5aef62e23",
        "CINEMATV://BOX/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://share.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "HTTPS://SHARE.EXAMPLE/boxes/f431cf9d-f81a-4f80-86c1-dab5aef62e23"
    ])
    func acceptsKnownRoutesIgnoringHostAndUUIDCase(_ value: String) {
        #expect(BoxShareLink.editionID(from: URL(string: value)!, allowedHost: "share.example") == id)
    }

    @Test(arguments: [
        "https://share.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23?edition=00000000-0000-0000-0000-000000000000#tracking",
        "cinematv://box/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23?edition=00000000-0000-0000-0000-000000000000#tracking"
    ])
    func trackingNeverOverridesEditionInPath(_ value: String) {
        #expect(BoxShareLink.editionID(from: URL(string: value)!, allowedHost: "share.example") == id)
    }

    @Test func webLinksRequireExplicitTrustedHost() {
        let url = URL(string: "https://share.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23")!
        #expect(BoxShareLink.editionID(from: url) == nil)
        #expect(BoxShareLink.editionID(from: url, allowedHost: "SHARE.EXAMPLE") == id)
        #expect(BoxShareLink.editionID(from: url, allowedHost: "") == nil)
    }

    @Test(arguments: [
        "http://share.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "file://share.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://untrusted.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://share.example.untrusted.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://share.example@untrusted.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://user@share.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://share.example:444/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://share.example/BOXES/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://share.example/boxes/not-a-uuid",
        "https://share.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23/extra",
        "https://share.example/boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23/",
        "https://share.example//boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "https://share.example/boxes%2FF431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "cinematv://boxes/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23",
        "cinematv://box/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23/extra",
        "cinematv:///box/F431CF9D-F81A-4F80-86C1-DAB5AEF62E23"
    ])
    func rejectsAmbiguousOrUntrustedRoutes(_ value: String) {
        #expect(BoxShareLink.editionID(from: URL(string: value)!, allowedHost: "share.example") == nil)
    }

    @Test(arguments: [
        "http://share.example", "cinematv://box", "https://user:password@share.example",
        "https://share.example:443", "https://share.example/subpath",
        "https://share.example?source=app", "https://share.example#section"
    ])
    func rejectsUnusableShareOrigins(_ value: String) {
        #expect(throws: (any Error).self) {
            try BoxShareLink.url(for: id, baseURL: URL(string: value)!)
        }
    }
}
