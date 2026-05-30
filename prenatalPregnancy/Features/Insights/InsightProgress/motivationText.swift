import Foundation

enum HealthActivityType {
    case walking
    case exercise
    case yoga
    case unknown
}

enum MotivationText {

    static func text(activity: HealthActivityType,completed: Double,target: Double ) -> String {

        guard target > 0 else { return "Let’s get started 💪" }
        let percentage = (completed / target) * 100
        switch activity {
        case .walking:
            switch percentage {
            case 0..<25: return "Time for a short walk"
            case 25..<50: return "Nice pace, keep walking"
            case 50..<75: return "Halfway there"
            case 75..<100: return "Almost there"
            default: return "Walking completed"
            }
        case .exercise:
            switch percentage {
            case 0..<25: return "Let’s warm up"
            case 25..<50: return "Good effort"
            case 50..<75: return "Strong session"
            case 75..<100: return "Final reps"
            default: return "Workout completed"
            }
        case .yoga:
            switch percentage {
            case 0..<25: return "Let's Begin"
            case 25..<50: return "Nice flow"
            case 50..<75: return "Mind aligned"
            case 75..<100: return "Almost done"
            default: return "Yoga completed"
            }
        case .unknown:
            return "Keep going 👍"
        }
    }
}

