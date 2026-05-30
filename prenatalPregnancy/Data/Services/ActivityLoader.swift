//
//  ActivityLoader.swift
//  prenatalPregnancy
//

import Foundation

enum ActivityLoader {
    static func loadActivities() -> [ActivityDefinition] {
        let files = [
            "walking_activities_meaningful",
            "exercise_activities_mapped",
            "yoga_activities_medical_mapped"
        ]
        return files.flatMap { file in
            guard let url = Bundle.main.bloomaResourceURL(named: file, fileExtension: "json") else {
                print("⛔ [ActivityLoader] MISSING BUNDLE FILE: \(file).json — activities from this file will be unavailable")
                return [ActivityDefinition]()
            }
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([ActivityDefinition].self, from: data)
                print("✅ [ActivityLoader] Loaded \(decoded.count) activities from \(file).json")
                return decoded
            } catch {
                print("⛔ [ActivityLoader] Decode error in \(file).json: \(error)")
                return []
            }
        }
    }
}
