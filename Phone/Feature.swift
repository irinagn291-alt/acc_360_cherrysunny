import SwiftUI
import UIKit

struct FeatureRoot: View {
    @State private var portions: [Portion] = []
    @State private var selected = Daybook.calendar.startOfDay(for: .now)
    @State private var knownToday = Daybook.calendar.startOfDay(for: .now)
    @State private var weekly = false
    @State private var didLoad = false
    @State private var storageIssue: String?
    @State private var catalog = false
    @State private var pendingDraft: Portion?
    @State private var editor: Portion?
    @State private var calendarSheet = false
    @State private var pageID = UUID()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize

    init() {
        #if DEBUG && targetEnvironment(simulator)
        if let screen = ScreenshotLaunch.screen {
            _portions = State(initialValue: ScreenshotLaunch.entries(for: screen))
            _didLoad = State(initialValue: true)
            if screen == .week {
                _selected = State(initialValue: ScreenshotLaunch.previousMonday)
                _weekly = State(initialValue: true)
            }
            if screen == .catalog || screen == .scanner {
                _catalog = State(initialValue: true)
            }
            if screen == .editor, let product = ScreenshotLaunch.product("5010029000016") {
                _editor = State(initialValue: Portion(product: product, amount: 50, meal: .breakfast,
                                                       date: Daybook.calendar.startOfDay(for: .now)))
            }
        }
        #endif
    }

    private var dayEntries: [Portion] { Daybook.entries(portions, on: selected) }
    private var frequent: [OFFProduct] {
        var seen = Set<String>()
        return portions.sorted { $0.created > $1.created }.compactMap {
            seen.insert($0.product.id).inserted ? $0.product : nil
        }.prefix(6).map { $0 }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    masthead.id("top")
                    sectionPicker
                    dateSelector
                    if weekly {
                        DiaryWeek(all: portions, selected: selected) { date in
                            selected = date; weekly = false; pageID = UUID()
                        }
                    } else {
                        dayContent
                    }
                }
                .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 28)
                .frame(maxWidth: 660, alignment: .leading).frame(maxWidth: .infinity)
            }
            .onChange(of: pageID) { _, _ in proxy.scrollTo("top", anchor: .top) }
        }
        .foregroundStyle(Paper.ink)
        .background(Paper.base.ignoresSafeArea())
        .preferredColorScheme(.dark).tint(Paper.mint)
        .environment(\.locale, Daybook.locale)
        .onAppear { if !didLoad { load() } }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { advanceToday() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in advanceToday() }
        .onOpenURL { url in
            if url.scheme == "portionnote" && url.host == "dashboard" {
                catalog = false; pendingDraft = nil; editor = nil; calendarSheet = false
                selected = Daybook.calendar.startOfDay(for: .now); weekly = false; pageID = UUID()
            }
        }
        .sheet(isPresented: $catalog, onDismiss: {
            if let pendingDraft { editor = pendingDraft; self.pendingDraft = nil }
        }) {
            CatalogPicker { product in pendingDraft = newPortion(product) }
        }
        .sheet(item: $editor) { portion in
            PortionEditor(original: portion, existing: portions.contains { $0.id == portion.id },
                          onSave: { candidate in
                let updated = Daybook.upserting(candidate, in: portions)
                guard persist(updated) else { return false }
                selected = Daybook.calendar.startOfDay(for: candidate.date); weekly = false
                return true
            }, onDelete: { persist(portions.filter { $0.id != portion.id }) })
        }
        .sheet(isPresented: $calendarSheet) {
            NavigationStack {
                DatePicker("Choose date", selection: $selected, in: ...Date.now, displayedComponents: .date)
                    .datePickerStyle(.graphical).padding()
                    .navigationTitle("Journal date").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { calendarSheet = false } } }
                    .frame(maxHeight: .infinity, alignment: .top)
                    .background(Paper.base).journalSheet()
            }
            .environment(\.locale, Daybook.locale).presentationDetents([.medium, .large])
        }
        .alert("Journal unavailable", isPresented: Binding(get: { storageIssue != nil }, set: { if !$0 { storageIssue = nil } })) {
            Button("Close") { }
        } message: { Text(storageIssue ?? "") }
    }

    private var masthead: some View {
        HStack(spacing: 12) {
            FoodMark()
            VStack(alignment: .leading, spacing: 3) {
                Text(Brand.name).font(Paper.rounded(.title2)).lineLimit(1).minimumScaleFactor(0.65)
                if !typeSize.isAccessibilitySize {
                    Text("A little note for every meal").font(.caption).foregroundStyle(Paper.muted)
                }
            }
            Spacer()
        }.accessibilityElement(children: .combine)
    }

    private var sectionPicker: some View {
        HStack(spacing: 4) {
            sectionButton("Day", "book.pages", isWeek: false)
            sectionButton("Week", "chart.bar.xaxis", isWeek: true)
        }
        .padding(5).surfaceCard(radius: 19)
    }

    private func sectionButton(_ name: String, _ symbol: String, isWeek: Bool) -> some View {
        Button {
            weekly = isWeek
        } label: {
            HStack(spacing: 8) {
                if !typeSize.isAccessibilitySize { Image(systemName: symbol) }
                Text(name)
            }.font(Paper.rounded(.subheadline))
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .foregroundStyle(weekly == isWeek ? Paper.base : Paper.muted)
                .background(weekly == isWeek ? Paper.violet : .clear, in: RoundedRectangle(cornerRadius: 14))
        }.buttonStyle(.plain).accessibilityAddTraits(weekly == isWeek ? .isSelected : [])
            .accessibilityIdentifier(isWeek ? "journal.week" : "journal.day")
    }

    private var dateSelector: some View {
        let days = Daybook.week(containing: selected)
        let dateText = weekly
            ? "\(Daybook.label(days.first ?? selected, template: "dMMM")) — \(Daybook.label(days.last ?? selected, template: "dMMM"))"
            : Daybook.label(selected, template: "dMMMM")
        let atEnd = weekly ? days.contains { Daybook.calendar.isDateInToday($0) } : Daybook.calendar.isDateInToday(selected)
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(spacing: 6))
        return layout {
            VStack(alignment: .leading, spacing: 4) {
                MarginLabel(weekly ? "Week in review" : Daybook.label(selected, template: "EEEE"))
                    .foregroundStyle(Paper.muted)
                Button {
                    calendarSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text(dateText).font(Paper.rounded(.title2))
                        Image(systemName: "chevron.down").font(.caption.weight(.bold))
                    }.multilineTextAlignment(.leading)
                }.buttonStyle(.plain).accessibilityHint("Open the calendar").accessibilityLabel(Daybook.label(selected, template: "EEEEdMMMMyyyy"))
                    .accessibilityIdentifier("journal.calendar")
            }
            if !typeSize.isAccessibilitySize { Spacer(minLength: 2) }
            HStack(spacing: 8) {
                arrow("chevron.left", weekly ? "Previous week" : "Previous day") { shift(-1) }
                arrow("chevron.right", weekly ? "Next week" : "Next day") { shift(1) }
                    .disabled(atEnd).opacity(atEnd ? 0.32 : 1)
            }
        }
    }

    private func arrow(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 16, weight: .bold)).frame(width: 44, height: 44)
                .surfaceCard(radius: 15)
        }.buttonStyle(.plain).accessibilityLabel(label)
    }

    @ViewBuilder private var dayContent: some View {
        let entries = dayEntries
        let energy = NutrientTotal(.energy, entries)
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    MarginLabel(entries.isEmpty ? "Your daily food journal" : "Daily energy").foregroundStyle(.white.opacity(0.8))
                    if entries.isEmpty {
                        Text("What’s on\nyour plate?").font(Paper.rounded(.largeTitle))
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(energy.formatted()).font(.system(.largeTitle, design: .rounded, weight: .heavy)).monospacedDigit()
                        Text("kcal logged").font(.subheadline)
                    }
                }
                Spacer(minLength: 0)
                if !typeSize.isAccessibilitySize {
                    DishPrint().frame(width: 120, height: 128)
                }
            }
            if entries.isEmpty {
                Text("Pick a food and enter your portion to start the day’s journal.")
                    .font(.subheadline).fixedSize(horizontal: false, vertical: true)
            } else {
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: 6))
                layout {
                    ForEach([Nutrient.protein, .carbs, .fat]) { nutrient in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(nutrient.label).font(.caption.weight(.medium)).foregroundStyle(.white.opacity(0.8))
                            Text("\(NutrientTotal(nutrient, entries).formatted(digits: 1)) g")
                                .font(Paper.rounded(.subheadline)).monospacedDigit()
                                .foregroundStyle(nutrient == .protein ? Paper.mint : nutrient == .carbs ? Paper.apricot : Paper.rose)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(10)
                            .background(.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                if Nutrient.allCases.contains(where: { NutrientTotal($0, entries).known < entries.count }) {
                    Text("— no label data · ≥ partial total").font(.caption)
                }
            }
            Button { catalog = true } label: {
                Label(entries.isEmpty && !typeSize.isAccessibilitySize ? "Log your first portion" : "Add a portion", systemImage: "plus")
            }.buttonStyle(PrintButton()).disabled(!didLoad).accessibilityIdentifier("journal.add")
        }
        .padding(20).foregroundStyle(.white)
        .background(Paper.hero, in: RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).strokeBorder(.white.opacity(0.18)))
        .shadow(color: Paper.violet.opacity(0.12), radius: 20, y: 8)
        if !frequent.isEmpty {
            VStack(alignment: .leading, spacing: 9) {
                MarginLabel("Log it again").foregroundStyle(Paper.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(frequent) { product in
                            Button { editor = newPortion(product) } label: {
                                Label(product.name, systemImage: "arrow.clockwise")
                                    .font(.subheadline.weight(.medium)).padding(.horizontal, 12).padding(.vertical, 10)
                                    .surfaceCard(radius: 16)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Meal entries").font(Paper.rounded(.title2))
                Spacer()
                Text("\(entries.count)").font(.caption.monospacedDigit().bold()).padding(8)
                    .background(Paper.surface, in: Circle())
            }
            ForEach(MealSlot.allCases) { meal in
                let records = entries.filter { $0.meal == meal }
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: meal.icon).font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Paper.color(for: meal)).frame(width: 44, height: 44)
                            .background(Paper.color(for: meal).opacity(0.12), in: RoundedRectangle(cornerRadius: 15))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.label).font(Paper.rounded(.headline))
                            Text(records.isEmpty ? "No portions yet" : "\(records.count) \(records.count == 1 ? "portion" : "portions")")
                                .foregroundStyle(Paper.muted).font(.caption)
                        }
                        Spacer(minLength: 4)
                        if !records.isEmpty {
                            Text("\(NutrientTotal(.energy, records).formatted()) kcal")
                                .font(Paper.rounded(.caption)).foregroundStyle(Paper.color(for: meal))
                        }
                    }
                    ForEach(records) { portion in
                        PaperRule()
                        Button { editor = portion } label: {
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(portion.product.name).font(.body.weight(.medium))
                                    Text("\(Daybook.number(portion.amount)) \(portion.product.amountUnit)")
                                        .font(.caption).foregroundStyle(Paper.muted)
                                }
                                Spacer()
                                Image(systemName: "pencil").font(.caption).foregroundStyle(Paper.violet)
                            }.padding(.vertical, 6).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityHint("Edit or delete this portion")
                            .accessibilityIdentifier("journal.entry." + portion.product.id)
                    }
                }.padding(15).surfaceCard()
            }
        }
        if !entries.isEmpty { NutritionLedger(entries: entries, title: "Daily nutrition") }
    }

    private func shift(_ direction: Int) {
        let days = weekly ? 7 : 1
        if let next = Daybook.calendar.date(byAdding: .day, value: days * direction, to: selected) {
            selected = min(next, Daybook.calendar.startOfDay(for: .now))
        }
    }

    private func newPortion(_ product: OFFProduct) -> Portion {
        Portion(product: product, amount: 100, meal: .current, date: selected)
    }

    private func load() {
        do {
            portions = try Daybook.load(); didLoad = true; publish()
        } catch {
            storageIssue = "Your journal could not be read. Close and reopen the app to try again."
        }
    }

    private func persist(_ updated: [Portion]) -> Bool {
        guard didLoad else { return false }
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.screen != nil { portions = updated; return true }
        #endif
        do {
            try Daybook.save(updated); portions = updated; publish(); return true
        } catch { return false }
    }

    private func advanceToday() {
        let today = Daybook.calendar.startOfDay(for: .now)
        if Daybook.calendar.isDate(selected, inSameDayAs: knownToday) { selected = today }
        knownToday = today
        if didLoad { publish() }
    }

    private func publish() {
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.screen != nil { return }
        #endif
        let today = Daybook.entries(portions, on: .now)
        let energy = NutrientTotal(.energy, today)
        let detail = today.isEmpty ? "Log a portion on iPhone" : [Nutrient.protein, .fat, .carbs].map {
            "\($0.label.prefix(1)) \(NutrientTotal($0, today).formatted(digits: 1)) g"
        }.joined(separator: " · ")
        CompanionHub.shared.publish(
            title: "Journal · " + Daybook.label(.now, template: "dMMMM"),
            value: today.isEmpty ? "No entries" : (energy.known == 0 ? "No energy data" : "\(energy.formatted()) kcal"),
            detail: detail,
            items: today.prefix(8).map {
                CompanionItem(id: $0.id.uuidString, title: $0.product.name,
                              detail: "\($0.meal.label) · \(Daybook.number($0.amount)) \($0.product.amountUnit)")
            }
        )
    }
}
