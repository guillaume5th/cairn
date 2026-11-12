import CairnCore
import Testing

struct SelectionRuleTests {
    enum Item: Hashable { case feed(Int), folder(Int), all }

    func restrict(_ old: Set<Item>, _ new: Set<Item>) -> Set<Item> {
        SelectionRule.restrict(old: old, new: new) { if case .feed = $0 { true } else { false } }
    }

    @Test func feedsGroupTogether() {
        #expect(restrict([.feed(1)], [.feed(1), .feed(2)]) == [.feed(1), .feed(2)])
        #expect(restrict([.feed(1), .feed(2)], [.feed(1), .feed(2), .feed(3)]) == [.feed(1), .feed(2), .feed(3)])
    }

    @Test func nonGroupableItemReplacesTheSelection() {
        #expect(restrict([.feed(1), .feed(2)], [.feed(1), .feed(2), .folder(1)]) == [.folder(1)])
    }

    @Test func shiftClickAddingSeveralItemsKeepsTheNonGroupableOne() {
        #expect(restrict([.feed(1)], [.feed(1), .feed(2), .folder(1), .feed(3)]) == [.folder(1)])
    }

    @Test func feedAddedToAFolderReplacesIt() {
        #expect(restrict([.folder(1)], [.folder(1), .feed(2)]) == [.feed(2)])
    }

    @Test func singleItemsPassThrough() {
        #expect(restrict([.feed(1)], [.all]) == [.all])
        #expect(restrict([.feed(1), .feed(2)], [.feed(2)]) == [.feed(2)])
        #expect(restrict([.all], []) == [])
    }
}
