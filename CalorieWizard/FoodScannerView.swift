//
//  FoodScannerView.swift
//  CalorieWizard
//
//  Created by Paridhi Singh on 8/13/26.
//

import Charts
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct FoodScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    @State private var inputImage: UIImage? = nil
    @State private var showCamera = false
    
    @State private var analysisResult: String = "Snap or upload a meal photo to analyze calories and macros instantly."
    @State private var mealNutrition: MealNutrition? = nil
    @State private var mealKind: LoggedMealKind = .meal
    @State private var savedEntryID: UUID? = nil
    @State private var isLoading: Bool = false
    @State private var editingMacro: MacroKind? = nil
    
    // Gemini API Configuration
    private let apiKey = "YOUR_GEMINI_API_KEY"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: - Image Preview Section
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.secondarySystemBackground))
                            .frame(height: 240)
                        
                        if let inputImage = inputImage {
                            Image(uiImage: inputImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 48))
                                    .foregroundColor(.purple)
                                Text("No meal image selected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Action Buttons (Camera & Photo Library)
                    HStack(spacing: 12) {
                        Button(action: {
                            showCamera = true
                        }) {
                            Label("Take Photo", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Label("Photo Library", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .foregroundColor(.purple)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal)
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let item = newItem,
                                let data = try? await item.loadTransferable(type: Data.self),
                                let uiImage = UIImage(data: data) {
                                inputImage = uiImage
                                selectedImage = Image(uiImage: uiImage)
                                resetAnalysis()
                            }
                        }
                    }
                    .sheet(isPresented: $showCamera) {
                        ImagePicker(sourceType: .camera, selectedImage: $selectedImage, rawUIImage: $inputImage)
                    }
                    
                    // MARK: - AI Estimation Transparency Disclaimer
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Estimation Notice")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("AI estimates are for guidance and may vary. Tap any macro to manually adjust if needed.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(colorScheme == .dark ? 0.18 : 0.08))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // MARK: - Analyze Button
                    Button(action: {
                        Task {
                            await analyzeMealImage()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Label("Analyze Meal", systemImage: "sparkles")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(inputImage == nil ? Color.gray.opacity(0.3) : Color.indigo)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(inputImage == nil || isLoading)
                    .padding(.horizontal)
                    
                    // MARK: - Results Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis Results")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                            
                            if isLoading {
                                VStack(spacing: 8) {
                                    ProgressView()
                                    Text("Evaluating visual macros with Gemini...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(30)
                            } else {
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
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    } else {
                                        Text(analysisResult)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                                .padding()
                            }
                        }
                        .frame(minHeight: 180)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Meal Scanner")
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

    private func resetAnalysis() {
        mealNutrition = nil
        savedEntryID = nil
        mealKind = .meal
        analysisResult = "Snap or upload a meal photo to analyze calories and macros instantly."
    }

    private func persistCurrentMeal() {
        guard let nutrition = mealNutrition, let uiImage = inputImage else { return }

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
        let targetID = id
        var descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate<MealEntry> { entry in
                entry.id == targetID
            }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Gemini Vision Analysis Logic
    func analyzeMealImage() async {
        guard let inputImage = inputImage,
              let imageData = inputImage.jpegData(compressionQuality: 0.8) else { return }
         
        isLoading = true
        defer { isLoading = false }
         
        let base64Image = imageData.base64EncodedString()
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { return }
         
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
                    self.persistCurrentMeal()
                }
            } else {
                await MainActor.run {
                    self.analysisResult = "Could not parse structured nutritional response. Please try again."
                }
            }
        } catch {
            await MainActor.run {
                self.analysisResult = "Error connecting to Gemini Vision: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    FoodScannerView()
        .modelContainer(for: MealEntry.self, inMemory: true)
}
