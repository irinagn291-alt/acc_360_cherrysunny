import SwiftUI

struct CatalogPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var text = ""
    @State private var offline = FoodCatalog.offline()
    @State private var results: [OFFProduct] = []
    @State private var searched = false
    @State private var loading = false
    @State private var message: String?
    @State private var fetchingCode: String?
    @State private var incomplete: OFFProduct?
    @State private var scanning = false
    @State private var task: Task<Void, Never>?
    @FocusState private var focused: Bool
    let onPick: (OFFProduct) -> Void

    init(onPick: @escaping (OFFProduct) -> Void) {
        self.onPick = onPick
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotLaunch.screen == .scanner {
            _text = State(initialValue: "5010029000016")
        }
        #endif
    }

    private var input: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var visibleOffline: [OFFProduct] {
        offline.filter { input.isEmpty || [$0.name, $0.brand, $0.id].contains { $0.localizedCaseInsensitiveContains(input) } }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 7) {
                            if !typeSize.isAccessibilitySize {
                                MarginLabel("A note starts here").foregroundStyle(Paper.mint)
                            }
                            Text("Find your food").font(Paper.rounded(.title))
                            if !typeSize.isAccessibilitySize {
                                Text("Search a label or scan the package.")
                                    .font(.subheadline).foregroundStyle(Paper.muted)
                            }
                        }
                        Spacer(minLength: 0)
                        if !typeSize.isAccessibilitySize {
                            Image(systemName: "carrot.fill").font(.system(size: 36)).foregroundStyle(Paper.apricot)
                                .rotationEffect(.degrees(-20)).accessibilityHidden(true)
                        }
                    }.padding(.vertical, 6)
                }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").foregroundStyle(Paper.violet)
                        TextField("Name, brand or barcode", text: $text,
                                  prompt: Text("Name, brand or barcode").foregroundStyle(Paper.muted))
                            .focused($focused).autocorrectionDisabled().submitLabel(.search)
                            .onSubmit { search(input) }.accessibilityIdentifier("catalog.query")
                        if !text.isEmpty {
                            Button { text = "" } label: { Image(systemName: "xmark.circle.fill") }
                                .buttonStyle(.borderless).accessibilityLabel("Clear")
                        }
                    }.padding(.vertical, 9)
                    HStack {
                        Button("Search online") { search(input) }
                            .disabled(input.isEmpty || loading).accessibilityIdentifier("catalog.search")
                            .font(Paper.rounded(.subheadline)).foregroundStyle(input.isEmpty || loading ? Paper.muted : Paper.mint)
                        Spacer()
                        Button { focused = false; scanning = true } label: { Label("Scan", systemImage: "barcode.viewfinder") }
                    }.buttonStyle(.borderless)
                } header: { Text("Open Food Facts") }
                    .listRowBackground(Paper.surface)
                if loading { ProgressView(fetchingCode == nil ? "Searching the catalog…" : "Opening the full label…").listRowBackground(Paper.surface) }
                if let message { Text(message).font(.callout).foregroundStyle(Paper.muted).listRowBackground(Paper.surface) }
                if searched && !results.isEmpty {
                    Section("Search results") { ForEach(results) { row($0, online: true) } }
                        .listRowBackground(Paper.surface)
                }
                if !visibleOffline.isEmpty && results.isEmpty {
                    Section {
                        ForEach(visibleOffline) { row($0, online: false) }
                    } header: { Text("Available offline") } footer: {
                        Text("Starter products and labels you open are stored on this device.")
                    }
                    .listRowBackground(Paper.surface)
                }
                Section {
                    Link("Open Food Facts · community data", destination: URL(string: "https://world.openfoodfacts.org")!)
                    Link("Database license · ODbL", destination: URL(string: "https://opendatacommons.org/licenses/odbl/1-0/")!)
                    Link("Photo license · CC BY-SA", destination: URL(string: "https://creativecommons.org/licenses/by-sa/3.0/")!)
                } footer: { Text("Recipes can change. Check the printed package for current ingredients.") }
                .font(.footnote).listRowBackground(Paper.surface)
            }
            .scrollContentBackground(.hidden).background(Paper.base)
            .journalSheet()
            .navigationTitle("Food catalog").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: text) { _, new in
                // Scanning starts a request for the new input in the same transaction.
                if new != submitted { reset() }
            }
            .sheet(isPresented: $scanning) {
                ScanSheet { code in scanning = false; text = code; search(code) }
            }
            .confirmationDialog("Full label unavailable", isPresented: Binding(get: { incomplete != nil }, set: { if !$0 { incomplete = nil } }), presenting: incomplete) { product in
                Button("Use available information") { finish(product) }
                Button("Cancel", role: .cancel) {}
            } message: { _ in Text("You can use the saved or indexed information now. Some fields may be missing.") }
            .onDisappear { task?.cancel() }
        }
    }

    @State private var submitted: String?
    private func reset() {
        task?.cancel()
        submitted = nil
        fetchingCode = nil
        incomplete = nil
        results = []; message = nil; loading = false; searched = false
    }

    private func search(_ query: String) {
        guard !query.isEmpty else { return }
        reset()
        submitted = query
        focused = false
        if query.allSatisfy({ $0.isNumber }) && !(4...14).contains(query.count) {
            message = "Check the barcode digits on the package."
            return
        }
        loading = true
        task = Task { @MainActor in
            do {
                let found = try await FoodCatalog.lookup(query)
                try Task.checkCancellation()
                results = found; searched = true
                if found.isEmpty { message = "No matches. Try another name or scan the barcode." }

            } catch {
                guard !Task.isCancelled else { return }
                message = (error as? CatalogFailure)?.errorDescription ?? CatalogFailure.unavailable.errorDescription
            }
            loading = false
        }
    }

    private func finish(_ product: OFFProduct) {
        FoodCatalog.remember([product])
        dismiss()
        onPick(product)
    }

    private func choose(_ product: OFFProduct, online: Bool) {
        // Barcode and offline rows already carry their complete stored record.
        guard online, submitted?.allSatisfy({ $0.isNumber }) != true else { finish(product); return }
        task?.cancel()
        fetchingCode = product.id
        loading = true
        task = Task { @MainActor in
            do {
                let full = try await FoodCatalog.lookup(product.id)
                try Task.checkCancellation()
                guard let label = full.first else { throw CatalogFailure.notFound }
                loading = false
                fetchingCode = nil
                finish(label)
            } catch {
                guard !Task.isCancelled else { return }
                loading = false
                fetchingCode = nil
                incomplete = offline.first { $0.id == product.id } ?? product
            }
        }
    }

    private func row(_ product: OFFProduct, online: Bool) -> some View {
        Button {
            choose(product, online: online)
        } label: {
            HStack(spacing: 13) {
                if !typeSize.isAccessibilitySize {
                    AsyncImage(url: product.imageURL.flatMap(URL.init(string:))) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Image(systemName: "fork.knife").foregroundStyle(Paper.violet)
                    }
                    .frame(width: 44, height: 54).padding(7)
                    .background(Paper.raised, in: RoundedRectangle(cornerRadius: 14)).accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name).font(Paper.rounded(.headline)).foregroundStyle(Paper.ink)
                    if !product.brand.isEmpty { Text(product.brand).font(.subheadline).foregroundStyle(Paper.muted) }
                    Text(product.id).font(.caption.monospacedDigit()).foregroundStyle(Paper.muted)
                }
                Spacer(minLength: 0)
                if !typeSize.isAccessibilitySize {
                    Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(Paper.mint).accessibilityHidden(true)
                }
            }.padding(.vertical, 7)
        }.disabled(fetchingCode != nil).accessibilityIdentifier("catalog.product." + product.id)
    }
}
