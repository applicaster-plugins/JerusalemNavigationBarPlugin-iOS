//
//  JerusalemNavigationBarManager.swift
//  Zapp-App
//
//  Created by Anton Kononenko on 01/12/2017.
//  Copyright © 2017 Applicaster LTD. All rights reserved.
//

import Foundation
import ZappNavigationBarPluginsSDK
import ZappRootPluginsSDK
import ZappSDK
import ZappPlugins

enum GANavigationBarKeys : String {
    case BackButtonImageName    = "navbar_back_btn"
    case LogoImageName          = "navbar_logo"
    case BackgroundImageName    = "navbar_background"
    case SpecialButtonImageName = "navbar_menu_btn"
    case CloseButtonImageName   = "pop_up_close_button"
    case HomeButtonImageName    = "navbar_home_btn"
}

/// Caching Item to controll presenting screen from NavigationBar
struct NavigationBarCatchingItem {

    /// ScreenType of the screen
    var screenType:String?
    
    /// Data Source URL of the screen
    var dataSourceURL:String?
    
    /// GARootViewContainerController instance. screen will be wrapped into this NavigationViewController
    var presentationScreen:GARootViewContainerController
    
    // Instance of root view controller from Navigation View Controller to get analytics data
    var rootViewController:UIViewController
    
    var innerNavigationController: ZPNavigationController? {
        return presentationScreen.innerNavigationController
    }
    
    /// Intance of current view controller in navigation stack
    var latestViewController:UIViewController? {
        return presentationScreen.innerNavigationController?.viewControllers.last
    }
    
    static func ==(lhs: NavigationBarCatchingItem, rhs: NavigationBarCatchingItem) -> Bool {
        var retVal = false
        if let lhsDataSourceURL = lhs.dataSourceURL,
            let rhsDataSourceURL = rhs.dataSourceURL,
            let lhsScreenType = lhs.screenType,
            let rhsScreenType = rhs.screenType {
            retVal = lhsScreenType == rhsScreenType &&
                lhsDataSourceURL == rhsDataSourceURL
        } else if let lhsScreenType = lhs.screenType,
            let rhsScreenType = rhs.screenType {
            retVal = lhsScreenType == rhsScreenType
        }
        return retVal
    }
    
    static func !=(lhs: NavigationBarCatchingItem, rhs: NavigationBarCatchingItem) -> Bool {
        var retVal = false

        if let lhsDataSourceURL = lhs.dataSourceURL,
            let rhsDataSourceURL = rhs.dataSourceURL,
            let lhsScreenType = lhs.screenType,
            let rhsScreenType = rhs.screenType {
            retVal = lhsScreenType != rhsScreenType ||
                lhsDataSourceURL != rhsDataSourceURL
        } else if let lhsScreenType = lhs.screenType,
            let rhsScreenType = rhs.screenType {
            retVal = lhsScreenType != rhsScreenType
        }
        
        return retVal
    }
}

@objc public class JerusalemNavigationBarManager: NSObject {
    
    /// Singletone of navigation bar manager
    @objc public static let sharedInstance = JerusalemNavigationBarManager()

    /// Array of presented screen created from navigataion bar
    fileprivate var cachedScreenCreatedFromNavBar:[NavigationBarCatchingItem] = []
    
    /// Main app adapter
    lazy var adapter:ZPNavigationBarBaseAdapter = {
        return createAdapter()
    }()
    
    let customizationHelper = JerusalemNavigationBarCustomizationHelper()

    /// Retrieve currently used nav bar adapter
    ///
    /// Note: This method will return main adapter that is used for all application or  adapter of currently presented screen that was created from navigation bar. Each stack has own instance of the navigation bar adapter
    /// - Returns: Instance of the nav bar adapter that conforms ZPNavigationBarBaseAdapter
    @objc public class func navBarAdapter() -> ZPNavigationBarBaseAdapter {
//        if let customAdapter = GANavigationBarManager.sharedInstance.cachedScreenCreatedFromNavBar.last?.presentationScreen.navBarAdapter {
//            return customAdapter
//        }
        return JerusalemNavigationBarManager.sharedInstance.adapter
    }
    
    @objc public class func navBarAdapter(forViewController viewController:UIViewController) -> ZPNavigationBarBaseAdapter? {
        if let navigationController = viewController.navigationController as? ZPNavigationController {
            return navigationController.navigationBarManager as? ZPNavigationBarBaseAdapter
        }
        return nil
    }
    
    /// Retreive latest view controller presented from navigation bar
    ///
    /// - Returns: UIViewController instance
    @objc public func currentCachedViewController() -> UIViewController? {
        return cachedScreenCreatedFromNavBar.first?.latestViewController
    }
    
    /// Perform a presentation on the current inner navigation controller
    ///
    /// This function should be used only from the GAHelper as an extension of the presentation function.
    /// This function allowes to push a view controller to the correct inner navigation stack.
    /// - Returns: boolean value if the presentation was performed
    @objc open func presentViewController(_ viewController:UIViewController, forPresentationType presentationType:GARootHelper.GARootPresentationType, animated:Bool = false) ->  Bool {
        var retVal = false
        guard let firstItem = cachedScreenCreatedFromNavBar.first,
            let innerNavigationController = firstItem.innerNavigationController else {
            return retVal
        }
        
        switch presentationType {
        case .push:
            innerNavigationController.pushViewController(viewController, animated: animated)
            retVal = true
            break
        default:
            break
        }
        
        return retVal
    }
    
    /// Prepare navigation bar for usage
    ///
    /// - Parameters:
    ///   - customAdapter: Indicates if it is screen created from navagation bar and need to create new unique adapter
    ///   - completion: Completion handler
    public class func prepareNavBar(customAdapter:Bool = false,
                                    completion:(_ adapter:ZPNavigationBarBaseAdapter) -> Void) {
        let adapter = customAdapter ? JerusalemNavigationBarManager.sharedInstance.createAdapter() : navBarAdapter()
        adapter.prepareManager(customizationHelper: JerusalemNavigationBarManager.sharedInstance.customizationHelper) { (success) in
            completion(adapter)
        }
    }
  
    /// Create new instance of navigation bar plugins adapter
    ///
    /// - Returns: Instance of the ZPNavigationBarBaseAdapter
    func createAdapter() -> ZPNavigationBarBaseAdapter {
        // By default will be used Legacy adapter.
        var retVal:ZPNavigationBarBaseAdapter = JerusalemNavigationBarAdapter()

        //Check if UIBUilder enabled
        if GAFeaturesCustomizationHelper.isZappLayoutEnabled(),
            GAFeaturesCustomizationHelper.navBarUIBuilderApiEnabled() {
            if let homeScreenModel = ZLComponentsManager.homeScreenDataSource(),
                let menuModel = homeScreenModel.navigation(by: .navigationBar),
                let navigationType = menuModel.navigationType,
                let navBarAdapter = ZPNavigationBarPluginFactory.adapter(withIdentifier: navigationType) {
                retVal = navBarAdapter
                
                // Use default UIBuilder adapter
            } else {
                retVal = JerusalemNavigationBarAdapter()
            }
        }
        
        // Assign delegate to navigation bar adapter
        retVal.navBarManagerDelegate = JerusalemNavigationBarManager.sharedInstance
        
        return retVal
    }
    
    /// Present Screen from navigation bar
    ///
    /// - Parameters:
    ///   - genericViewController: instance view controller to present
    ///   - screenID: target screen ID
    ///   - urlString: data source URL String
    func present(genericViewController:UIViewController,
                 screenID:String?,
                 urlString:String?) {
        // Disable user interaction
//        adapter.navBarView?.isUserInteractionEnabled = false
//
//        // ZPNavigationController navigation Controller that will use to present new View Controller
//        let navController = ZPNavigationController(rootViewController: genericViewController,
//                                                   adapterDataSource: ZAZappAppManager.sharedInstance)
//
//        // Create instance of GARootViewContainerController that has avility to present nav bar plugin
//        let viewControllerToPresent = GARootViewContainerController(innerNavController: navController)
//        navController.navigationBarManager = viewControllerToPresent.navBarAdapter as? (ZPAdapterNavBarProtocol & ZPNavigationBarManagerProtocol)
//
//        /// Create new navigation caching item
//        let newCachedItem = NavigationBarCatchingItem(screenType: screenID,
//                                                      dataSourceURL: urlString,
//                                                      presentationScreen: viewControllerToPresent,
//                                                      rootViewController: genericViewController)
//
//        // Add caching item to caching list, remove instances of already existing items. We do not want to have on screen more than 1 same item
//        let itemsToRemove = addCacheItemToCacheList(toAdd: newCachedItem)
//
//        // Add new View Controller as child
//        GARootHelper.rootViewContainerController()?.addChildViewController(viewControllerToPresent,
//                                                                          to: GARootHelper.rootViewContainerController()?.view)
//
//        // Mimic animation of presentation of the view controller
//        let realSize = viewControllerToPresent.view.frame
//        viewControllerToPresent.view.frame.origin.y = realSize.origin.y + realSize.size.height
//        UIView.animate(withDuration: 0.3,
//                       delay: 0,
//                       options: .curveEaseOut,
//                       animations: {
//            viewControllerToPresent.view.frame = realSize
//        }) { [weak self] _ in
//            //Enable user interaction
//            self?.adapter.navBarView?.isUserInteractionEnabled = true
//            //Remove duplication screens
//            itemsToRemove.forEach { $0.presentationScreen.removeViewFromParentViewController()}
//        }
    }
    
    /// Remove screen that was presented from navigation bar
    ///
    /// - Parameters:
    ///   - viewControllerToRemove: View Controller instance that should be removed from screen
    ///   - completion: Completion handler
    func remove(viewControllerToRemove:UIViewController,
                completion:(()->Void)? = nil) {
        let realSize = viewControllerToRemove.view.frame

        UIView.animate(withDuration: 0.3,
                       animations: {
            viewControllerToRemove.view.frame.origin.y = realSize.origin.y + realSize.size.height
        }) { _ in
            viewControllerToRemove.removeViewFromParentViewController()
            completion?()
        }
    }
    
    /// Add caching items to list returning duplicates items
    ///
    /// - Parameter cachedItem: new cachedItem instance to add
    /// - Returns: Array of duplication items
    func addCacheItemToCacheList(toAdd cachedItem:NavigationBarCatchingItem) -> [NavigationBarCatchingItem] {
        // Retrive same screen items from currently cached instances
        let retVal = self.cachedScreenCreatedFromNavBar.filter { $0 == cachedItem }

        // Remove instances from list
        removeCacheItemFromCacheList(toRemove: cachedItem)
        
        // Add new cached item
        cachedScreenCreatedFromNavBar.append(cachedItem)
        
        // Return duplicates
        return retVal
    }
    
    /// Remove caching item from caching list
    ///
    /// - Parameter cachedItem: caching item to remove
    func removeCacheItemFromCacheList(toRemove cachedItem:NavigationBarCatchingItem) {
        let filteredArray = cachedScreenCreatedFromNavBar.filter { $0 != cachedItem }
        cachedScreenCreatedFromNavBar = filteredArray
    }
}

extension JerusalemNavigationBarManager {

    /// Check if back button was pushed from screen that was presented from navigation bar
    ///
    /// - Returns: True if back button was pushed from navigaiton bar, otherwise false
    public func userDidPushBackButtonFromPresentedScreen() -> Bool {
        if let lastViewController = cachedScreenCreatedFromNavBar.last?.presentationScreen,
            let navController = lastViewController.innerNavigationController {
            let count = navController.viewControllers.count
            if count - 2 >= 0 {
                let willPopToViewController = navController.viewControllers[count - 2]
                if let title = willPopToViewController.title {
                    JerusalemNavigationBarAnalyticsHelper.sendAnalyticsForBackButton(with: title)
                }
            }
            navController.popViewController(animated: true)
            return true
        }
        return false
    }
}

extension JerusalemNavigationBarManager: ZPNavigationBarViewDelegate {

    public func removeCachedItem(for viewController:UIViewController,
                                 completion:(()->Void)? = nil) -> Bool {
        if let rootViewContainerController = rootContainerViewController(by: viewController) {
            return removeCachedItem(for: rootViewContainerController,
                             completion: completion)
        }
        return false
    }
    
    public func removeCachedItem(for rootViewContainerController:GARootViewContainerController,
                                 completion:(()->Void)? = nil) -> Bool {
        var cachedItemToRemove:NavigationBarCatchingItem?
        
        for cacheItem in cachedScreenCreatedFromNavBar {
            if cacheItem.presentationScreen == rootViewContainerController {
                cachedItemToRemove = cacheItem
                break
            }
        }
        
        if let cachedItemToRemove = cachedItemToRemove {
            removeCacheItemFromCacheList(toRemove: cachedItemToRemove)
            remove(viewControllerToRemove: rootViewContainerController,
                   completion:completion)
        }
        
        return cachedItemToRemove != nil
    }
    
    func rootContainerViewController(by viewController:UIViewController) -> GARootViewContainerController? {
        //We are trying to check in navigation view controller if exist viewContorller to check to retrieve GARootViewContainerController that was created from nav bar
        for cashedModel in cachedScreenCreatedFromNavBar {
            if let innerNavigationController = cashedModel.innerNavigationController {
                for currentViewController in innerNavigationController.viewControllers {
                    if currentViewController == viewController {
                        return cashedModel.presentationScreen
                    }
                }
            }
        }
        return nil
    }
    
    public func removeTopCachedItem(completion:(()->Void)? = nil) {
        // Check if current screen, screen that was created from navigation bar
        if let cachedItemToRemove = cachedScreenCreatedFromNavBar.last,
            let lastViewController = cachedScreenCreatedFromNavBar.last?.presentationScreen {
            // Try to get screen that was created from navigation bar was placed on lower level. Example:   Root -> NavBarScreen(searched screen) -> NavBarScreen(planning to close)
            if cachedScreenCreatedFromNavBar.count - 2 >= 0 {
                let previousCachedItem = cachedScreenCreatedFromNavBar[cachedScreenCreatedFromNavBar.count - 2]
                let previousRootViewController = previousCachedItem.rootViewController
                if let title = previousRootViewController.title {
                    JerusalemNavigationBarAnalyticsHelper.sendAnalyticsForCloseButton(with: title)
                }
                // Lower screen is root
            } else if let title = GARootHelper.currentViewController()?.title {
                JerusalemNavigationBarAnalyticsHelper.sendAnalyticsForCloseButton(with: title)
            }
            
            removeCacheItemFromCacheList(toRemove: cachedItemToRemove)
            remove(viewControllerToRemove: lastViewController,
                   completion:completion)
        }
    }
    
    public func navigationBar(_ navigationBar: UIView,
                              buttonWasClicked:ZPNavBarButtonTypes,
                              senderButton:UIButton) {
        switch buttonWasClicked {
        case .close:
            let cachedItemToRemove = cachedScreenCreatedFromNavBar.last
            removeTopCachedItem()
            if let cachedItemToRemove = cachedItemToRemove,
                let viewController = cachedItemToRemove.latestViewController {
                notifyScreenPluginDidRemovedIfNeeded(viewController: viewController)
            }
        case .rightGroup,
             .leftGroup:
            if let senderButton = senderButton as? NavigationButton {
                self.proccesedNavButton(senderButton)
            }
        case .back:
            
            if userDidPushBackButtonFromPresentedScreen() == false,
                let currentViewController = GARootHelper.currentViewController() {
                
                if let count = currentViewController.navigationController?.viewControllers.count,
                    count - 2 >= 0,
                    let willPopToViewController = currentViewController.navigationController?.viewControllers[count - 2],
                    let title = willPopToViewController.title {
                    JerusalemNavigationBarAnalyticsHelper.sendAnalyticsForBackButton(with: title)
                }
//                GARootHelper.popViewControllerOfCurrentNavigationController()
                let webViewController = GARootHelper.currentViewController() as? GAWebViewController
                if webViewController == nil || webViewController?.tryToGoBack() == false {
                    if let viewController = GARootHelper.rootViewController() {
                        viewController.popViewController()
                    }
                }
                notifyScreenPluginDidRemovedIfNeeded(viewController: currentViewController)

            }
        case.special:
            JerusalemNavigationBarAnalyticsHelper.sendAnalyticsForSpecialButton(customizationHelper: customizationHelper)
//            GARootHelper.performSpecificRootAction(senderButton)
            if let viewController = GARootHelper.rootViewController() {
                viewController.performSpecialAction?(senderButton)
            }
        
        case.returnToHome:
            if let currentViewController = GARootHelper.currentViewController() {
                notifyScreenPluginDidRemovedIfNeeded(viewController: currentViewController)
            }
            
            if cachedScreenCreatedFromNavBar.isEmpty == false {
                if let lastViewController = cachedScreenCreatedFromNavBar.last?.presentationScreen {
                    var itemToRemoveWithoutNavigation = cachedScreenCreatedFromNavBar
                    itemToRemoveWithoutNavigation.removeLast()
                    cachedScreenCreatedFromNavBar = []
                    itemToRemoveWithoutNavigation.forEach { $0.presentationScreen.removeViewFromParentViewController()}
                    remove(viewControllerToRemove: lastViewController, completion: { [weak self] in 
                        JerusalemNavigationBarAnalyticsHelper.sendAnalyticsForHomeButton(customizationHelper: self?.customizationHelper)
//                        GARootHelper.navigateRootToHomeScreen()
                        if let viewController = GARootHelper.rootViewController() {
                            viewController.navigateToHomeScreen()
                        }
                    })
                }
            } else {
                JerusalemNavigationBarAnalyticsHelper.sendAnalyticsForHomeButton(customizationHelper: customizationHelper)
                if let viewController = GARootHelper.rootViewController() {
                    viewController.navigateToHomeScreen()
                }
//                GARootHelper.navigateRootToHomeScreen()
            }
        }
    }
    
    /// Try to notify screen plugin that it will be removed
    ///
    /// - Parameter viewController: viewContorller instance that posibly carry screen plugin
    func notifyScreenPluginDidRemovedIfNeeded(viewController:UIViewController) {
        
        guard let screenPluginVC = viewController as? GAScreenPluginGenericViewController else {
            return
        }
        
        screenPluginVC.viewControllerDidRemoved()
    }
}

extension JerusalemNavigationBarManager {
    
    /// Perform action after navigation button was push ed
    ///
    /// - Parameter button: NavigationButton instance
    func proccesedNavButton(_ button:NavigationButton) {
        JerusalemNavigationBarAnalyticsHelper.sendAnalytics(for: button)
        
        func performAction(model:NSObject?) {
            adapter.currentViewController?.performAction(forParentComponentModel: nil,
                                                         withModel: model,
                                                         componentModel: nil,
                                                         pushAfter: nil,
                                                         animated: true,
                                                         completion:nil)
        }
        
//        let model = button.model
//        if let model = model {
//            if let screenID = model.data.targetID {
//
//                var dataModel:NSObject?
//                if let dataSourceModel = ZLDataSourceHelper.model(from: model.dataSource) as? NSObject {
//                    dataModel = dataSourceModel
//                }
//
//                if let viewController =  GAViewControllerFactory.genericViewController(model.title,
//                                                                                       navigationFlowScreenName: screenID,
//                                                                                       model: dataModel) {
//                    GAScreenHookManager().performHook(hookedViewController:viewController,
//                                                      hookType: .screenPrehook,
//                                                      screenID: screenID,
//                                                      model: dataModel) { [unowned self] continueFlow in
//                                                        if continueFlow {
//
//                                                            self.present(genericViewController: viewController,
//                                                                         screenID: screenID,
//                                                                         urlString: model.data.dataSource?.source)
//                                                        }
//                    }
//                }
//
//            } else if let dataSourceModel = ZLDataSourceHelper.model(from: model.dataSource) as? NSObject {
//                performAction(model: dataSourceModel)
//            }  else {
//                switch model.type {
////                case .applicasterFeed:
//////                    GARootHelper.presentFeed()
////                case .applicasterCrossmates:
//////                    GARootHelper.presentCrossmates()
////                case .liveDrawer:
////                    GARootHelper.presentLiveDrawer()
//                case.chromecast:
//                    break
//                default:
//                    performAction(model: model)
//                }
//            }
//        }
    }
}

extension JerusalemNavigationBarManager: ZPNavigationBarManagerDelegate {
    
    /// Retrieve navigation button from model
    ///
    /// - Parameter model: model
    /// - Returns: UIButton instance if ca be created
    public func navigationButton(for model:NSObject) -> UIButton? {
        var retVal:UIButton?
        if let model = model as? ZLNavigationItem {
            retVal = NavigationButton(model:model)
            
            if ZAAppConnector.sharedInstance().genericDelegate.isDebug() {
                // Addition for automation purposes, The following defines an accessibility id for all nav bar items
                retVal?.accessibilityIdentifier = model.identifier
            }
            
            switch model.type {
            case.chromecast:
                retVal = ChromecastNavigationButton(model: model)
            default:break;
            }
        }
        return retVal
    }
    
    /// Ask root plugin, if it is using special button
    /// Note: speacial button informs root that some action was clicked
    ///
    /// - Returns: true if special  button handling was implemented on root plugin
    public func isSpecialButtonUsedByRoot() -> Bool {
        return GARootHelper.rootViewController()?.performSpecialAction != nil//GARootHelper.isSpecialButtonUsedByRoot()
    }
}
