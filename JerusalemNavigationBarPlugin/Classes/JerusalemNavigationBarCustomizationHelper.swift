//
//  GANavigationBarCustomizationHelper.swift
//  Zapp-App
//
//  Created by Anton Kononenko on 18/12/2017.
//  Copyright © 2017 Applicaster LTD. All rights reserved.
//

import Foundation
import ZappNavigationBarPluginsSDK
import ZappSDK

class JerusalemNavigationBarCustomizationHelper:ZPNavigationBarCustomizationHelperDelegate {
    private struct DefaultImageNameKeys {
        static let backButton = "navbar_back_btn_ui_builder"
        static let closeButton = "navbar_menu_btn_close_ui_builder"
        static let menuButton = "navbar_menu_btn_ui_builder"
    }
    
    var custsomizationModel: NSObject?
    
    var model: ZLScreenModel? {
        return custsomizationModel as? ZLScreenModel
    }

    func navigationBarModel() -> ZLNavigationModel? {
        let retVal = model?.navigation(by: .navigationBar)
        return retVal
    }
    
    func keySuffixForDevice() -> String {
        return UIDevice.current.userInterfaceIdiom == .pad ? "_tablet" : ""
    }
    
    func intNumber(for key:String, from dictionary:[String:Any]) -> Int? {
        var retVal:Int?
        if let valueString = dictionary[key] as? String,
            let intValue = Int(valueString) {
            retVal = intValue
        } else if let value = dictionary[key] as? Int {
            retVal = value
        }
        return retVal
    }
    
    //MARK: Styles
    
    func placementType() -> ZPNavBarPlacement {
        var retVal:ZPNavBarPlacement = .onTop
        guard let styleDict = navigationBarModel()?.style,
            let placementString = styleDict[NavigationBarPlacementsKeys.generalKey] as? String else {
            return retVal
        }
        
        switch placementString {
        case NavigationBarPlacementsKeys.PlacementStates.overlay:
            retVal = .overlay
        case NavigationBarPlacementsKeys.PlacementStates.hidden:
            retVal = .hidden
        default:
            retVal = .onTop
        }
        return retVal
    }

    func presentationType() -> ZPNavBarPresentationStyle {
        var retVal:ZPNavBarPresentationStyle = .title
        guard let styleDict = navigationBarModel()?.style,
            let presentationStyleString = styleDict[NavigationPresentationKeys.generalKey] as? String else {
                return retVal
        }
        
        switch presentationStyleString {
        case NavigationPresentationKeys.PlacementStates.logo:
            retVal = .logo
        case NavigationPresentationKeys.PlacementStates.logoAndTitleHidden:
            retVal = .hidden
        default:
            retVal = .title
        }
        return retVal
    }
    
    public func forceHomeScreenShowLogo() -> Bool {
        guard let styleDict = navigationBarModel()?.style,
            let forceShowLogo = styleDict[NavigationBarStyleKeys.forceHomeScreenShowLogo] as? Bool else {
                return false
        }
        return forceShowLogo
    }
    
    func backgroundType() -> ZPNavBarBackgroundType {
        guard let styleDict = navigationBarModel()?.style,
            let backgroundTypeString = styleDict[NavigationBarStyleKeys.backgroundType] as? String else {
                return .color
        }
        if backgroundTypeString == NavigationBackgroundTypeKeys.Types.image {
            return .image
        }
        return .color
    }
    
    func backgroundColor() -> UIColor {
        let defaultColor = UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 1.0)
        guard let styleDict = navigationBarModel()?.style,
            let backgroundColorWithARGBHexString = styleDict[NavigationBarStyleKeys.backgroundColor] as? String else {
                return defaultColor
        }
        var retVal = UIColor(argbHexString: backgroundColorWithARGBHexString) ?? defaultColor
        if placementType() == .onTop {
            retVal = retVal.withAlphaComponent(1)
        }
        return retVal
    }
    
    func fontForTitleLabel() -> UIFont? {
        guard let styleDict = navigationBarModel()?.style,
            let fontName = styleDict[NavigationBarStyleKeys.titleLabelFontName] as? String,
            let fontSize = intNumber(for: NavigationBarStyleKeys.titleLabelFontSize + keySuffixForDevice(), from: styleDict) else {
                return UIFont.boldSystemFont(ofSize: 20)
        }
        let fontSizeCGFloat = CGFloat(fontSize)
        return UIFont(name: fontName,
                      size: fontSizeCGFloat)
    }
    
    func colorFotTitleLabel() -> UIColor {
        guard let styleDict = navigationBarModel()?.style,
            let fontColorWithARGBHexString = styleDict[NavigationBarStyleKeys.titleLabelColor] as? String else {
                return UIColor.black
        }
        return UIColor(argbHexString: fontColorWithARGBHexString) ?? UIColor.black
    }
    
    func navigationBarXib() -> String? {
        guard let styleDict = navigationBarModel()?.style,
            let navigationBarViewXib = styleDict[NavigationBarStyleKeys.xibName] as? String else {
                return nil
        }
        return navigationBarViewXib
    }
    
    //MARK: Assets
    func imageURL(for key:String,
                  isSupportIpad:Bool = false) -> URL? {
        var retVal:URL?
        
        let searchedKey = isSupportIpad == true ? key + keySuffixForDevice() : key
        guard let assetsDict = navigationBarModel()?.assets else {
            return retVal
        }
        
        if let imageURL = assetsDict[searchedKey] as? String {
            retVal = URL(string:imageURL)
        //Fallback logic, if not iPad image try take key
        } else if isSupportIpad == true,
            let imageURL = assetsDict[key] as? String {
            retVal = URL(string:imageURL)
        }
        
        return retVal
    }
    
    func backgroundImageURL() -> URL? {
        guard let stylesDict = navigationBarModel()?.style,
        let backgroundImageURL = stylesDict[NavigationBarAssetsKeys.backgroundImage] as? String,
            let url = URL(string:backgroundImageURL) else {
            return nil
        }
        return url
        
    }
    
    func backButtonImageURL() -> URL? {
        return imageURL(for: NavigationBarAssetsKeys.backButtonImage,
                        isSupportIpad: false)
    }
    
    func specialButtonImageURL() -> URL? {
        return imageURL(for: NavigationBarAssetsKeys.menuButtonImage,
                        isSupportIpad: false)
    }
    
    func closeButtonImageURL() -> URL? {
        return imageURL(for: NavigationBarAssetsKeys.closeButtonImage,
                        isSupportIpad: false)
    }
    
    func logoImageURL() -> URL? {
        return imageURL(for: NavigationBarAssetsKeys.appLogoImage,
                        isSupportIpad: false)
    }
        
    func backButtonImage() -> UIImage? {
        return UIImage(named:DefaultImageNameKeys.backButton)
    }
    
    func specialButtonImage() -> UIImage? {
        return UIImage(named:DefaultImageNameKeys.menuButton)
    }
    
    func closeButtonImage() -> UIImage? {
        return UIImage(named:DefaultImageNameKeys.closeButton)
    }
    
    func logoImage() -> UIImage? {
        return GAResourceHelper.imageNamed(GANavigationBarKeys.LogoImageName.rawValue)
    }
    
    func homeButtonImage() -> UIImage? {
        return GAResourceHelper.imageNamed(GANavigationBarKeys.HomeButtonImageName.rawValue)
    }
}
