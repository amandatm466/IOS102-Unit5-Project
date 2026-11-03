//
//  ContentView.swift
//  TriviaGame
//
//  Created by amanda torres on 10/28/26.
//

import SwiftUI

// MARK: - Options Selection Screen
struct ContentView: View {
    @State private var amount: Int = 5
    @State private var difficulty: String = "easy"
    @State private var type: String = "multiple"
    @State private var selectedCategory: Int = 9 // General Knowledge default
    
    @State private var questions: [TriviaQuestion] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isGameActive = false

    let difficulties = ["easy", "medium", "hard"]
    let types = [("Multiple Choice", "multiple"), ("True / False", "boolean")]
    let categories = [
        ("General Knowledge", 9),
        ("Books", 10),
        ("Film", 11),
        ("Science & Nature", 17),
        ("Computers", 18),
        ("Sports", 21),
        ("History", 23),
        ("Geography", 22)
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Customize Your Trivia")) {
                    Stepper("Number of Questions: \(amount)", value: $amount, in: 1...20)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.1) { category in
                            Text(category.0).tag(category.1)
                        }
                    }
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(difficulties, id: \.self) { diff in
                            Text(diff.capitalized).tag(diff)
                        }
                    }
                    
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.1) { typeItem in
                            Text(typeItem.0).tag(typeItem.1)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await fetchTriviaQuestions()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Start Trivia Game")
                                    .font(.headline)
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Trivia Options")
            .navigationDestination(isPresented: $isGameActive) {
                TriviaGameView(questions: questions)
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error occurred.")
            }
        }
    }

    private func fetchTriviaQuestions() async {
        isLoading = true
        let urlString = "https://opentdb.com/api.php?amount=\(amount)&category=\(selectedCategory)&difficulty=\(difficulty)&type=\(type)"
        
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL."
            isLoading = false
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(TriviaResponse.self, from: data)
            
            if response.responseCode == 0, !response.results.isEmpty {
                self.questions = response.results
                self.isLoading = false
                self.isGameActive = true
            } else {
                errorMessage = "No questions found for the selected options. Try different settings."
                isLoading = false
            }
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

// MARK: - Trivia Game View
struct TriviaGameView: View {
    let questions: [TriviaQuestion]
    @State private var userAnswers: [UUID: String] = [:] // Question ID -> Selected Answer
    @State private var score: Int = 0
    @State private var showAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question \(index + 1) of \(questions.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(parseHTML(question.question))
                            .font(.headline)
                        
                        // Answer choices
                        ForEach(question.allAnswers, id: \.self) { answer in
                            let isSelected = userAnswers[question.id] == answer
                            Button(action: {
                                userAnswers[question.id] = answer
                            }) {
                                HStack {
                                    Text(parseHTML(answer))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 3)
                    .padding(.horizontal)
                }
                
                Button(action: {
                    calculateScore()
                    showAlert = true
                }) {
                    Text("Submit Answers")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Trivia Challenge")
        .alert("Quiz Results", isPresented: $showAlert) {
            Button("Play Again") {
                dismiss()
            }
        } message: {
            Text("You scored \(score) out of \(questions.count)!")
        }
    }

    private func calculateScore() {
        var currentScore = 0
        for question in questions {
            if let selected = userAnswers[question.id], selected == question.correctAnswer {
                currentScore += 1
            }
        }
        self.score = currentScore
    }
    
    // Lightweight HTML entity decoder (Prevents SwiftUI layout cycles and crashes)
    private func parseHTML(_ string: String) -> String {
        var result = string
        let entities = [
            "&quot;": "\"",
            "&#039;": "'",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&eacute;": "é",
            "&rsquo;": "’",
            "&ldquo;": "“",
            "&rdquo;": "”"
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result
    }
}
