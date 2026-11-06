import SwiftUI

struct NutritionLedger: View {
    let entries: [Portion]
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text(title).font(Paper.rounded(.title2))
                Spacer()
                Image(systemName: "leaf.fill").foregroundStyle(Paper.mint).accessibilityHidden(true)
            }
            ForEach(Nutrient.allCases) { nutrient in
                let total = NutrientTotal(nutrient, entries)
                PaperRule()
                HStack {
                    Text(nutrient.label).foregroundStyle(Paper.muted)
                    Spacer()
                    Text(total.formatted(digits: nutrient == .energy ? 0 : 1) + " " + nutrient.unit)
                        .font(Paper.rounded(.body, weight: .semibold)).monospacedDigit()
                        .foregroundStyle(nutrient == .energy ? Paper.mint : Paper.ink)
                }
            }
            if Nutrient.allCases.contains(where: { NutrientTotal($0, entries).known < entries.count }) {
                Text("≥ marks a partial total. A dash means the nutrient is missing from every label.")
                    .font(.caption).foregroundStyle(Paper.muted)
            }
        }.padding(20).surfaceCard()
    }
}

struct DiaryWeek: View {
    let all: [Portion]
    let selected: Date
    let pick: (Date) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    private struct Day: Identifiable {
        let date: Date
        let entries: [Portion]
        var id: Date { date }
        var energy: NutrientTotal { NutrientTotal(.energy, entries) }
    }

    var body: some View {
        let days = Daybook.week(containing: selected).map { Day(date: $0, entries: Daybook.entries(all, on: $0)) }
        let peak = max(days.map { $0.energy.value }.max() ?? 0, 1)
        let entries = days.flatMap(\.entries)
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    MarginLabel("Energy · seven days").foregroundStyle(.white.opacity(0.75))
                    Text("Your week\nin food").font(Paper.rounded(.largeTitle))
                }
                Spacer()
                Image(systemName: "chart.bar.xaxis").font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(Paper.mint).padding(14)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
                    .accessibilityHidden(true)
            }
            HStack(alignment: .bottom, spacing: 9) {
                ForEach(days) { day in
                    let isSelected = Daybook.calendar.isDate(day.date, inSameDayAs: selected)
                    Button { pick(day.date) } label: {
                        VStack(spacing: 9) {
                            VStack {
                                Spacer(minLength: 0)
                                if day.energy.known > 0 {
                                    RoundedRectangle(cornerRadius: 8).fill(isSelected ? Paper.mint.gradient : Paper.violet.gradient)
                                        .frame(height: max(4, CGFloat(day.energy.value / peak) * 112))
                                } else if !day.entries.isEmpty {
                                    Image(systemName: "questionmark").font(.caption2).foregroundStyle(Paper.mint)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 112)
                            .background(.black.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
                            Text(Daybook.label(day.date, template: "EEEEE"))
                                .font(Paper.rounded(.caption)).foregroundStyle(isSelected ? Paper.mint : .white.opacity(0.7))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(day.date > .now).opacity(day.date > .now ? 0.4 : 1)
                    .accessibilityLabel(Daybook.label(day.date, template: "EEEEdMMMM") + ", " +
                        (day.entries.isEmpty ? "no portions logged" : "\(day.energy.formatted()) kcal"))
                    .accessibilityHint("Open this day")
                }
            }
            Text(entries.isEmpty ? "No entries this week. Choose a day to log a portion." :
                    "Energy from available labels. Tap a column to see the day.")
                .font(.caption).foregroundStyle(.white.opacity(0.8))
        }.padding(22).foregroundStyle(.white)
            .background(Paper.hero, in: RoundedRectangle(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(.white.opacity(0.15)))

        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 12))
        layout {
            metric("Days logged", "\(days.filter { !$0.entries.isEmpty }.count) / 7", "calendar", Paper.mint)
            metric("Portions this week", "\(entries.count)", "fork.knife", Paper.apricot)
        }

        if !entries.isEmpty {
            NutritionLedger(entries: entries, title: "Weekly nutrition")
            VStack(alignment: .leading, spacing: 13) {
                Text("Daily entries").font(Paper.rounded(.title2))
                ForEach(days.filter { !$0.entries.isEmpty }) { day in
                    PaperRule()
                    Button { pick(day.date) } label: {
                        HStack {
                            Text(Daybook.label(day.date, template: "EEE dMMM"))
                            Spacer()
                            Text("\(day.energy.formatted()) kcal").font(.subheadline.monospacedDigit()).foregroundStyle(Paper.mint)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Paper.muted)
                        }.padding(.vertical, 8)
                    }.buttonStyle(.plain)
                }
            }.padding(20).surfaceCard()
        }
    }

    private func metric(_ text: String, _ value: String, _ symbol: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).font(.headline).foregroundStyle(color).accessibilityHidden(true)
            Text(value).font(Paper.rounded(.title)).monospacedDigit()
            Text(text).font(.caption).foregroundStyle(Paper.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18).surfaceCard()
    }
}
