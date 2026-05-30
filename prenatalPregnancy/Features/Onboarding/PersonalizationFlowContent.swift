import UIKit

enum PersonalizationFlowContent {
    
    enum ReuseID {
        static let hero = "PersonalizationHeroCollectionViewCell"
        static let progress = "PersonalizationProgressCollectionViewCell"
        static let step = "PersonalizationStepsCollectionViewCell"
        static let continueCTA = "PersonalizationContinueCollectionViewCell"
    }
    
    enum Hero {
        static let eyebrow = "Blooma"
        static let title = "Personalizing your care"
        static let completeTitle = "Your care is ready"
        static let subtitle = "Creating your personalized experience"
        static let completeSubtitle = "Your experience is ready to begin"
        static let description = "Tailoring recommendations for your journey."
        static let completeDescription = "Recommendations are prepared for your journey."
        static let illustrationIcon = "figure.mind.and.body"
    }
    
    enum Progress {
        static let title = "Journey Progress"
        static func stepText(current: Int, total: Int) -> String {
            "Step \(current) of \(total)"
        }
        static func percentText(progress: CGFloat) -> String {
            "\(Int(round(progress * 100)))% Complete"
        }
    }
    
    enum Continue {
        static let title = "Begin My Blooma Journey"
        static let icon = "arrow.right"
    }
    
    struct StepDisplay {
        let title: String
        let subtitle: String
        let iconName: String
        let fallbackIconName: String
    }
    
    static func display(for step: RoutineProcessingStep) -> StepDisplay {
        switch step {
        case .filteringType:
            return StepDisplay(
                title: "Analyzing Activities",
                subtitle: "Activity types selected",
                iconName: "figure.mind.and.body",
                fallbackIconName: "figure.walk"
            )
        case .applyingTrimester:
            return StepDisplay(
                title: "Adjusting Trimester",
                subtitle: "Stage preferences tuned",
                iconName: "calendar.badge.clock",
                fallbackIconName: "calendar"
            )
        case .checkingProfile:
            return StepDisplay(
                title: "Reviewing Profile",
                subtitle: "Profile details considered",
                iconName: "person.crop.circle.badge.checkmark",
                fallbackIconName: "person.crop.circle"
            )
        case .validatingHealth:
            return StepDisplay(
                title: "Ensuring Safety",
                subtitle: "Safety preferences configured",
                iconName: "cross.case.fill",
                fallbackIconName: "heart.text.square.fill"
            )
        case .matchingLevel:
            return StepDisplay(
                title: "Matching Activity",
                subtitle: "Activity level optimized",
                iconName: "slider.horizontal.3",
                fallbackIconName: "line.3.horizontal.decrease.circle"
            )
        case .finalizing:
            return StepDisplay(
                title: "Finalizing Routine",
                subtitle: "Preparing recommendations",
                iconName: "wand.and.stars",
                fallbackIconName: "sparkles"
            )
        }
    }
}
