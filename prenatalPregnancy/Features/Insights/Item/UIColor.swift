import UIKit

extension UIColor {
    static func appColor(from name: String) -> UIColor {
        switch name.lowercased() {
        case "walking", "green":
            return .systemGreen
        case "exercise", "purple":
            return .systemPurple
        case "yoga", "red":
            return .systemRed
        case "pink":
            return .systemPink
        case "blue":
            return .systemBlue
        case "orange":
            return .systemOrange
        default:
            return .label
        }
    }

    static func appBackgroundColor(from name: String) -> UIColor {
        switch name.lowercased() {
        case "lightgreen":
            return UIColor.systemGreen.withAlphaComponent(0.12)
        case "lightpurple":
            return UIColor.systemPurple.withAlphaComponent(0.12)
        case "lightpink":
            return UIColor.systemPink.withAlphaComponent(0.12)
        case "lightblue":
            return UIColor.systemBlue.withAlphaComponent(0.12)
        case "lightorange":
            return UIColor.systemOrange.withAlphaComponent(0.12)
        case "lightred":
            return UIColor.systemRed.withAlphaComponent(0.12)
        default:
            return .systemGray6
        }
    }
}
