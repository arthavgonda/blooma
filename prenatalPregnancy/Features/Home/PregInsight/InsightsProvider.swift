struct InsightsProvider {

    static func getCategories(for week: Int) -> [Category] {

        return [
            Category(
                id: "bump_care",
                title: "Bump Care Basics",
                subtitle: subtitle(for: week, type: .bump_care),
                heroImage: "bump_care",
                items: []
            ),
            Category(
                id: "strength",
                title: "Strength From Within",
                subtitle: subtitle(for: week, type: .strength),
                heroImage: "strength",
                items: []
            ),
            Category(
                id: "sleep",
                title: "Calm Before Sleep",
                subtitle: subtitle(for: week, type: .sleep),
                heroImage: "sleep",
                items: []
            ),
            Category(
                id: "movement",
                title: "Safe Movement",
                subtitle: subtitle(for: week, type: .movement),
                heroImage: "movement",
                items: []
            )
        ]
    }

    private static func subtitle(for week: Int, type: InsightType) -> String {
        switch type {
        case .bump_care:
            return "Care for your growing bump"
            
        case .strength:
            return "Build strength from within"
            
        case .sleep:
            return "Rest and recharge your body"
            
        case .movement:
            return "Move safely and mindfully"
        }
    }
}

enum InsightType {
    case bump_care
    case strength
    case sleep
    case movement
}
