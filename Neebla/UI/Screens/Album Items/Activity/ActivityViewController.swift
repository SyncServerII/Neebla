//
//  ActivityViewController.swift
//  Neebla
//
//  Created by Christopher G Prince on 12/30/20.
//

import UIKit
import SwiftUI

// `activityItems` can be UIImage, web URL, a PDF (local) URL, or string
// See https://nshipster.com/uiactivityviewcontroller/

struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {
    }
}
