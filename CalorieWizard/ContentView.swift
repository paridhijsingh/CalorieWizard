//
//  ContentView.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/12/26.
//

import Charts
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct MealNutrition: Codable, Equatable {
    var food: String
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatsG: Double
    var insights: String

    enum CodingKeys: String, CodingKey {
        case food, calories, insights
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatsG = "fats_g"
    }
}

enum MacroKind: String, Identifiable, CaseIterable {
    case protein
    case carbs
    case fats

    var id: String { rawValue }

    var title: String {
        switch self {
        case .protein: "Protein"
        case .carbs: "Carbs"
        case .fats: "Fats"
        }
    }
}

enum LoggedMealKind: String, Codable, CaseIterable, Identifiable {
    case meal
    case snack

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meal: "Meal"
        case .snack: "Snack"
        }
    }
}

@Model
final class MealEntry {
    var id: UUID
    var foodName: String
    var calories: Double
    var proteinG: Double
    var carbsG: Double
    var fatsG: Double
    var insights: String
    var createdAt: Date
    var imageFileName: String
    var mealKindRaw: String

    var mealKind: LoggedMealKind {
        get { LoggedMealKind(rawValue: mealKindRaw) ?? .meal }
        set { mealKindRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        foodName: String,
        calories: Double,
        proteinG: Double,
        carbsG: Double,
        fatsG: Double,
        insights: String,
        createdAt: Date = .now,
        imageFileName: String,
        mealKind: LoggedMealKind = .meal
    ) {
        self.id = id
        self.foodName = foodName
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatsG = fatsG
        self.insights = insights
        self.createdAt = createdAt
        self.imageFileName = imageFileName
        self.mealKindRaw = mealKind.rawValue
    }

    func apply(_ nutrition: MealNutrition) {
        foodName = nutrition.food
        calories = nutrition.calories
        proteinG = nutrition.proteinG
        carbsG = nutrition.carbsG
        fatsG = nutrition.fatsG
        insights = nutrition.insights
    }
}

enum MealImageStore {
    private static var directory: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MealImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    static func save(_ image: UIImage, id: UUID) -> String? {
        let fileName = "\(id.uuidString).jpg"
        let url = directory.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.72) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return fileName
        } catch {
            return nil
        }
    }

    static func load(_ fileName: String) -> UIImage? {
        guard !fileName.isEmpty else { return nil }
        let url = directory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: url.path)
    }

    static func delete(_ fileName: String) {
        guard !fileName.isEmpty else { return }
        let url = directory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}

private struct MacroSlice: Identifiable {
    let id: String
    let name: String
    let grams: Double
    let caloriesPerGram: Double
    let color: Color
    let kind: MacroKind

    var calories: Double { grams * caloriesPerGram }
}

struct MacroProgressRing: View {
    let proteinGrams: Double
    let carbsGrams: Double
    let fatsGrams: Double
    let reportedCalories: Double
    var allowsEditing: Bool = false
    var onSelectMacro: ((MacroKind) -> Void)? = nil

    private var slices: [MacroSlice] {
        [
            MacroSlice(id: "protein", name: "Protein", grams: proteinGrams, caloriesPerGram: 4, color: .purple, kind: .protein),
            MacroSlice(id: "carbs", name: "Carbs", grams: carbsGrams, caloriesPerGram: 4, color: .orange, kind: .carbs),
            MacroSlice(id: "fats", name: "Fats", grams: fatsGrams, caloriesPerGram: 9, color: .green, kind: .fats)
        ]
    }

    private var displayCalories: Int {
        let macroCalories = slices.reduce(0) { $0 + $1.calories }
        let value = reportedCalories > 0 ? reportedCalories : macroCalories
        return Int(value.rounded())
    }

    var body: some View {
        HStack(spacing: 20) {
            Chart(slices) { slice in
                SectorMark(
                    angle: .value("Calories", max(slice.calories, 0.01)),
                    innerRadius: .ratio(0.72),
                    angularInset: 2.5
                )
                .foregroundStyle(slice.color)
                .cornerRadius(5)
            }
            .chartLegend(.hidden)
            .frame(width: 132, height: 132)
            .overlay {
                VStack(spacing: 2) {
                    Text("\(displayCalories)")
                        .font(.title2.weight(.bold).monospacedDigit())
                    Text("kcal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(slices) { slice in
                    Button {
                        onSelectMacro?(slice.kind)
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(slice.color)
                                .frame(width: 10, height: 10)
                            Text(slice.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Spacer(minLength: 8)
                            Text(slice.grams == slice.grams.rounded() ? "\(Int(slice.grams.rounded()))g" : String(format: "%.1fg", slice.grams))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                            if allowsEditing {
                                Image(systemName: "pencil")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!allowsEditing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum MealNutritionParser {
    static func parse(_ text: String) -> MealNutrition? {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "", options: .caseInsensitive)
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let data = cleaned.data(using: .utf8),
           let nutrition = try? JSONDecoder().decode(MealNutrition.self, from: data) {
            return nutrition
        }

        if let start = cleaned.firstIndex(of: "{"),
           let end = cleaned.lastIndex(of: "}"),
           start < end,
           let data = String(cleaned[start...end]).data(using: .utf8),
           let nutrition = try? JSONDecoder().decode(MealNutrition.self, from: data) {
            return nutrition
        }

        return nil
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var rawUIImage: UIImage? = nil
    @State private var aiAnalysisResult: String = "Tap 'Select Meal' to analyze your food!"
    @State private var mealNutrition: MealNutrition? = nil
    @State private var mealKind: LoggedMealKind = .meal
    @State private var savedEntryID: UUID? = nil
    @State private var showingSourceOptions = false
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var isAnalyzing = false
    @State private var editingMacro: MacroKind? = nil

    let apiKey = APIKeys.gemini

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    imagePreview
                    actionButtons
                    disclaimerCard
                    insightsCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Analyze")
            .confirmationDialog("Select Meal Source", isPresented: $showingSourceOptions, titleVisibility: .visible) {
                Button("Take Photo with Camera") {
                    showingCamera = true
                }
                Button("Choose from Library") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage, rawUIImage: $rawUIImage)
            }
            .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                        rawUIImage = uiImage
                        resetAnalysis()
                        aiAnalysisResult = "Image loaded! Ready for analysis."
                    }
                }
            }
            .sheet(item: $editingMacro) { kind in
                MacroAdjustSheet(nutrition: nutritionBinding, focusedMacro: kind)
                    .onDisappear { persistCurrentMeal() }
            }
        }
    }

    private var nutritionBinding: Binding<MealNutrition> {
        Binding(
            get: { mealNutrition ?? MealNutrition(food: "", calories: 0, proteinG: 0, carbsG: 0, fatsG: 0, insights: "") },
            set: { mealNutrition = $0 }
        )
    }

    private var imagePreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 260)

            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text("No Meal Selected")
                        .foregroundStyle(.secondary)
                        .font(.headline)
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                showingSourceOptions = true
            } label: {
                Text("Select Meal")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button(action: analyzeMealWithGemini) {
                Text(isAnalyzing ? "Analyzing..." : "Analyze with AI")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        rawUIImage != nil && !isAnalyzing ? Color.green : Color.gray,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .disabled(rawUIImage == nil || isAnalyzing)
        }
    }

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.purple)
                .padding(.top, 1)

            Text("AI estimates are for guidance and may vary. Tap any macro to manually adjust if needed.")
                .font(.caption)
                .italic()
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(colorScheme == .dark ? 0.18 : 0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityLabel("AI estimates are for guidance and may vary. Tap any macro to manually adjust if needed.")
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let mealNutrition {
                Picker("Type", selection: $mealKind) {
                    ForEach(LoggedMealKind.allCases) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: mealKind) { _, _ in
                    persistCurrentMeal()
                }

                MacroProgressRing(
                    proteinGrams: mealNutrition.proteinG,
                    carbsGrams: mealNutrition.carbsG,
                    fatsGrams: mealNutrition.fatsG,
                    reportedCalories: mealNutrition.calories,
                    allowsEditing: true,
                    onSelectMacro: { editingMacro = $0 }
                )

                Divider()

                Text(mealNutrition.food)
                    .font(.headline)

                Text(mealNutrition.insights)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(aiAnalysisResult)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func resetAnalysis() {
        mealNutrition = nil
        savedEntryID = nil
        mealKind = .meal
    }

    private func persistCurrentMeal() {
        guard let nutrition = mealNutrition, let uiImage = rawUIImage else { return }

        if let savedEntryID,
           let entry = existingEntry(id: savedEntryID) {
            entry.apply(nutrition)
            entry.mealKind = mealKind
        } else {
            let id = UUID()
            let fileName = MealImageStore.save(uiImage, id: id) ?? ""
            let entry = MealEntry(
                id: id,
                foodName: nutrition.food,
                calories: nutrition.calories,
                proteinG: nutrition.proteinG,
                carbsG: nutrition.carbsG,
                fatsG: nutrition.fatsG,
                insights: nutrition.insights,
                imageFileName: fileName,
                mealKind: mealKind
            )
            modelContext.insert(entry)
            savedEntryID = id
        }

        try? modelContext.save()
    }

    private func existingEntry(id: UUID) -> MealEntry? {
        let descriptor = FetchDescriptor<MealEntry>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }

    private func analyzeMealWithGemini() {
        guard let uiImage = rawUIImage,
              let imageData = uiImage.jpegData(compressionQuality: 0.8) else { return }

        isAnalyzing = true
        aiAnalysisResult = "Analyzing image with Gemini..."

        let base64Image = imageData.base64EncodedString()
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            isAnalyzing = false
            return
        }

        let prompt = """
        Analyze this food image and return a JSON object with EXACTLY this structure, with no extra text or markdown wrappers outside the JSON:
        {
          "food": "Name of the meal",
          "calories": 0.0,
          "protein_g": 0.0,
          "carbs_g": 0.0,
          "fats_g": 0.0,
          "insights": "Brief healthy ingredients breakdown and nutritional insights."
        }
        """

        let payload: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]

        Task {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)

                let (data, _) = try await URLSession.shared.data(for: request)

                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String,
                   let parsedNutrition = MealNutritionParser.parse(text) {
                    await MainActor.run {
                        self.mealNutrition = parsedNutrition
                        self.isAnalyzing = false
                        self.persistCurrentMeal()
                    }
                } else {
                    await MainActor.run {
                        self.aiAnalysisResult = "Failed to parse nutritional data from Gemini response."
                        self.isAnalyzing = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.aiAnalysisResult = "Network error: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }
}

// MARK: - Macro Adjust Sheet
struct MacroAdjustSheet: View {
    @Binding var nutrition: MealNutrition
    let focusedMacro: MacroKind
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Adjust \(focusedMacro.title)") {
                    switch focusedMacro {
                    case .protein:
                        Stepper("Protein: \(Int(nutrition.proteinG))g", value: $nutrition.proteinG, in: 0...300, step: 1)
                    case .carbs:
                        Stepper("Carbs: \(Int(nutrition.carbsG))g", value: $nutrition.carbsG, in: 0...500, step: 1)
                    case .fats:
                        Stepper("Fats: \(Int(nutrition.fatsG))g", value: $nutrition.fatsG, in: 0...200, step: 1)
                    }
                    
                    Stepper("Calories: \(Int(nutrition.calories)) kcal", value: $nutrition.calories, in: 0...3000, step: 10)
                }
            }
            .navigationTitle("Edit Macro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Meal Detail

struct MealDetailView: View {
    let meal: MealEntry

    var body: some View {
        List {
            Section("Meal") {
                LabeledContent("Name", value: meal.foodName)
                LabeledContent("Type", value: meal.mealKind.displayName)
                LabeledContent("Logged", value: meal.createdAt.formatted(date: .abbreviated, time: .shortened))
            }

            Section("Nutrition") {
                LabeledContent("Calories", value: "\(Int(meal.calories.rounded())) kcal")
                LabeledContent("Protein", value: "\(Int(meal.proteinG.rounded())) g")
                LabeledContent("Carbs", value: "\(Int(meal.carbsG.rounded())) g")
                LabeledContent("Fats", value: "\(Int(meal.fatsG.rounded())) g")
            }

            if !meal.insights.isEmpty {
                Section("Insights") {
                    Text(meal.insights)
                }
            }
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: MealEntry.self, inMemory: true)
}
