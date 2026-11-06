import SwiftUI

enum Paper {
    static let base = Color(red: 0.082, green: 0.063, blue: 0.137)
    static let surface = Color(red: 0.158, green: 0.123, blue: 0.242)
    static let raised = Color(red: 0.223, green: 0.175, blue: 0.324)
    static let ink = Color(red: 0.976, green: 0.957, blue: 1)
    static let muted = Color(red: 0.741, green: 0.690, blue: 0.820)
    static let rule = Color(red: 0.302, green: 0.243, blue: 0.408)
    static let violet = Color(red: 0.695, green: 0.572, blue: 1)
    static let apricot = Color(red: 1, green: 0.733, blue: 0.541)
    static let mint = Color(red: 0.686, green: 0.949, blue: 0.796)
    static let rose = Color(red: 1, green: 0.639, blue: 0.761)
    static let hero = LinearGradient(colors: [Color(red: 0.46, green: 0.29, blue: 0.76),
                                               Color(red: 0.30, green: 0.18, blue: 0.51)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing)

    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static func color(for meal: MealSlot) -> Color {
        switch meal {
        case .breakfast: apricot
        case .lunch: mint
        case .dinner: violet
        case .snack: rose
        }
    }
}

struct MarginLabel: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased()).font(.system(.caption2, design: .rounded, weight: .bold)).tracking(1.5)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
}

struct PrintButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(Paper.rounded(.headline))
            .padding(.horizontal, 20).frame(maxWidth: .infinity).padding(.vertical, 16)
            .foregroundStyle(Paper.base)
            .background(LinearGradient(colors: [Color(red: 0.79, green: 1, blue: 0.87), Paper.mint],
                                       startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 19))
            .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(.white.opacity(0.3)))
            .shadow(color: Paper.mint.opacity(configuration.isPressed ? 0 : 0.16), radius: 14, y: 5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

struct SurfaceCard: ViewModifier {
    var color: Color = Paper.surface
    var radius: CGFloat = 24
    func body(content: Content) -> some View {
        content.background(color, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(
                LinearGradient(colors: [.white.opacity(0.12), .white.opacity(0.025)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
    }
}

extension View {
    func surfaceCard(_ color: Color = Paper.surface, radius: CGFloat = 24) -> some View {
        modifier(SurfaceCard(color: color, radius: radius))
    }

    func journalSheet() -> some View {
        self.foregroundStyle(Paper.ink).tint(Paper.mint).preferredColorScheme(.dark)
            .toolbarBackground(Paper.base, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct FoodMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16).fill(Paper.mint.gradient)
            Image(systemName: "fork.knife").font(.system(size: 21, weight: .bold)).foregroundStyle(Paper.base)
        }.frame(width: 48, height: 48).accessibilityHidden(true)
    }
}

/// A small food illustration, drawn as vectors so it stays crisp at every size.
struct DishPrint: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 160, size.height / 160)
            context.translateBy(x: (size.width - 160 * scale) / 2, y: (size.height - 160 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            func ellipse(_ rect: CGRect, _ colors: [Color]) {
                context.fill(Path(ellipseIn: rect), with: .linearGradient(
                    Gradient(colors: colors), startPoint: rect.origin,
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
            }
            ellipse(CGRect(x: 16, y: 24, width: 136, height: 133), [.black.opacity(0.18), .black.opacity(0.05)])
            ellipse(CGRect(x: 9, y: 10, width: 140, height: 140), [.white, Color(red: 0.79, green: 0.75, blue: 0.93)])
            ellipse(CGRect(x: 21, y: 22, width: 116, height: 116), [Color(red: 0.67, green: 0.62, blue: 0.82), .white])
            ellipse(CGRect(x: 26, y: 27, width: 106, height: 106), [Color(red: 0.94, green: 0.92, blue: 1), .white])
            // Greens occupy one side of the plate; grains and vegetables the other.
            for (x, y, angle) in [(47.0, 53.0, -24.0), (62.0, 44.0, 30.0), (45.0, 76.0, -60.0), (66.0, 68.0, 12.0), (57.0, 94.0, 47.0)] {
                var leaf = context
                leaf.translateBy(x: x, y: y); leaf.rotate(by: .degrees(angle))
                var shape = Path()
                shape.move(to: CGPoint(x: 0, y: -22))
                shape.addQuadCurve(to: CGPoint(x: 0, y: 22), control: CGPoint(x: 29, y: 0))
                shape.addQuadCurve(to: CGPoint(x: 0, y: -22), control: CGPoint(x: -25, y: 0))
                leaf.fill(shape, with: .linearGradient(Gradient(colors: [Paper.mint, Color(red: 0.19, green: 0.60, blue: 0.40)]), startPoint: .init(x: -10, y: -20), endPoint: .init(x: 10, y: 22)))
                var vein = Path(); vein.move(to: .init(x: 0, y: -14)); vein.addLine(to: .init(x: 0, y: 15))
                leaf.stroke(vein, with: .color(.white.opacity(0.4)), lineWidth: 1.4)
            }
            for row in 0..<5 {
                for column in 0..<4 {
                    let x = 82 + CGFloat(column) * 8 + CGFloat(row % 2) * 3
                    let y = 44 + CGFloat(row) * 8
                    ellipse(CGRect(x: x, y: y, width: 9, height: 6), [Color(red: 1, green: 0.88, blue: 0.57), Paper.apricot])
                }
            }
            for (x, y) in [(87.0, 91.0), (107.0, 92.0), (97.0, 110.0)] {
                ellipse(CGRect(x: x - 10, y: y - 10, width: 22, height: 22), [Color(red: 1, green: 0.55, blue: 0.42), Color(red: 0.87, green: 0.27, blue: 0.29)])
                ellipse(CGRect(x: x - 5, y: y - 7, width: 6, height: 3), [.white.opacity(0.7), .white.opacity(0.15)])
            }
        }.rotationEffect(.degrees(-10)).accessibilityHidden(true)
    }
}

struct PaperRule: View {
    var body: some View { Rectangle().fill(Paper.rule.opacity(0.65)).frame(height: 1).accessibilityHidden(true) }
}
