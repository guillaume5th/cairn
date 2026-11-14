import Foundation
import Security

/// Logins of protected sites, in the macOS keychain, one per host. Generic passwords under Cairn's own service
/// names: an Internet password for the host could match another app's item and prompt for keychain access.
enum Credentials {
    private static func service(_ host: String) -> String { "Cairn — \(host)" }

    @Sendable static func login(for host: String) -> (user: String, password: String)? {
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service(host),
                                      kSecMatchLimit: kSecMatchLimitOne, kSecReturnAttributes: true, kSecReturnData: true]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let found = item as? [CFString: Any],
              let user = found[kSecAttrAccount] as? String, let password = found[kSecValueData] as? Data else { return nil }
        return (user, String(decoding: password, as: UTF8.self))
    }

    static func save(user: String, password: String, for host: String) throws {
        remove(for: host)
        let item: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service(host),
                                     kSecAttrAccount: user, kSecValueData: Data(password.utf8)]
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw NSError(domain: NSOSStatusErrorDomain, code: Int(status)) }
    }

    static func remove(for host: String) {
        SecItemDelete([kSecClass: kSecClassGenericPassword, kSecAttrService: service(host)] as CFDictionary)
    }
}
