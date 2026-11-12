/// Which items of a list may be selected together.
public enum SelectionRule {
    /// The selection to keep after the user changed it from `old` to `new`: `new` itself when it holds a single
    /// item or only groupable ones, otherwise just what was added (its first non-groupable item, or the groupable
    /// ones added to a non-groupable selection). E.g. feeds can be selected together, a folder only alone.
    public static func restrict<Item: Hashable>(old: Set<Item>, new: Set<Item>,
                                                groupable: (Item) -> Bool) -> Set<Item> {
        guard new.count > 1, !new.allSatisfy(groupable) else { return new }
        let added = new.subtracting(old)
        if let item = added.first(where: { !groupable($0) }) { return [item] }
        let addedGroupable = added.filter(groupable)
        return addedGroupable.isEmpty ? new.filter(groupable) : addedGroupable
    }
}
