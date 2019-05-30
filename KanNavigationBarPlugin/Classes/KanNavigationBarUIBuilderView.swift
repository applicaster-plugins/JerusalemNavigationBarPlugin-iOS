//
//  NavigationBarUIBuilderView.swift
//  Zapp-App
//
//  Created by Anton Kononenko on 15/12/2017.
//  Copyright © 2017 Applicaster LTD. All rights reserved.
//

import Foundation
import ZappPlugins
import ZappNavigationBarPluginsSDK
import ApplicasterSDK
import ZappSDK

public class KanNavigationBarUIBuilderView: UIView, ZPNavigationBarUIBuilderProtocol {
    
    public struct AnimationKeys {
        static let animationDurationForMakeButtonsVisible = 0.4
        static let animationDurationForMakeButtonsHidden  = 0.2
        static let animationDurationForMakeTitleHidden    = 0.2
        static let hideSpecialContainer                   = 0.2
    }
    
    public let navigationButtonsWidth:CGFloat    = 38.0

    public weak var delegate: ZPNavigationBarViewDelegate?
    public var modelUrlPath: NSURL?

    @IBOutlet weak var mainStackView: UIStackView!

    @IBOutlet open weak var specialButton: NavigationButton?
    @IBOutlet open weak var backButton: NavigationButton?
    @IBOutlet open weak var closeButton: NavigationButton?

    @IBOutlet open weak var shareButton: CAButton?

    @IBOutlet open weak var homeButton: NavigationButton?
    @IBOutlet open weak var specialButtonsContainer: UIView!
    @IBOutlet weak var specialContainerDummyView:UIView?
    
    @IBOutlet open weak var rightButtonsStackView:UIStackView?
    @IBOutlet weak var rightButtonDummyView:UIView?
    
    @IBInspectable var rightNavButtonLimitIPhone: Int = 3
    @IBInspectable var rightNavButtonLimitIPad  : Int = 3
  
    var rightNavButtonsLimit:Int {
        return UIScreen.main.traitCollection.userInterfaceIdiom == .phone ? rightNavButtonLimitIPhone : rightNavButtonLimitIPad
    }
    
    @IBOutlet open weak var logoImageView: ZPImageView?
    @IBOutlet open var backgroundImageView: ZPImageView?
    
    @IBOutlet  open var titleLabel: UILabel?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func awakeFromNib() {
        if let rightButtonDummyView = rightButtonDummyView {
            rightButtonDummyView.isHidden = false
        } else {
            rightButtonsStackView?.isHidden = true
        }
        
    }
    
    open var rightMenuButtons : [NavigationButton] = []
        {
        didSet {

        }
    }
    
    public func updateSpecialButtonsContainer(backButtonHidden:Bool,
                                       specialButtonHidden:Bool,
                                       closeButtonHidden:Bool) {
        backButton?.isHidden = backButtonHidden
        specialButton?.isHidden = specialButtonHidden
        closeButton?.isHidden = closeButtonHidden
        let allButtonsHidden = backButtonHidden == true && specialButtonHidden == true && closeButtonHidden == true
        let specialButtonContainerIsHidden = allButtonsHidden && specialContainerDummyView == nil
        specialContainerDummyView?.isHidden = !allButtonsHidden
        if self.specialButtonsContainer.isHidden != specialButtonContainerIsHidden {
            UIView.animate(withDuration: AnimationKeys.hideSpecialContainer) { [weak self] in
                self?.specialButtonsContainer.isHidden = specialButtonContainerIsHidden
            }
        }
    }

    open func resetNavBar(_ buttonsCollection:[NavigationButton]) {
        buttonsCollection.forEach { (button) in
            button.setImage(nil, for: .normal)
            button.setImage(nil, for: .highlighted)
            button.setImage(nil, for: .selected)
            button.setImage(nil, for: .disabled)
            button.isHidden = true
        }
    }
    
    //MARK: Actions
    @IBAction open func handleUserPushCloseButton(_ sender: NavigationButton) {
        delegate?.navigationBar(self, buttonWasClicked: .close, senderButton: sender)
    }
    
    @IBAction open func handleUserPushSpecialButton(_ sender: NavigationButton) {
        delegate?.navigationBar(self, buttonWasClicked: .special, senderButton: sender)
    }
    
    @IBAction open func handleUserBackButton(_ sender: NavigationButton) {
        delegate?.navigationBar(self, buttonWasClicked: .back, senderButton: sender)
    }
    
    @IBAction open func handleUserHomeButton(_ sender: NavigationButton) {
        delegate?.navigationBar(self, buttonWasClicked: .returnToHome, senderButton: sender)
    }
    
    @objc open func handleUserPushGroupButtons(_ sender: NavigationButton) {

    }
    
    @IBAction func handleShareButtonTapped(_ sender:CAButton) {
        guard let modelUrlPath = self.modelUrlPath,
            let newAtomEntry = APAtomEntry.linkEntry(withURLString: modelUrlPath.absoluteString) else {
            return
        }
        
        //for debug usage
        //print("KAN share Link before change: " + newAtomEntry.link)
        guard var urlComponents = URLComponents(string: newAtomEntry.link) else {
            return
        }
        
        if let queryItems = urlComponents.queryItems {
            //For VIMI content we filter catId and for KAN content by itemId
            if let queryItem = queryItems.filter({$0.name == "itemId" || $0.name == "catId"}).first {
                urlComponents.queryItems = [queryItem]
            }
        }
        
        newAtomEntry.link = urlComponents.string
        newAtomEntry.title = " "
        //for debug usage
        //print("KAN share Link after change: " + newUrlString)
        
         APSocialSharingManager.sharedInstance().shareWithDefaultText(withModel: newAtomEntry, andSharingType: APSharingViaNativeType)
    }
    
    //MARK: Helpers
    
    func buttonInGroupOfButtons(_ button:NavigationButton, inButtonsGroup buttonsGroup:[NavigationButton]?) -> Bool {
        var retVal = false
        if let unwrappedButtonsGroup = buttonsGroup {
            for currentButton in unwrappedButtonsGroup {
                if button == currentButton {
                    retVal = true
                    break
                }
            }
        }
        return retVal
    }
}


