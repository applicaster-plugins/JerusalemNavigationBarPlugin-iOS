//
//  KanNavigationBarAnalyticsHelper.swift
//  Zapp-App
//
//  Created by Miri on 15/04/2019.
//  Copyright © 2018 Applicaster LTD. All rights reserved.
//

import Foundation
import ZappNavigationBarPluginsSDK
import ZappRootPluginsSDK
import ApplicasterSDK
import ZappSDK

class KanNavigationBarAnalyticsHelper {
    private struct Events {
        static let tapNavigationItem        = "Tap Navigation Item"
        static let tapNavigationHomeButton  = "Tap NavBar Home Button"
        static let tapNavigationBackButton  = "Tap NavBar Back Button"
        static let tapNavigationCloseButton = "Tap NavBar Close Button"
    }
    
    private struct Keys {
        static let navigationItemType  = "Navigation Item Types"
        static let screenProperties    = "Screen Properties"
        static let URL                 = "URL"
        static let iconFileURL         = "Icon file URL"
        static let logoFileURL         = "Logo file URL"
        static let rootPluginName      = "Root Navigation Plugin Name"
        static let returnTo            = "Return To"

        struct NavigationItemTypes {
            static let feed           = "Feed"
            static let crossmates     = "Crossmates"
            static let chromecast     = "Chromecast"
            static let liveDrawer     = "Live Drawer"
            static let screen         = "Screen"
            static let URL            = "URL"
            static let rootNavigation = "Root Navigation Plugin"
            static let undefined      = "Undefined"
        }
        
        struct ScreenProperties {
            static let screenName     = "Screen Name"
            static let screenId       = "Screen ID"
            static let feedProperties = "Feed Properies"
        }
        
        struct FeedProperties {
            static let dataProvider        = "Data Provider"
            static let dataType            = "Data Type"
            static let dataFeedUrl         = "Feed URL"
        }
 
    }
 
    class func sendAnalytics(for navigationButton:NavigationButton) {
        if let navigationItem = navigationButton.model {
            if let model = ZLDataSourceHelper.model(from: navigationItem.dataSource) as? APAtomEntryProtocol,
                model.entryType == .link {
                linkAnalytics(navigationButton: navigationButton,
                              model:model)
            } else if navigationItem.data.targetID != nil {
                screenAnalytics(navigationButton: navigationButton,
                                navigationItem: navigationItem)
            } else {
                let params = basicAnalyticParams(for: navigationButton)
                sendAnalyticsEvent(eventName: Events.tapNavigationItem,
                                   params: params)
            }
        }
    }
    
    class func sendAnalyticsForSpecialButton(customizationHelper:ZPNavigationBarCustomizationHelperDelegate?) {
        var params:[String: Any] = [Keys.navigationItemType: Keys.NavigationItemTypes.rootNavigation]
        
        if let rootPluginName = ZPRootPluginFactory.currentPluginModel()?.pluginName {
            params[Keys.rootPluginName] = rootPluginName
        }
        
        if let customizationHelper = customizationHelper,
            let imageURLString = customizationHelper.specialButtonImageURL() {
            params[Keys.iconFileURL] = imageURLString
        }
        sendAnalyticsEvent(eventName: Events.tapNavigationItem,
                           params: params)
    }
    
    
    class func sendAnalyticsForHomeButton(customizationHelper:ZPNavigationBarCustomizationHelperDelegate?) {
        var params:[String: Any] = [:]
        
        if let customizationHelper = customizationHelper,
            customizationHelper.presentationType() == .logo,
            let imageURLString = customizationHelper.logoImageURL() {
            params[Keys.logoFileURL] = imageURLString
        }
        sendAnalyticsEvent(eventName: Events.tapNavigationHomeButton,
                           params: params)
    }
    
    class func sendAnalyticsForBackButton(with screenTitle:String) {
        let params:[String: Any] = [Keys.returnTo:screenTitle]
        sendAnalyticsEvent(eventName: Events.tapNavigationBackButton,
                           params: params)
    }
    
    class func sendAnalyticsForCloseButton(with screenTitle:String) {
        let params:[String: Any] = [Keys.returnTo:screenTitle]
        sendAnalyticsEvent(eventName: Events.tapNavigationCloseButton,
                           params: params)
    }
    
    private class func linkAnalytics(navigationButton: NavigationButton,
                                     model:APAtomEntryProtocol) {
        var params = basicAnalyticParams(for: navigationButton)
        if let link = model.link {
            params[Keys.URL] = link
        }
        sendAnalyticsEvent(eventName: Events.tapNavigationItem,
                           params: params)
    }
    
    private class func screenAnalytics(navigationButton: NavigationButton,
                                       navigationItem: ZLNavigationItem) {
        var params = basicAnalyticParams(for: navigationButton)
        params[Keys.screenProperties] = screenAnalyticsParams(for: navigationItem)
        
        sendAnalyticsEvent(eventName: Events.tapNavigationItem,
                           params: params)
        
    }
    
    private class func screenAnalyticsParams(for navigationItem: ZLNavigationItem) -> [String: Any] {
        var retVal = [String: Any]()
        
        if let screenID = navigationItem.data.targetID {
            retVal[Keys.ScreenProperties.screenId] = screenID
            
            if let screenModel = ZLComponentsManager.screenComponentForScreenID(screenID) {
                retVal[Keys.ScreenProperties.screenName] = screenModel.name
            }
        }
        
        if let feedDict = feedAnalyticsParams(for: navigationItem) {
            retVal[Keys.ScreenProperties.feedProperties] = feedDict
        }
        return retVal
    }
    
    private class func feedAnalyticsParams(for navigationItem: ZLNavigationItem) -> [String: Any]? {
        
        guard let source = navigationItem.data.dataSource?.source,
            let type = navigationItem.data.dataSource?.type else {
                return nil
        }
        
        var retVal = [String: Any]()
        let url = URL(fileURLWithPath: source)
        retVal[Keys.FeedProperties.dataFeedUrl] = link
        retVal[Keys.FeedProperties.dataProvider] = url.host
        retVal[Keys.FeedProperties.dataType] = type
        
        return retVal
    }
    
    
    private class func basicAnalyticParams(for navigationButton: NavigationButton) -> [String: Any] {
        
        var retVal = [
            Keys.navigationItemType: navigationItemType(for: navigationButton)
        ]
        
        if let imageURLString = navigationButton.imageURLString {
            retVal[Keys.iconFileURL] = imageURLString
        }
  
        return retVal
    }
    
    private class func navigationItemType(for navigationButton: NavigationButton) -> String {
        var itemType = Keys.NavigationItemTypes.undefined

        guard let navigationItem = navigationButton.model else {
            APLoggerError("Navigation Button has no model")
            return itemType
        }
        
        switch navigationItem.type {
        case .applicasterFeed:
            itemType = Keys.NavigationItemTypes.feed
        case .applicasterCrossmates:
            itemType = Keys.NavigationItemTypes.crossmates
        case .liveDrawer:
            itemType = Keys.NavigationItemTypes.liveDrawer
        case .chromecast:
            itemType = Keys.NavigationItemTypes.chromecast
        default:
            if let model = ZLDataSourceHelper.model(from: navigationItem.dataSource) as? APAtomEntryProtocol,
                model.entryType == .link {
                itemType = Keys.NavigationItemTypes.URL
            } else if navigationItem.data.targetID != nil {
                itemType = Keys.NavigationItemTypes.screen
            }
        }
        return itemType
    }
    
    private class func sendAnalyticsEvent(eventName:String,
                                          params:[String: Any]) {
        if let analyticsDelegate = ZAAppConnector.sharedInstance().analyticsDelegate {
            analyticsDelegate.trackEvent(name: eventName,
                                         parameters: params)
        } else {
            APLoggerError("Analytics delegate does not exist")
        }
    }
    
}
