//
//  ChromecastNavigationButton.swift
//  Zapp-App
//
//  Created by Anton Kononenko on 29/01/2018.
//  Copyright © 2018 Applicaster LTD. All rights reserved.
//

import Foundation
import ZappNavigationBarPluginsSDK
import ZappGeneralPluginsSDK
import ZappSDK

class ChromecastNavigationButton:NavigationButton {

    @objc var buttonView: UIView?
    public override init(model: ZLNavigationItem) {
        super.init(model:model)

        //The defualt value of icon color can be null, in that case the chromecast button will be white.
        if let stringColor = self.model?.style["icon_color"] as? String,
            let color = UIColor(argbHexString: stringColor) {
//            buttonView = GAChromecastManager.sharedInstance.addButton(container: self,
//                                                         topOffset: 0,
//                                                         width: frame.width,
//                                                         buttonKey: kChromecastIconColorKey,
//                                                         color: color,
//                                                         useConstrains: false)
        } else {
//            buttonView = GAChromecastManager.sharedInstance.addButton(container: self,
//                                                         topOffset: 0,
//                                                         width: frame.width,
//                                                         buttonKey: kChromecastIconColorKey,
//                                                         color: nil,
//                                                         useConstrains: false)
        }

        if buttonView != nil {
            addObserver(self, forKeyPath: #keyPath(buttonView.isHidden), options: [.old, .new], context: nil)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func prepareButton() {
        //Overriding default behaviour and not calling super
    }


    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(buttonView.isHidden),
            let buttonView = buttonView {
            // Update button visibility
            self.isHidden = buttonView.isHidden
        }
    }
}
