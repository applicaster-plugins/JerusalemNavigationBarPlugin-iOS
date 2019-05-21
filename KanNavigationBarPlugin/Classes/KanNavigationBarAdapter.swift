//
//  KanNavigationBarAdapter.swift
//  Zapp-App
//
//  Created by Miri on 15/04/2019.
//  Copyright © 2017 Applicaster LTD. All rights reserved.
//

import Foundation
import ZappNavigationBarPluginsSDK
import ApplicasterSDK
import ZappSDK

@objc class KanNavigationBarAdapter: ZPNavigationBarBaseAdapter {
    let defaultNavigationStyle = "DefaultNavigationBarKan"
    let navigationStylePrefix  = "DefaultNavigationBar"

    /// Stores curently existing navigation bar xib
    var currentNavigationBarStyle:String?
    var screenModel:ZLScreenModel?
    
    /// Navigation Bar View instance
    open var navigationBar:KanNavigationBarUIBuilderView? {
        didSet {
            self.navigationBar?.delegate = navBarManagerDelegate
            customizeNavigationBar()
  
            navigationBar?.backButton?.isHidden = true
            navigationBar?.homeButton?.isHidden = true
        }
    }
    
    /// Customize NavigationBarView from navigation bar model
    func customizeNavigationBar() {
        if let navBarView = navBarView,
            let navigationBar = navigationBar {

            if let customizationHelper = customizationHelper {
                if let backImage = UIImage.init(named: "kan_navbar_back_btn", in: Bundle.main, compatibleWith: nil) {
                    navigationBar.backButton?.setImage(backImage, for: .normal)
                }
                else if let backImage = UIImage.init(named: "kan_navbar_back_btn", in: Bundle(for: self.classForCoder), compatibleWith: nil) {
                    navigationBar.backButton?.setImage(backImage, for: .normal)
                }
                
                if let shareButton = UIImage.init(named: "kan_share_btn", in: Bundle.main, compatibleWith: nil) {
                    navigationBar.shareButton?.setImage(shareButton, for: .normal)
                }
                else if let shareButton = UIImage.init(named: "kan_share_btn", in: Bundle(for: self.classForCoder), compatibleWith: nil) {
                    navigationBar.shareButton?.setImage(shareButton, for: .normal)
                }
                
                if let logoImage = UIImage.init(named: "kan_navbar_logo", in: Bundle.main, compatibleWith: nil) {
                    navigationBar.logoImageView?.image = logoImage
                }
                else if let logoImage = UIImage.init(named: "kan_navbar_logo", in: Bundle(for: self.classForCoder), compatibleWith: nil) {
                    navigationBar.logoImageView?.image = logoImage
                }
            
                navigationBar.specialButton?.prepareButton(for: customizationHelper.specialButtonImageURL(),
                                                        placeholderImage: customizationHelper.specialButtonImage())
                navigationBar.closeButton?.prepareButton(for: customizationHelper.closeButtonImageURL(),
                                                      placeholderImage: customizationHelper.closeButtonImage())

                if customizationHelper.backgroundType?() == .image,
                    let imageURL = customizationHelper.backgroundImageURL() {
                    navigationBar.backgroundColor = GAUICustomizationHelper.color(forKey: RootViewControllerStatusBarBgColor) ?? UIColor.black
                    navigationBar.backgroundImageView?.setImage(url: imageURL,
                                                                placeholderImage: nil)
                } else {
                    navigationBar.backgroundImageView?.image = nil
                    navigationBar.backgroundColor = customizationHelper.backgroundColor()
                }
                
                if let titleLabelFont = customizationHelper.fontForTitleLabel() {
                    navigationBar.titleLabel?.font = titleLabelFont
                }
                navigationBar.titleLabel?.textColor = customizationHelper.colorFotTitleLabel()
                
                navigationBar.homeButton?.setImage(customizationHelper.homeButtonImage(),
                                                   for:.normal)
                
                if forceNavigationBarHiddenRNScreens == true {
                    rootContainerDelegate?.placeNavBarToContainer(navigationBar: navBarView,
                                                                  placementType: .hidden)
                } else {
                    rootContainerDelegate?.placeNavBarToContainer(navigationBar: navBarView,
                                                                  placementType: isNoScreenModel == true ? .onTop : customizationHelper.placementType())
                }
            }
            navigationBar.shareButton?.isHidden = true

            GAAutomationManager.sharedInstance.setAccessibilityIdentifier(view: navigationBar.specialButton, identifier: AccessibilityIdSpecialButton)
            GAAutomationManager.sharedInstance.setAccessibilityIdentifier(view: navigationBar.backButton, identifier: AccessibilityIdSpecialButton)
        }
    }
    
    override var navBarView: UIView? {
        return navigationBar
    }

    override func updateNavBarTitle() {
        guard let navigationBar = navigationBar else {
            return
        }

        let forceShowLogo = customizationHelper?.forceHomeScreenShowLogo?() == true &&
            currentScreenModel?.isHomeScreen == true &&
            customizationHelper?.presentationType() != .hidden
        
        if (customizationHelper?.presentationType() == .logo || forceShowLogo == true) &&
            customizationHelper?.logoImageURL() != nil {
            navigationBar.logoImageView?.isHidden = false
            navigationBar.homeButton?.isHidden = false
        } else if customizationHelper?.presentationType() == .hidden {
            navigationBar.logoImageView?.isHidden = true
            navigationBar.homeButton?.isHidden = true
            navigationBar.titleLabel?.isHidden = true
        } else {
            if let currentViewController = currentViewController as? GAWebViewController {
                if let title = currentViewController.title {
                    let currentTitle = APApplicasterController.sharedInstance().isAppRTL ? title.rtl() : title
                    if currentTitle != navigationBar.titleLabel?.text {
                        navigationBar.titleLabel?.setText(currentTitle,
                                                          animationOptions: .transitionCrossDissolve,
                                                          completion: nil)
                    }
                    navigationBar.titleLabel?.isHidden = false
                }
                else {
                    navigationBar.titleLabel?.isHidden = true
                }
            }
            else if let title = screenModel?.name {
                let currentTitle = APApplicasterController.sharedInstance().isAppRTL ? title.rtl() : title
                if currentTitle != navigationBar.titleLabel?.text {
                    navigationBar.titleLabel?.setText(currentTitle,
                                                       animationOptions: .transitionCrossDissolve,
                                                       completion: nil)
                }
                navigationBar.titleLabel?.isHidden = false
            }
            else {
                navigationBar.titleLabel?.isHidden = true
            }
            if customizationHelper?.logoImageURL() != nil {
                navigationBar.logoImageView?.isHidden = false
                navigationBar.homeButton?.isHidden = false
            }
        }
    }
    
    override func customizeForScreen(model:AnyObject?,
                                     dataSource:AnyObject?) {
        isNoScreenModel = false
        currentDataSourceModel = dataSource
        navigationBar?.shareButton?.isHidden = false

        forceNavigationBarHiddenRNScreens = false
        if let model = model as? ZLScreenModel {
            if model.isPluginScreen(),
                let pluginIdentifier = model.typeInString(),
                let pluginModel = ZPPluginManager.pluginModelById(pluginIdentifier),
                pluginModel.isReactNativePlugin,
                let forceNavBarHidden = model.style?.object["force_nav_bar_hidden"] as? Bool,
                forceNavBarHidden == true {
                forceNavigationBarHiddenRNScreens = true
            }
            currentScreenModel = model
        } else {
            isNoScreenModel = true
            currentScreenModel = ZLComponentsManager.homeScreenDataSource()
        }
    }

    public override func prepareManager(customizationHelper: ZPNavigationBarCustomizationHelperDelegate,
                               completion: (Bool) -> Void)  {
        self.customizationHelper = customizationHelper
        super.prepareManager(customizationHelper: customizationHelper) { (success) in
            if success {
                navigationBar = navigationBarView(for: nil)
            }
            completion(success)
        }
    }
    
    /// List of caching items
    var cachedNavBarItems:[KanNavigationBarCachedModel] = []
    
    /// Data source of the screen
    var currentDataSourceModel:Any?
    var currentModelLink:String? {
        var retVal:String?
        if let currentDataSourceModel = currentDataSourceModel as? APAtomEntryProtocol {
            retVal = currentDataSourceModel.link
        } else if let currentDataSourceModel = currentDataSourceModel as? APCategory {
            retVal = currentDataSourceModel.uniqueID
        } else if let currentDataSourceModel = currentDataSourceModel as? APCollection {
            retVal = currentDataSourceModel.uniqueID
        }
        return retVal
    }
    
    /// Provide information that screen ScreenModel, this key is temporary until we will not have screen model for all screen types.
    /// This key used for two porposes
    /// 1. Screens that do not have screen Model will use data from Home
    /// 2. Such screen presentation style must be always on top, not overlay supported
    var isNoScreenModel:Bool = false

    /// Screen Model from currently presented Nav Bar
    var currentScreenModel:ZLScreenModel? {
        didSet {
            if let currentScreenModel = currentScreenModel,
                let customizationHelper = customizationHelper {
                customizationHelper.customizationModel = currentScreenModel
                
                navigationBar = navigationBarView(for: currentScreenModel)

                refreshButtons()
            }
        }
    }
    
    func refreshButtons() {
        if let navigationBarModel = currentScreenModel?.navigation(by: .navigationBar) {
            
            if let model = cachedModel(by: navigationBarModel) {
                populateButtons(model: model)
            } else {
                prepareModelForUse(for: navigationBarModel)
            }
        } else {
            populateButtons(model: nil)
        }
    }
    /// Create NavigationBarUIBuilderView instance
    ///
    /// - Parameter screenModel: Screen Model with information about style for navigation bar
    /// - Returns: NavigationBarUIBuilderView instance if can be created
    func navigationBarView(for screenModel:ZLScreenModel?) -> KanNavigationBarUIBuilderView? {
        self.screenModel = screenModel
        var retVal:KanNavigationBarUIBuilderView? = navigationBar
        var navigationBarStyle = defaultNavigationStyle
        if let navigationXibKey = customizationHelper?.navigationBarXib()?.capitalized {
            navigationBarStyle = navigationStylePrefix + navigationXibKey
        }
        
        if retVal == nil || navigationBarStyle != currentNavigationBarStyle {
            retVal = KanNavigationBarUIBuilderView.searchXib(navigationBarStyle,
                                                          in: Bundle(for: KanNavigationBarUIBuilderView.self)) as? KanNavigationBarUIBuilderView
            currentNavigationBarStyle = navigationBarStyle
        }
        
        return retVal
    }
    
}

extension KanNavigationBarAdapter {
    
    /// Retrieve cached navigation bar Model
    ///
    /// - Parameter dataModel: Instance of navigation bar model to retrieve
    /// - Returns: cached navigation bar model if exists
    func cachedModel(by dataModel: ZLNavigationModel) -> KanNavigationBarCachedModel? {
        let searchedItem = cachedNavBarItems.first { (cachedModel) -> Bool in
            return cachedModel.model?.identifier == dataModel.identifier
        }
        
        return searchedItem
    }
    
    /// Prepare navigation model for usage and cache it
    ///
    /// - Parameter dataModel: instance of navigation model
    func prepareModelForUse(for dataModel:ZLNavigationModel) {
        
        if let navBarManagerDelegate = navBarManagerDelegate {
            let newCachedModel = KanNavigationBarCachedModel(model: dataModel,
                                                            navBarManagerDelegate: navBarManagerDelegate)
            cachedNavBarItems.append(newCachedModel)
            populateButtons(model: newCachedModel)
        }
    }
    
    
    /// Populate buttons for navigation bar
    ///
    /// - Parameter model: GANavigationBarCachedModel instance
    func populateButtons(model: KanNavigationBarCachedModel?) {
        if let navigationBar = navigationBar {
            if let model = model {

                model.rightButtonsCollection.forEach {
                    if  isNoScreenModel == false {
                        if let screenType = $0.screenType,
                            let dataSourceURLString = $0.dataSourceURLString,
                            let urlString = currentModelLink {
                            $0.isEnabled = !(currentScreenModel?.screenID == screenType && dataSourceURLString == urlString)
                        } else if let screenType = $0.screenType,
                            let hookScreen = currentViewController as? ZPScreenHookProtocol,
                            let hookedViewController = hookScreen.preHookedViewController as? ZPUIBuilderScreenProtocol {
                            $0.isEnabled = !(hookedViewController.screenModel?.screenID == screenType)
                        }
                        else if let screenType = $0.screenType {
                            $0.isEnabled = !(currentScreenModel?.screenID == screenType)
                        }                     } else {
                        $0.isEnabled = true
                    }
//                    GAAutomationManager.sharedInstance.setAccessibilityIdentifier(view: $0, identifier: $0.model?.identifier)zq
                }
                navigationBar.rightMenuButtons = model.rightButtonsCollection
            } else {
                navigationBar.rightMenuButtons = []
            }
        }
    }
}

// MARK: - ZPNavigationBarManagerProtocol

extension KanNavigationBarAdapter: ZPNavigationBarManagerProtocol {
    func navigationController(_ navigationController:UINavigationController,
                              transitionStartedWithViewController viewController:UIViewController,
                              animated:Bool) {
        self.navigationBar?.isUserInteractionEnabled = false
    }
    
    func navigationController(_ navigationController:UINavigationController,
                              transitionEndedWithViewController viewController:UIViewController,
                              animated:Bool) {
        self.navigationBar?.isUserInteractionEnabled = true
    }
    
    func navigationController(_ navigationController:UINavigationController,
                              displayingRootViewController rootViewController:UIViewController) {

        if rootContainerDelegate?.isRootNavigationContainer() == true {
            if let navBarManagerDelegate = navBarManagerDelegate,
                navBarManagerDelegate.isSpecialButtonUsedByRoot() == false {
                self.navigationBar?.updateSpecialButtonsContainer(backButtonHidden: true,
                                                                  specialButtonHidden: true,
                                                                  closeButtonHidden: true)
            } else {
                self.navigationBar?.updateSpecialButtonsContainer(backButtonHidden: true,
                                                                  specialButtonHidden: false,
                                                                  closeButtonHidden: true)
            }
            
        } else {
            self.navigationBar?.updateSpecialButtonsContainer(backButtonHidden: true,
                                                               specialButtonHidden: true,
                                                               closeButtonHidden: false)
        }
        print("Anton: \(navigationController) \(self)")
        self.currentViewController = rootViewController
        
        if currentScreenModel != nil {
            self.updateNavBarTitle()
        }
        refreshButtons()

    }
    
    func navigationController(_ navigationController:UINavigationController,
                              displayingCurrentViewController currentViewController:UIViewController, previousViewController:UIViewController?) {
        self.navigationBar?.updateSpecialButtonsContainer(backButtonHidden: false,
                                                           specialButtonHidden: true,
                                                           closeButtonHidden: true)

        self.currentViewController = currentViewController
        self.updateNavBarTitle()
        refreshButtons()
        
        if let webViewController = currentViewController as? APTimedWebViewController,
            let url = webViewController.urlPath as NSURL? {
            navigationBar?.modelUrlPath = url
            navigationBar?.shareButton?.isHidden = false
        }
    }
}


