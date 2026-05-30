//
//  DateServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol DateServiceProtocol {
    func dayKey(_ date: Date) -> String
    func date(fromDayKey key: String) -> Date?
    func startOfDayInIST(for date: Date) -> Date
    func currentISTWeekday() -> String
    func currentISTHour() -> Int
    func secondsUntilNextISTMidnight(from date: Date) -> TimeInterval
    func pregnancyProgressDefaultsKey(_ suffix: String, userId: String?) -> String
    func saveRegistrationDate()
    func getRegistrationDate() -> Date
    func getWeekDayLabels() -> [String]
    func getWeekDayKeys() -> [String]
    var istCalendar: Calendar { get }
    var istCalendarForProgress: Calendar { get }
}
