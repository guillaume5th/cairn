import Foundation

/// The `<link>` tags of an HTML page's head.
// shortcut: regex instead of an HTML parser, so malformed <link> tags or ones added by JavaScript are missed;
// switch to a real parser if common sites fail.
enum HTMLHead {
    struct Link {
        /// Lowercased `rel` tokens.
        var rel: [Substring]
        var type: String?
        /// `href` resolved against the page URL.
        var href: URL
        var title: String?
        var sizes: String?
    }

    /// Links with an `href`, in document order. Only the head is read (the whole page when it has no `</head>`
    /// or when `wholePage` is set: YouTube declares its feed after `</head>`).
    static func links(in html: String, baseURL: URL, wholePage: Bool = false) -> [Link] {
        let head = wholePage ? html : html.firstRange(of: /<\/head\s*>/.ignoresCase()).map { String(html[..<$0.lowerBound]) } ?? html
        return head.matches(of: /<link\b[^>]*>/.ignoresCase()).compactMap { match in
            let tag = String(match.output)
            guard let href = attribute("href", in: tag),
                  let url = URL(string: decode(href), relativeTo: baseURL)?.absoluteURL else { return nil }
            return Link(rel: attribute("rel", in: tag)?.lowercased().split(whereSeparator: \.isWhitespace) ?? [],
                        type: attribute("type", in: tag)?.lowercased(), href: url,
                        title: attribute("title", in: tag).map(decode), sizes: attribute("sizes", in: tag))
        }
    }

    private static func attribute(_ name: String, in tag: String) -> String? {
        // name="…", name='…' or name=… (unquoted)
        let pattern = try! Regex<(Substring, Substring?, Substring?, Substring?)>(
            #"\b\#(name)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^"'>\s]+))"#
        ).ignoresCase()
        guard let m = tag.firstMatch(of: pattern), let value = m.output.1 ?? m.output.2 ?? m.output.3 else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Numeric entities and the named ones found in titles (`&raquo;`, `&#8211;`…); unknown ones are left as is.
    static func decode(_ value: String) -> String {
        value.replacing(/&(#[xX]?[0-9a-fA-F]+|[a-zA-Z]+);/) { match in
            let name = match.output.1
            if name.hasPrefix("#") {
                let hex = name.dropFirst().first.map { $0 == "x" || $0 == "X" } ?? false
                let digits = name.dropFirst(hex ? 2 : 1)
                if let code = UInt32(digits, radix: hex ? 16 : 10), let scalar = Unicode.Scalar(code) { return String(scalar) }
            } else if let char = namedEntities[String(name)] {
                return char
            }
            return String(match.output.0)
        }
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "quot": "\"", "apos": "'", "lt": "<", "gt": ">", "nbsp": "\u{A0}",
        "laquo": "«", "raquo": "»", "lsquo": "‘", "rsquo": "’", "ldquo": "“", "rdquo": "”",
        "ndash": "–", "mdash": "—", "hellip": "…", "middot": "·", "bull": "•",
        "eacute": "é", "egrave": "è", "ecirc": "ê", "agrave": "à", "acirc": "â", "ccedil": "ç", "ocirc": "ô", "ucirc": "û", "icirc": "î",
    ]
}
