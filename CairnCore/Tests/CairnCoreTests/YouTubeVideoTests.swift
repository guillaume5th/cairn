@testable import CairnCore
import Testing

struct YouTubeVideoTests {
    @Test(arguments: [
        "https://www.youtube.com/watch?v=nHz3mJpo9BE",
        "https://youtube.com/watch?v=nHz3mJpo9BE",
        "https://m.youtube.com/watch?v=nHz3mJpo9BE",
        "https://www.youtube.com/watch?feature=share&v=nHz3mJpo9BE&t=42",
        "https://youtu.be/nHz3mJpo9BE",
        "https://youtu.be/nHz3mJpo9BE?t=42",
    ])
    func videoLinks(_ link: String) {
        #expect(Library.youtubeVideoID(in: link) == "nHz3mJpo9BE")
    }

    @Test(arguments: [
        "https://www.youtube.com/channel/UCJe020zaO_mWLy1X2Myp-7Q",
        "https://www.youtube.com/@NicolasMartignole",
        "https://www.youtube.com/playlist?list=PLabcdefghij",
        "https://www.youtube.com/shorts/nHz3mJpo9BE",
        "https://www.youtube.com/watch",
        "https://www.youtube.com/watch?v=court",
        "https://www.youtube.com/watch?v=nHz3mJpo9BE%22%3E%3Cx",
        "https://evil.example/watch?v=nHz3mJpo9BE",
        "https://youtu.be/",
        "ftp://youtu.be/nHz3mJpo9BE",
        "pas une url",
        "",
    ])
    func otherLinks(_ link: String) {
        #expect(Library.youtubeVideoID(in: link) == nil)
    }
}
