//
//  ShareViewController.swift
//  Share
//
//  Created by Christopher G Prince on 10/3/20.
//

import UIKit
import MobileCoreServices
import iOSShared
import iOSBasics
import SwiftUI
import iOSSignIn
import ServerShared

struct ShowAlert {
    let title: String
    let message: String
}

// https://medium.com/macoclock/ios-share-extension-swift-5-1-1606263746b
// https://stackoverflow.com/questions/40769387/getting-an-ios-share-action-extension-to-show-up-only-for-a-single-image
// https://diamantidis.github.io/2020/01/11/share-extension-custom-ui
// https://dmtopolog.com/ios-app-extensions-data-sharing/
// https://www.9spl.com/blog/build-share-extension-ios-using-swift/

// To make a custom UI: https://stackoverflow.com/questions/25922118 (The original superclass for ShareViewController was `SLComposeServiceViewController`).

// It looks like I need to declare what file types I can receive in the share extension:
// https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html#//apple_ref/doc/uid/TP40014214-CH21-SW8
// https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AppExtensionKeys.html
// https://stackoverflow.com/questions/38226283/ios-share-extension-not-working-on-image-urls

class ShareViewController: UIViewController {
    var hostingController:UIHostingController<SharingView>!
    var showAlert: ShowAlert?
    var viewModel = ShareViewModel()
    var viewHasAppeared = false
    let itemProviderFactory = ItemProviderFactory()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logger.info("viewDidLoad: ShareViewController")
        
        // Setup the view first so that we can show an error if neeed.
        setupView(viewModel: viewModel)
        
        viewModel.cancel = { [weak self] in
            self?.cancel()
        }
        
        guard setupServices() else {
            logger.error("Could not setup services")
            return
        }
        
        viewModel.setupAfterServicesInitialized()

        // Call `getSharedFile` before view appears because it may take some time to run.
        getSharedFile { [weak self] result in
            switch result {
            case .success(let itemProvider):
                DispatchQueue.main.async {
                    logger.debug("itemProvider: \(itemProvider)")
                    self?.viewModel.sharingItem = itemProvider
                }

            case .failure(let error):
                if let displayableError = error as? UserDisplayable,
                    let displayable = displayableError.userDisplayableMessage {
                    self?.showAlert(title: displayable.title, message: displayable.message)
                }
                else {
                    self?.showAlert(title: "Alert!", message: "Could not load item! Perhaps you selected more than one?")
                }
                
                logger.error("\(error)")
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        setViewModelSize(size: size)
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            if self.viewHasAppeared {
                Services.session.userEvents.alerty.send(
                    AlertyContents(AlertyHelper.alert(title: title, message: message)))
            }
            else {
                self.showAlert = ShowAlert(title: title, message: message)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let showAlert = showAlert {
            Services.session.userEvents.alerty.send(
                AlertyContents(AlertyHelper.alert(title: showAlert.title, message: showAlert.message)))
        }
        
        viewHasAppeared = true
    }
}

extension ShareViewController {
    func cancel() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    func done() {
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    func setupView(viewModel: ShareViewModel)  {
        setViewModelSize(size: view.frame.size)

        hostingController = UIHostingController(rootView: SharingView(viewModel: viewModel))
        addChild(hostingController)
        
        // Having problems not getting clipping when I do this from SwiftUI, so doing it here. See also https://stackoverflow.com/questions/57269651
        hostingController.view.layer.cornerRadius = 10
        hostingController.view.layer.masksToBounds = true
        hostingController.view.layer.borderWidth = 1
        
        let color: UIColor
        if traitCollection.userInterfaceStyle == .light {
            color = UIColor(white: 0.3, alpha: 1)
        } else {
            color = UIColor(white: 0.7, alpha: 1)
        }
        
        hostingController.view.layer.borderColor = color.cgColor
        
        view.addSubview(hostingController.view)
        addConstaints()
    }
    
    func setViewModelSize(size: CGSize) {
        if UIDevice.isPad {
            // Using a fixed size because I'm not getting good results on resizing. On iPad only?
            let modalSize = CGSize(width: 600, height: 700)
            viewModel.width = modalSize.width
            viewModel.height = modalSize.height
        }
        else {
            let widthProportion: CGFloat = 0.8
            let shortHeightProportion: CGFloat = widthProportion
            let tallHeightProportion: CGFloat = 0.7
            
            viewModel.width = size.width * widthProportion
            
            if size.height > size.width {
                viewModel.height = size.height * tallHeightProportion
            }
            else {
                viewModel.height = size.height * shortHeightProportion
            }
        }
    }
    
    func addConstaints() {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        hostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    
    // If false is returned an alert was given to the user.
    func setupServices() -> Bool {
        // If the sharing extension is used twice in a row, we oddly have a state where it's already been initialized. Get a crash on multiple initialization, so be careful.
        if Services.setupState == .none {
            Services.setup(delegate: nil)
        }
        
        if Services.setupState == .done(appLaunch: false) {
            Services.session.appLaunch(options: nil)
        }

        logger.info("Services.session.setupState: \(Services.setupState)")
        
        guard Services.setupState.isComplete else {
            logger.error("Services.session.setupState: \(Services.setupState)")
            showAlert(title: "Alert!", message: "Problem with setting up sharing.")
            return false
        }
                
        return true
    }

    enum HandleSharedFileError: Error {
        case noFiles
    }

    func getSharedFile(completion: @escaping (Result<SXItemProvider, Error>)->()) {
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        
        // As of 9/26/21, coincident with iOS 15, I'm finding that Quora will sometimes give the sharing extension > 1 item. I used to have a check here for exactly one attachment, but that's no longer appropriate.
        guard attachments.count > 0 else {
            completion(.failure(HandleSharedFileError.noFiles))
            return
        }

        let specs = attachments.map { ItemSpecification(assetIdentifier: nil, item: $0)}
        itemProviderFactory.create(using: specs, completion: completion)
    }
}

/*
Docs on Info.plist subqueries for indicating when the sharing extension should be active.
https://github.com/SyncServerII/Neebla/issues/3
 */

/* Another issue: When tap on some live photos and open the share extension, it immediately closes. Like it crashed. But the Photo's app doesn't crash. I'm seeing this in the console log:

default	19:08:17.662079-0700	MobileSlideShow	SLRemoteComposeViewController: (this may be harmless) viewServiceDidTerminateWithError: Error Domain=_UIViewServiceInterfaceErrorDomain Code=3 "(null)" UserInfo={Message=Service Connection Interrupted}
default	19:08:17.662122-0700	MobileSlideShow	viewServiceDidTerminateWithError:: Error Domain=_UIViewServiceInterfaceErrorDomain Code=3 "(null)" UserInfo={Message=Service Connection Interrupted}

A little before:

default	19:08:17.663129-0700	runningboardd	XPC connection invalidated: [xpcservice<biz.SpasticMuffin.SharedImages.Share([application<com.apple.mobileslideshow>:19084])>:19092]
default	19:08:17.663306-0700	nsurlsessiond	NDSession

And then a little later:

default	19:08:17.684577-0700	runningboardd	[xpcservice<biz.SpasticMuffin.SharedImages.Share([application<com.apple.mobileslideshow>:19084])>:19092] termination reported by launchd (1, 7, 9)

When I stop processing related to the NSItemProvider values, this problem goes away. There's some suggestion here: https://developer.apple.com/forums/thread/54456 that this is graphics related.

When I remove live image processing: Same deal. Crash.
When I stop rendering the icon with a still image: That fixes it. Looks related to rendering the icon image.
Is this related to scaling the image? When I stop scaling, the problem goes away.
    I have dealt with this by removing use of Toucan/resize-- that seems to be the issue.
*/
