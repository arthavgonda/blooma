//
//  DateService.swift
//  prenatalPregnancy
//

import Foundation

final class DateService: DateServiceProtocol {

    static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return formatter
    }()

    static let insightDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return formatter
    }()

    static let insightTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return formatter
    }()

    static let graphDayLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return formatter
    }()

    var istCalendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return cal
    }

    var istCalendarForProgress: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata")!
        return cal
    }

    func dayKey(_ date: Date) -> String {
        Self.dayKeyFormatter.string(from: date)
    }

    func date(fromDayKey key: String) -> Date? {
        Self.dayKeyFormatter.date(from: key)
    }

    func startOfDayInIST(for date: Date = Date()) -> Date {
        istCalendar.startOfDay(for: date)
    }

    func currentISTWeekday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return formatter.string(from: Date())
    }

    func currentISTHour() -> Int {
        istCalendar.component(.hour, from: Date())
    }

    func secondsUntilNextISTMidnight(from date: Date = Date()) -> TimeInterval {
        let startOfToday = istCalendar.startOfDay(for: date)
        let nextMidnight = istCalendar.date(byAdding: .day, value: 1, to: startOfToday) ?? date.addingTimeInterval(86400)
        return max(1, nextMidnight.timeIntervalSince(date))
    }

    func pregnancyProgressDefaultsKey(_ suffix: String, userId: String?) -> String {
        let userKey = userId ?? "guest"
        return "pregnancyProgress.\(userKey).\(suffix)"
    }

    func saveRegistrationDate() {
        guard UserDefaults.standard.object(forKey: "registrationDate") == nil else { return }
        let today = istCalendarForProgress.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: "registrationDate")
    }

    func getRegistrationDate() -> Date {
        if let saved = UserDefaults.standard.object(forKey: "registrationDate") as? Date {
            return saved
        }
        let today = istCalendarForProgress.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: "registrationDate")
        return today
    }

    func getWeekDayLabels() -> [String] {
        let cal = istCalendarForProgress
        let today = cal.startOfDay(for: Date())
        let reg = cal.startOfDay(for: getRegistrationDate())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")!

        guard let daysSinceReg = cal.dateComponents([.day], from: reg, to: today).day else {
            return Array(repeating: "", count: 6) + ["Today"]
        }

        var labels: [String] = []

        for slot in 0..<7 {
            if slot < 6 {
                let offsetFromReg = slot
                if offsetFromReg > daysSinceReg {
                    labels.append("")
                } else if offsetFromReg == daysSinceReg {
                    labels.append("Today")
                } else {
                    guard let day = cal.date(byAdding: .day, value: offsetFromReg, to: reg) else {
                        labels.append("")
                        continue
                    }
                    labels.append(formatter.string(from: day))
                }
            } else {
                if daysSinceReg >= 6 {
                    labels.append("Today")
                } else {
                    labels.append("")
                }
            }
        }

        return labels
    }

    func getWeekDayKeys() -> [String] {
        let cal = istCalendarForProgress
        let today = cal.startOfDay(for: Date())
        let reg = cal.startOfDay(for: getRegistrationDate())

        guard let daysSinceReg = cal.dateComponents([.day], from: reg, to: today).day else {
            return Array(repeating: "", count: 7)
        }

        var keys: [String] = []

        for slot in 0..<7 {
            if slot < 6 {
                let offsetFromReg = slot
                if offsetFromReg > daysSinceReg {
                    keys.append("")
                } else {
                    guard let day = cal.date(byAdding: .day, value: offsetFromReg, to: reg) else {
                        keys.append("")
                        continue
                    }
                    keys.append(dayKey(day))
                }
            } else {
                if daysSinceReg >= 6 {
                    keys.append(dayKey(today))
                } else {
                    keys.append("")
                }
            }
        }

        return keys
    }
}
