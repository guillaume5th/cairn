@testable import CairnCore
import Foundation
import Testing

struct FeedAuthTests {
    private func fetcher(_ login: (user: String, password: String)?) -> FeedFetcher {
        FeedFetcher(session: stubFetcher.session) { host in host == "auth.test" ? login : nil }
    }

    @Test func sendsTheSiteLogin() async throws {
        let parsed = try await fetcher(("user", "pass")).fetch(try #require(URL(string: "https://auth.test/feed")))
        #expect(!parsed.items.isEmpty)
    }

    @Test func missingOrWrongLoginAsksForOne() async throws {
        for login in [nil, ("user", "faux")] as [(user: String, password: String)?] {
            await #expect(throws: CairnError.httpStatus(401)) {
                try await fetcher(login).fetch(try #require(URL(string: "https://auth.test/feed")))
            }
        }
        #expect(CairnError.httpStatus(401).errorDescription == "Ce site demande un identifiant et un mot de passe.")
    }
}
