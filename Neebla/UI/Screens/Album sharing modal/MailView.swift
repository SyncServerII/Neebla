//
//  SendInvitationView.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/29/20.
//

import SwiftUI
import UIKit
import MessageUI

// Adapted from https://stackoverflow.com/questions/56784722/swiftui-send-email

struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    @Binding var result: Result<MFMailComposeResult, Error>?
    let messageBody: String
    
    init(messageBody: String, result: Binding<Result<MFMailComposeResult, Error>?>) {
        self.messageBody = messageBody
        self._result = result
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let messageBody: String
        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(presentation: Binding<PresentationMode>,
             result: Binding<Result<MFMailComposeResult, Error>?>, messageBody: String) {
            _presentation = presentation
            _result = result
            self.messageBody = messageBody
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer {
                $presentation.wrappedValue.dismiss()
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: presentation, result: $result, messageBody: messageBody)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        
        vc.mailComposeDelegate = context.coordinator
        vc.setMessageBody(messageBody, isHTML: false)
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
        context: UIViewControllerRepresentableContext<MailView>) {
    }
}
