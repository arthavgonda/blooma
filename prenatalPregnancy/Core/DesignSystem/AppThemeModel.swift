//
//  
// AppThemeModel.swift
//  prenatalPregnancy
//

import Foundation
import UIKit

//App Color
enum Style {
    case normal
    case action
}

struct AppTheme {
    
    let backgroundGradientStart: UIColor
    let backgroundGradientEnd: UIColor
    
    let glassUltraThin: UIColor
    let glassThin: UIColor
    let glassMedium: UIColor
    let glassStrong: UIColor
    
    let glassBorderLight: UIColor
    let glassBorderStrong: UIColor
    
    let shadowSoft: UIColor
    let shadowMedium: UIColor
    
    let primaryText: UIColor
    let secondaryText: UIColor
    let tertiaryText: UIColor
    
    let accentPrimary: UIColor
    let accentSecondary: UIColor
    
    let buttonGlassBackground: UIColor
    let buttonGlassBorder: UIColor
    let buttonText: UIColor
    
    let inputGlassBackground: UIColor
    let inputGlassBorder: UIColor
    
    let success: UIColor
    let warning: UIColor
    let error: UIColor
    
    let divider: UIColor
    let shimmer: UIColor
}
