import SwiftUI

// MARK: - Color from hex

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB,
                  red:     Double(r)/255,
                  green:   Double(g)/255,
                  blue:    Double(b)/255,
                  opacity: Double(a)/255)
    }
}

// MARK: - Theme

enum Theme {

    // Backgrounds – warm off-white like Claude's UI
    static let background   = Color(hex: "F7F6F3")
    static let sidebarBg    = Color(hex: "EFEDE8")
    static let cardBg       = Color.white
    static let inputBg      = Color(hex: "F0EDE8")
    static let divider      = Color(hex: "E5E2DC")

    // Text
    static let textPrimary   = Color(hex: "1A1A1A")
    static let textSecondary = Color(hex: "6B6B6B")
    static let textTertiary  = Color(hex: "9B9B9B")

    // Accent – Claude amber
    static let accent      = Color(hex: "D97706")
    static let accentLight = Color(hex: "FEF3C7")

    // Status
    static let success = Color(hex: "059669")
    static let warning = Color(hex: "D97706")
    static let danger  = Color(hex: "DC2626")

    // Sticky notes
    static let stickyYellow = Color(hex: "FEF08A")
    static let stickyPink   = Color(hex: "FBCFE8")
    static let stickyBlue   = Color(hex: "BAE6FD")
    static let stickyGreen  = Color(hex: "BBF7D0")
    static let stickyPurple = Color(hex: "E9D5FF")

    // Typography — Chinese: Songti SC (宋体简), English: Times New Roman
    static let titleFont    = Font.custom("Songti SC", size: 24).weight(.semibold)
    static let headlineFont = Font.custom("Songti SC", size: 16).weight(.semibold)
    static let bodyFont     = Font.custom("Songti SC", size: 14)
    static let captionFont  = Font.custom("Songti SC", size: 12)
    static let smallFont    = Font.custom("Songti SC", size: 11).weight(.medium)

    // English-specific typography (course codes, professor names, etc.)
    static let englishBodyFont    = Font.custom("Times New Roman", size: 14)
    static let englishHeadFont    = Font.custom("Times New Roman", size: 16)

    // Layout
    static let cornerRadius: CGFloat = 12
    static let cardPadding:  CGFloat = 16
    static let sectionSpacing: CGFloat = 24

    // Sticky color helper
    static func stickyColor(_ name: StickyNote.StickyColor) -> Color {
        switch name {
        case .yellow: return stickyYellow
        case .pink:   return stickyPink
        case .blue:   return stickyBlue
        case .green:  return stickyGreen
        case .purple: return stickyPurple
        }
    }

    // Urgency color for due dates
    static func urgencyColor(daysUntil: Int) -> Color {
        if daysUntil < 0  { return danger }
        if daysUntil <= 1 { return danger }
        if daysUntil <= 3 { return warning }
        return success
    }
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.cardBg)
            .cornerRadius(Theme.cornerRadius)
            .shadow(color: .black.opacity(0.055), radius: 8, x: 0, y: 2)
    }
}

struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.captionFont)
            .fontWeight(.semibold)
            .foregroundColor(Theme.textTertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
    func sectionHeader() -> some View { modifier(SectionHeaderStyle()) }
}
