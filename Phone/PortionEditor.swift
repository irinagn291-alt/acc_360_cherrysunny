import SwiftUI

struct PortionEditor: View {
    let original: Portion
    let existing: Bool
    let onSave: (Portion) -> Bool
    let onDelete: () -> Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var amount: String
    @State private var meal: MealSlot
    @State private var date: Date
    @State private var confirmDelete = false
    @State private var failed = false
    @FocusState private var typing: Bool

    init(original: Portion, existing: Bool, onSave: @escaping (Portion) -> Bool, onDelete: @escaping () -> Bool) {
        self.original = original; self.existing = existing
        self.onSave = onSave; self.onDelete = onDelete
        _amount = State(initialValue: original.amount.formatted(.number.locale(Daybook.locale).grouping(.never).precision(.fractionLength(0...1))))
        _meal = State(initialValue: original.meal)
        _date = State(initialValue: original.date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 7) {
                        Label("FOOD LABEL", systemImage: "leaf.fill").font(Paper.rounded(.caption)).foregroundStyle(Paper.mint)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        Text(original.product.name).font(Paper.rounded(.title, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                        if !original.product.brand.isEmpty {
                            Text(original.product.brand).font(.subheadline).foregroundStyle(Paper.muted)
                        }
                        if let source = original.product.sourceURL {
                            Link(destination: source) { Label("View food label", systemImage: "arrow.up.right") }
                                .font(.subheadline)
                        }
                    }
                    PaperRule()
                    Text("Portion size").font(.headline)
                    HStack(alignment: .firstTextBaseline) {
                        TextField("100", text: $amount).keyboardType(.decimalPad).focused($typing)
                            .font(Paper.rounded(.largeTitle, weight: .bold)).accessibilityLabel("Portion size in \(original.product.amountUnit == "ml" ? "milliliters" : "grams")").accessibilityIdentifier("journal.amount")
                        Text(original.product.amountUnit).font(Paper.rounded(.title))
                    }
                    .padding(.horizontal, 15).padding(.vertical, 8)
                    .surfaceCard(radius: 20)
                    if Daybook.parseAmount(amount) == nil {
                        Text("Enter a portion from 0.1 to 10,000 \(original.product.amountUnit).").font(.caption).foregroundStyle(Paper.mint)
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isAccessibilitySize ? 2 : 4), spacing: 8) {
                        ForEach([50, 100, 150, 250], id: \.self) { size in
                            Button("\(size) \(original.product.amountUnit)") { amount = String(size); typing = false }
                                .font(Paper.rounded(.subheadline, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 12)
                                .foregroundStyle(Daybook.parseAmount(amount) == Double(size) ? Paper.base : Paper.ink)
                                .background(Daybook.parseAmount(amount) == Double(size) ? Paper.violet : Paper.surface,
                                            in: Capsule())
                        }
                    }.buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 10) {
                        Picker("Meal", selection: $meal) {
                            ForEach(MealSlot.allCases) { item in Label(item.label, systemImage: item.icon).tag(item) }
                        }.pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                        PaperRule()
                        if typeSize.isAccessibilitySize {
                            Text("Date").font(Paper.rounded(.headline))
                            DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                                .labelsHidden().datePickerStyle(.compact)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                        }
                    }.padding(18).surfaceCard()
                    if let parsed = Daybook.parseAmount(amount) {
                        NutritionLedger(entries: [candidate(parsed)], title: "In this portion")
                    }
                    if existing {
                        Button(role: .destructive) { confirmDelete = true } label: {
                            Label("Delete entry", systemImage: "trash").frame(maxWidth: .infinity)
                        }.padding(.vertical, 10)
                    }
                }.padding(20).frame(maxWidth: 660)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("journal.editor.scroll")
            .scrollDismissesKeyboard(.interactively)
            .background(Paper.base)
            .safeAreaInset(edge: .bottom) {
                Button {
                    guard let amount = Daybook.parseAmount(amount) else { return }
                    if onSave(candidate(amount)) { dismiss() } else { failed = true }
                } label: { Label(typeSize.isAccessibilitySize ? "Save" : (existing ? "Save changes" : "Log portion"), systemImage: "checkmark") }
                    .buttonStyle(PrintButton()).accessibilityIdentifier("journal.save").padding(.horizontal, 20).padding(.vertical, 6).background(Paper.base)
                    .accessibilityLabel(existing ? "Save changes" : "Log portion")
                    .disabled(Daybook.parseAmount(amount) == nil).opacity(Daybook.parseAmount(amount) == nil ? 0.5 : 1)
            }
            .journalSheet()
            .navigationTitle(existing ? "Journal entry" : "New portion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { typing = false } }
            }
            .confirmationDialog("Delete this portion from your journal?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete portion", role: .destructive) {
                    if onDelete() { dismiss() } else { failed = true }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Couldn’t save this entry", isPresented: $failed) {
                Button("Close") {}
            } message: { Text("Your changes could not be saved. Try again.") }
        }
        .environment(\.locale, Daybook.locale).foregroundStyle(Paper.ink).tint(Paper.mint)
    }

    private func candidate(_ amount: Double) -> Portion {
        var copy = original
        copy.amount = amount; copy.meal = meal; copy.date = Daybook.calendar.startOfDay(for: date)
        return copy
    }
}
