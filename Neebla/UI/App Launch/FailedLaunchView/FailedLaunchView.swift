//
//  FailedLaunchView.swift
//  Neebla
//
//  Created by Christopher G Prince on 8/9/21.
//

import Foundation
import SwiftUI
import iOSShared

struct FailedLaunchView : View {
    @StateObject var model = FailedLaunchViewModel()
    @State var show: Bool = false
    
    var body: some View {
        VStack {
            Text("Neebla has failed to launch.")
                .font(.largeTitle)
            Button(action: {
                show = true
            }, label: {
                Text("Please send logs to the developer.")
            })
            .enabled(MailView.canSendMail)
        }
        .sheet(isPresented: $show) {
            MailView(emailContents: EmailDeveloper.developer, addAttachments: model, result: $model.sendMailResult)
        }
    }
}
