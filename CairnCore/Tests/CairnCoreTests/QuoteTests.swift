@testable import CairnCore
import Testing

struct QuoteTests {
    @Test func appendsQuoteAfterBlankLine() {
        #expect(Library.appendQuote("  Le cache expire après 5 minutes\n", to: "À relire")
                == "À relire\n\n> Le cache expire après 5 minutes")
        #expect(Library.appendQuote("Premier", to: "") == "> Premier")
        #expect(Library.appendQuote("Deux", to: "  Note\n\n") == "  Note\n\n> Deux")
    }

    @Test func quotesEveryLine() {
        #expect(Library.appendQuote("Un.\n\nDeux.", to: "") == "> Un.\n> \n> Deux.")
    }

    @Test func blankPassageLeavesNote() {
        #expect(Library.appendQuote(" \n ", to: "À relire") == "À relire")
    }
}
