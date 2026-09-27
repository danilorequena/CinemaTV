import Foundation

/// A stable route to one published, immutable edition of a box.
public struct BoxShareLink: Sendable {
    public enum LinkError: Error, LocalizedError, Sendable {
        case invalidBaseURL

        public var errorDescription: String? {
            String(localized: "The box sharing address has not been configured yet.", bundle: .module)
        }
    }

    /// The base URL must be an HTTPS origin associated with the app.
    public static func url(for editionID: UUID, baseURL: URL) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.port == nil, components.query == nil, components.fragment == nil,
              components.percentEncodedPath.isEmpty || components.percentEncodedPath == "/"
        else { throw LinkError.invalidBaseURL }
        components.scheme = "https"
        components.host = host.lowercased()
        components.path = "/boxes/\(editionID.uuidString.lowercased())"
        guard let result = components.url else { throw LinkError.invalidBaseURL }
        return result
    }

    /// Tracking query items and fragments never override the edition in the path.
    public static func editionID(from url: URL, allowedHost: String? = nil) -> UUID? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.user == nil, components.password == nil, components.port == nil,
              let scheme = components.scheme?.lowercased(),
              let host = components.host?.lowercased() else { return nil }
        let prefix: String
        switch scheme {
        case "cinematv":
            guard host == "box" else { return nil }
            prefix = "/"
        case "https":
            guard let allowedHost, !allowedHost.isEmpty,
                  host == allowedHost.lowercased() else { return nil }
            prefix = "/boxes/"
        default:
            return nil
        }
        // Compare the encoded path so encoded slashes cannot create another route.
        let path = components.percentEncodedPath
        guard path.hasPrefix(prefix) else { return nil }
        let component = String(path.dropFirst(prefix.count))
        guard component.count == 36,
              !component.contains("/"), !component.contains("%"),
              let id = UUID(uuidString: component),
              id.uuidString.lowercased() == component.lowercased() else { return nil }
        return id
    }

    public static func deepLink(for id: UUID) -> URL {
        // UUID's canonical representation contains only URL-safe characters.
        URL(string: "cinematv://box/\(id.uuidString.lowercased())")!
    }
}
