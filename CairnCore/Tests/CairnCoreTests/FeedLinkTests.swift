import CairnCore
import Foundation
import Testing

struct FeedLinkTests {
    @Test(arguments: [
        ("feed:https://exemple.com/rss", "https://exemple.com/rss"),
        ("feed://exemple.com/rss?x=1", "exemple.com/rss?x=1"),
        ("FEED:http://exemple.com/atom", "http://exemple.com/atom"),
    ])
    func address(link: String, expected: String) throws {
        #expect(Library.address(fromFeedLink: try #require(URL(string: link))) == expected)
    }

    @Test func notAFeedLink() throws {
        #expect(Library.address(fromFeedLink: try #require(URL(string: "https://exemple.com/rss"))) == nil)
        #expect(Library.address(fromFeedLink: try #require(URL(string: "feed:"))) == nil)
    }
}
