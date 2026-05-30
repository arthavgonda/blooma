//
//  ActivityLevelServiceProtocol.swift
//  prenatalPregnancy
//

import Foundation

protocol ActivityLevelServiceProtocol: AnyObject {
    func updateActivityLevelFromProgressIfNeeded(referenceDate: Date)
}
