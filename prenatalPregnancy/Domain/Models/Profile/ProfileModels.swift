//
//  
// ProfileModels.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

//Profile
enum ProfileSection: Int, CaseIterable {
    
    case header
    case yourInformation
    case healthActivity
    case devices
    case privacy
    case support
    case about
    
    var title: String {
        switch self {
        case .header:
            return ""
        case .yourInformation:
            return "Your Information"
        case .healthActivity:
            return "Health & Activity"
        case .devices:
            return "Connected Devices"
        case .privacy:
            return "Privacy & Compliance"
        case .support:
            return "Support & Research"
        case .about:
            return "About App"
        }
    }
    
    var rows: [ProfileRow] {
        switch self {
            
        case .header:
            return []
            
        case .yourInformation:
            return [.personalInformation, .pregnancyInformation]
            
        case .healthActivity:
            return [.medicalConditions, .activityStatus]
            
        case .devices:
            return [.appleWatch]
            
        case .privacy:
            return [.legalCompliance, .permissions]
            
        case .support:
            return [.helpSupport, .researchInsights, .dataSources]
            
        case .about:
            return [.aboutBlooma, .credits, .logout]
        }
    }
}

enum ProfileRow {
    
    // Your Information
    case personalInformation
    case pregnancyInformation
    
    // Health
    case medicalConditions
    case activityStatus
    
    // Devices
    case appleWatch
    
    // Privacy
    case legalCompliance
    case permissions
    
    // Support
    case helpSupport
    case researchInsights
    case dataSources
    
    // About
    case aboutBlooma
    case credits
    case logout
    
    var title: String {
        switch self {
        case .personalInformation: return "Personal Information"
        case .pregnancyInformation: return "Pregnancy Information"
        case .medicalConditions: return "Medical Conditions"
        case .activityStatus: return "Activity Status"
        case .appleWatch: return "Apple Watch"
        case .legalCompliance: return "Legal & Compliance"
        case .permissions: return "Permissions"
        case .helpSupport: return "Help & Support"
        case .researchInsights: return "Research & Insights"
        case .dataSources: return "Data Sources"
        case .aboutBlooma: return "About Blooma"
        case .credits: return "Credits & Contributors"
        case .logout: return "Logout"
        }
    }
    
    var icon: String {
        switch self {
        case .personalInformation: return "person.text.rectangle"
        case .pregnancyInformation: return "heart.text.square"
        case .medicalConditions: return "cross.case"
        case .activityStatus: return "figure.run"
        case .appleWatch: return "applewatch"
        case .legalCompliance: return "doc.text"
        case .permissions: return "lock.shield"
        case .helpSupport: return "questionmark.circle"
        case .researchInsights: return "brain.head.profile"
        case .dataSources: return "externaldrive"
        case .aboutBlooma: return "info.circle"
        case .credits: return "person.3.fill"
        case .logout: return "rectangle.portrait.and.arrow.right"
        }
    }
    
    var subtitle: String {
        switch self {
            
        case .personalInformation:
            return "Manage your basic personal details like name and age."
            
        case .pregnancyInformation:
            return "Track your pregnancy progress and trimester details."
            
        case .medicalConditions:
            return "View and update your medical conditions."
            
        case .activityStatus:
            return "Monitor and adjust your daily activity level."
            
        case .appleWatch:
            return "Connect and manage your Apple Watch device."
            
        case .legalCompliance:
            return "View legal terms, policies and compliance details."
            
        case .permissions:
            return "Manage app permissions and privacy controls."
            
        case .helpSupport:
            return "Get help, FAQs and customer support."
            
        case .researchInsights:
            return "Explore research-based pregnancy insights."
            
        case .dataSources:
            return "See where your health data comes from."
            
        case .aboutBlooma:
            return "Learn more about the Blooma app."
            
        case .credits:
            return "Meet the experts, instructors, and contributors behind the app."
            
        case .logout:
            return "Sign out from your account securely."
        }
    }
    
    var contentId: String? {
        switch self {
        case .aboutBlooma:
            return "about_blooma"
            
        case .dataSources:
            return "data_sources"
            
        case .researchInsights:
            return "research_insights"
            
        case .legalCompliance:
            return "legal_compliance"
            
        default:
            return nil
        }
    }
    
    var isEditable: Bool {
        switch self {
        case .personalInformation, .pregnancyInformation, .medicalConditions, .activityStatus, .appleWatch:
            return true
            
        case .logout:
            return false
            
        default:
            return false
        }
    }
    
    var style: Style {
        switch self {
        case .logout:
            return .action
        default:
            return .normal
        }
    }
}

struct ProfileSectionData {
    let section: ProfileSection
    let rows: [ProfileRow]
}

struct ProfileDisplayValue {
    
    static func value(for row: ProfileRow, profile: UserProfile) -> String? {
        
        switch row {
            
        case .personalInformation:
            return profile.name
            
        case .pregnancyInformation:
            return "Week \(profile.gestationalWeek) + \(profile.gestationalDay) days (\(profile.trimester.displayTitle))"
            
        case .medicalConditions:
            return profile.medicalConditions.isEmpty ? "None" : profile.medicalConditions.map { $0.displayName }.joined(separator: ", ")
            
        case .activityStatus:
            return profile.activityLevel.displayName
            
        case .appleWatch:
            return profile.hasAppleWatch ? "Connected" : "Not Connected"
            
        default:
            return nil
        }
    }
}

enum ProfileDetailItem {
    
    case value(title: String, value: String?)
}

enum PickerType {
    case age
    case week
    case lmpDate
    case eddDate
    case activity
}

enum PermissionType {
    case motion
    case camera
    case photo
    case notification
    
    var icon: String {
        switch self {
        case .motion: return "figure.walk"
        case .camera: return "camera"
        case .photo: return "photo.on.rectangle"
        case .notification: return "bell.badge"
        }
    }
    
    var title: String {
        switch self {
        case .motion: return "Motion & Activity"
        case .camera: return "Camera"
        case .photo: return "Photo Library"
        case .notification: return "Notifications"
        }
    }
    
    var description: String {
        switch self {
        case .motion:
            return "Track activity for safe prenatal workouts."
        case .camera:
            return "Capture a photo for your profile when you choose."
        case .photo:
            return "Select images from your device for your profile."
        case .notification:
            return "Receive reminders for daily prenatal activities."
        }
    }
}

struct PermissionItem {
    let type: PermissionType
    
    var icon: String { type.icon }
    var title: String { type.title }
    var description: String { type.description }
    
    static var all: [PermissionItem] {
        return [
            PermissionItem(type: .motion),
            PermissionItem(type: .camera),
            PermissionItem(type: .photo),
            PermissionItem(type: .notification)
        ]
    }
}

enum PermissionStatus {
    case notDetermined
    case denied
    case authorized
}

struct AppContent: Codable {
    let id: String?
    let title: String
    let subtitle: String?
    let sections: [ContentSection]
}

struct ContentSection: Codable {
    let id: String?
    let title: String
    let content: ContentData
}

struct ContentData: Codable {
    let heroTitle: String
    let heroSubtitle: String
    let introBlocks: [IntroBlock]
    let items: [Item]
    
    enum CodingKeys: String, CodingKey {
        case heroTitle = "hero_title"
        case heroSubtitle = "hero_subtitle"
        case introBlocks = "intro_blocks"
        case items
    }
}

struct IntroBlock: Codable {
    let label: String
    let heading: String
    let paragraphs: [String]
}

struct Item: Codable {
    let icon: String
    let title: String
    let description: String
}

struct BloomaFAQResponse: Codable {
    let faqs: [BloomaFAQItem]
}

struct BloomaFAQItem: Codable {
    let id: Int
    let category: String
    let icon: String
    let question: String
    let answer: String
    let keywords: [String]
    
    var displayQuestion: String {
        question.replacingOccurrences(
            of: "\\s*\\(Q\\d+\\)$",
            with: "",
            options: .regularExpression
        )
    }
}
