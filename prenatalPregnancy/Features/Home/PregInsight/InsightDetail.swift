// InsightDetail.swift

import Foundation

struct InsightDetail: Codable {
    let week: Int
    let section: String
    let title: String
    let subtitle: String
    let description: String

    let whatToExpect: [String]?
    let careTips: [String]?
    let nutritionFocus: [String]?
    let recommendedFoods: [String]?
    let foodsToLimit: [String]?
    let hydration: [String]?
    let restPractices: [String]?
    let mindfulnessPractices: [String]?
    let emotionalWellbeing: [String]?
    let dailySafetyTips: [String]?
    let movementGuidelines: [String]?
    let environmentalAwareness: [String]?
    let travelSafety: [String]?
    let medicalCheckups: MedicalCheckups?
    let importantNote: String?
    let reassurance: String?
    let medicalDisclaimer: String?
    let conditionOverrides: [String: ConditionOverride]?
    let multiConditionBlend: MultiConditionBlend?

    enum CodingKeys: String, CodingKey {
        case week, section, title, subtitle, description
        case whatToExpect         = "what_to_expect"
        case careTips             = "care_tips"
        case nutritionFocus       = "nutrition_focus"
        case recommendedFoods     = "recommended_foods"
        case foodsToLimit         = "foods_to_limit"
        case hydration
        case restPractices        = "rest_practices"
        case mindfulnessPractices = "mindfulness_practices"
        case emotionalWellbeing   = "emotional_wellbeing"
        case dailySafetyTips      = "daily_safety_tips"
        case movementGuidelines   = "movement_guidelines"
        case environmentalAwareness = "environmental_awareness"
        case travelSafety         = "travel_safety"
        case medicalCheckups      = "medical_checkups"
        case importantNote        = "important_note"
        case reassurance
        case medicalDisclaimer    = "medical_disclaimer"
        case conditionOverrides   = "condition_overrides"
        case multiConditionBlend  = "multi_condition_blend"
    }
}

struct MedicalCheckups: Codable {
    let note: String
    let commonlySuggested: [SuggestedTest]
    let guidance: String

    enum CodingKeys: String, CodingKey {
        case note
        case commonlySuggested = "commonly_suggested"
        case guidance
    }
}

struct SuggestedTest: Codable {
    let name: String
    let purpose: String
}

struct ConditionOverride: Codable {
    let personalizedDescription: String?
    let careTips: [String]?
    let nutritionFocus: [String]?
    let recommendedFoods: [String]?
    let foodsToLimit: [String]?
    let restPractices: [String]?
    let mindfulnessPractices: [String]?
    let movementGuidelines: [String]?
    let medicalFocus: String?
    let safetyFocus: String?
    let reassurance: String?

    enum CodingKeys: String, CodingKey {
        case personalizedDescription = "personalized_description"
        case careTips                = "care_tips"
        case nutritionFocus          = "nutrition_focus"
        case recommendedFoods        = "recommended_foods"
        case foodsToLimit            = "foods_to_limit"
        case restPractices           = "rest_practices"
        case mindfulnessPractices    = "mindfulness_practices"
        case movementGuidelines      = "movement_guidelines"
        case medicalFocus            = "medical_focus"
        case safetyFocus             = "safety_focus"
        case reassurance
    }
}

struct MultiConditionBlend: Codable {
    let enabled: Bool
    let combinedMessage: String
    let priorityTips: [String]?
    let priorityNutrition: [String]?
    let priorityPractices: [String]?
    let priorityGuidelines: [String]?
    let reassurance: String

    enum CodingKeys: String, CodingKey {
        case enabled
        case combinedMessage = "combined_message"
        case priorityTips = "priority_tips"
        case priorityNutrition = "priority_nutrition"
        case priorityPractices = "priority_practices"
        case priorityGuidelines = "priority_guidelines"
        case reassurance
    }

    var resolvedPriorities: [String] {
        priorityTips ?? priorityNutrition ?? priorityPractices ?? priorityGuidelines ?? []
    }
}
