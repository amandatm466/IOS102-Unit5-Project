//
//  TriviaModels.swift
//  TriviaGame
//
//  Created by amanda torres on 10/28/26.
//

import Foundation

struct TriviaResponse: Codable {
    let responseCode: Int
    let results: [TriviaQuestion]
    
    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

struct TriviaQuestion: Codable, Identifiable {
    let id = UUID()
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
    
    enum CodingKeys: String, CodingKey {
        case category
        case type
        case difficulty
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
    
    // Combines correct and incorrect answers and shuffles them for display
    var allAnswers: [String] {
        var answers = incorrectAnswers + [correctAnswer]
        return answers.shuffled()
    }
}
