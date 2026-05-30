//
//  
// RoutineProcessingModels.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

//Filtering
enum RoutineProcessingStep: Int, CaseIterable {
    
    case filteringType
    case applyingTrimester
    case checkingProfile
    case validatingHealth
    case matchingLevel
    case finalizing
    
    var title: String {
        switch self {
        case .filteringType:
            return "Analyzing activities..."
            
        case .applyingTrimester:
            return "Adjusting for your trimester..."
            
        case .checkingProfile:
            return "Reviewing your profile..."
            
        case .validatingHealth:
            return "Ensuring safety..."
            
        case .matchingLevel:
            return "Matching your activity level..."
            
        case .finalizing:
            return "Finalizing your routine..."
        }
    }
    
    var subtitle: String {
        switch self {
        case .filteringType:
            return "Selecting suitable activity types"
            
        case .applyingTrimester:
            return "Filtering based on your current stage"
            
        case .checkingProfile:
            return "Considering your personal details"
            
        case .validatingHealth:
            return "Applying safety guidelines"
            
        case .matchingLevel:
            return "Aligning with your comfort level"
            
        case .finalizing:
            return "Preparing your personalized plan"
        }
    }
}
