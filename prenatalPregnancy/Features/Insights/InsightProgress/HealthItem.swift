import Foundation

struct HealthItem {
    let title: String
    let progress: String
    let subtitle: String
    let motivation : String 
    let chartValues: [Double]
    let chartLabels: [String]
    

    func activityType() -> String {
        switch title.lowercased() {
        case "walking":
            return "walking"
        case "exercise":
            return "exercise"
        case "yoga":
            return "yoga"
        default:
            return "unknown"
        }
    }

    func parsedProgress() -> (completed: Double, target: Double) {
        let cleaned = progress
            .lowercased()
            .replacingOccurrences(of: "km", with: "")
            .replacingOccurrences(of: "sets", with: "")
            .replacingOccurrences(of: "min", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = cleaned.split(separator: "/").map {
            Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        }
        return (
            completed: parts.indices.contains(0) ? parts[0] : 0, target: parts.indices.contains(1) ? parts[1] : 0
        )
    }
}
