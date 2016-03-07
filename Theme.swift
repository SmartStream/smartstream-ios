//
//  Theme.swift
//  SmartStream
//
//  Created by Jerry on 3/6/16.
//  Copyright © 2016 SmartStream. All rights reserved.
//

import UIKit

import UIKit
struct Theme {
    enum Colors {
        case BackgroundColor
        case DarkBackgroundColor
        case LightBackgroundColor
        case HighlightColor
        case HighlightLightColor
        
        var color: UIColor{
            switch self {
            case .BackgroundColor: return UIColor(red: 32/255, green: 34/255, blue: 43/255, alpha: 1)
            case .DarkBackgroundColor: return UIColor(red: 23/255, green: 23/255, blue: 23/255, alpha: 1)
            case .LightBackgroundColor: return UIColor(red: 54/255, green: 56/255, blue: 67/255, alpha: 1)
            case .HighlightColor: return UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1)
            case .HighlightLightColor: return UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 0.5)
            }
        }
    }
    
    enum Fonts {
        case TitleTypeFace
        case TitleThinTypeFace
        case NormalTypeFace
        case LightNormalTypeFace
        
        var font: UIFont {
            switch self {
            case .TitleThinTypeFace: return UIFont.systemFontOfSize(30, weight: UIFontWeightThin)
            case .TitleTypeFace: return UIFont.systemFontOfSize(30, weight: UIFontWeightRegular)
            case .NormalTypeFace: return UIFont.systemFontOfSize(20, weight: UIFontWeightRegular)
            case .LightNormalTypeFace: return UIFont.systemFontOfSize(20, weight: UIFontWeightLight)
            }
        }
    }
}
