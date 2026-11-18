@testable import CairnCore
import Testing

struct QuickLookImagesTests {
    @Test func keepsHTTPSAndImageDataInOrderWithSafeNames() {
        let images = Library.quickLookImages([
            "https://x.test/a/photo.PNG?size=2",
            "https://x.test/graph",
            "data:image/jpeg;base64,AAAA",
            "data:image/svg+xml;utf8,<svg/>",
        ])

        #expect(images.map(\.fileName) == ["01.png", "02", "03.jpg", "04.svg"])
        #expect(images[0].url.absoluteString == "https://x.test/a/photo.PNG?size=2")
        #expect(images[1].fileExtension == nil)
    }

    @Test func leavesOutWhatTheFeedMustNotMakeUsFetch() {
        let images = Library.quickLookImages([
            "http://x.test/a.png", "file:///etc/passwd", "javascript:alert(1)", "ftp://x.test/a.png",
            "data:text/html;base64,AAAA", "https://x.test/../../evil.png", "pas une url", "",
        ])

        // Only the path-traversal looking address is a valid https image, and its file name is still `01.png`.
        #expect(images.map(\.fileName) == ["01.png"])
    }

    @Test func unknownExtensionsAreNotCopiedFromTheAddress() {
        let images = Library.quickLookImages(["https://x.test/a.dmg", "https://x.test/b.exe"])
        #expect(images.map(\.fileName) == ["01", "02"])
    }

    @Test func removesDuplicatesAndStopsAtTheLimit() {
        let same = Library.quickLookImages(["https://x.test/a.png", "https://x.test/a.png", "https://x.test/b.png"])
        #expect(same.map(\.fileName) == ["01.png", "02.png"])

        let many = Library.quickLookImages((0..<80).map { "https://x.test/\($0).png" })
        #expect(many.count == 50)
        #expect(many.last?.fileName == "50.png")
        #expect(Library.quickLookImages((0..<10).map { "https://x.test/\($0).png" }, limit: 3).count == 3)
    }
}
