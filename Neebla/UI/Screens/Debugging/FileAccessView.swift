//
//  FileAccessView.swift
//  iOSIntegration
//
//  Created by Christopher G Prince on 9/24/20.
//

import SwiftUI

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-dismiss-the-keyboard-for-a-textfield
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct FilesView: View {
    var body: some View {
        MenuNavBar(title: "File Access")  {
            FileAccessView()
        }
    }
}

struct FileAccessView: View {
    let serverInterface:ServerInterface = Services.session.serverInterface
    @State private var sharingGroupUUID: String?
    @State private var fileGroupUUID: String?
    @State private var newFileText: String?
    
    var body: some View {
        VStack {
            if Services.setupState.isComplete {
                InitialViews()
                
                Button(action: {
                    sharingGroupUUID = serverInterface.firstSharingGroupUUID?.uuidString
                }) {
                    Text("Get first sharing group")
                }

                TextField("Sharing Group UUID", text: $sharingGroupUUID ?? "")
                    .padding(10)
                    .multilineTextAlignment(TextAlignment.center)

                TextField("File Group UUID", text: $fileGroupUUID ?? "")
                    .padding(10)
                    .multilineTextAlignment(TextAlignment.center)

                SyncSharingGroupView(sharingGroupUUID: sharingGroupUUID)
                CreateSharingInvitationView(sharingGroupUUID: sharingGroupUUID)
                
                Text("Text for new file")
                TextEditor(text: $newFileText ?? "")
                    .foregroundColor(.black)
                    .border(Color.black)
                    .padding(10)
                
                UploadFileView(sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroupUUID, newFileText: newFileText)
                LargeUploads(sharingGroupUUID: sharingGroupUUID, failImmediatelyAfterStarting: true)
            }
            else {
                Text("Setup Failure!")
                    .background(Color.red)
            }
        }
    }
}

struct LargeUploads: View {
    let failImmediatelyAfterStarting: Bool
    let sharingGroupUUID:String?
    
    init(sharingGroupUUID:String?, failImmediatelyAfterStarting: Bool = false) {
        self.sharingGroupUUID = sharingGroupUUID
        self.failImmediatelyAfterStarting = failImmediatelyAfterStarting
    }
    
    var body: some View {
        VStack {
            UploadMultipleLargeFilesView(sharingGroupUUID: sharingGroupUUID, displayText: "Upload multiple large files")
            UploadMultipleLargeFilesView(sharingGroupUUID: sharingGroupUUID, failImmediatelyAfterStarting: true, displayText: "Upload multiple large files and fail.")
        }
    }
}

struct InitialViews: View {
    var body: some View {
        VStack {
            HideKeyboardView()
            Spacer()
            SyncView()
            SharingGroupsView()
        }
    }
}

struct CreateSharingInvitationView: View {
    let sharingGroupUUID: String?
    let serverInterface:ServerInterface = Services.session.serverInterface
    var body: some View {
        Button(action: {
            if let sharingGroupUUIDString = sharingGroupUUID,
                let sharingGroupUUID = UUID(uuidString: sharingGroupUUIDString) {
                serverInterface.createSharingInvitation(permission: .admin,  sharingGroupUUID:sharingGroupUUID, numberAcceptors:1, allowSharingAcceptance: true)
            }
        }) {
            Text("Create sharing invitation")
        }
    }
}

struct UploadMultipleLargeFilesView: View {
    let failImmediatelyAfterStarting: Bool
    let sharingGroupUUID:String?
    let displayText: String
    let serverInterface:ServerInterface = Services.session.serverInterface
    
    init(sharingGroupUUID:String?, failImmediatelyAfterStarting: Bool = false, displayText: String) {
        self.sharingGroupUUID = sharingGroupUUID
        self.failImmediatelyAfterStarting = failImmediatelyAfterStarting
        self.displayText = displayText
    }
    
    var body: some View {
        Button(action: {
            if let sharingGroupUUIDString = sharingGroupUUID,
                let sharingGroupUUID = UUID(uuidString: sharingGroupUUIDString) {
                //serverInterface.uploadMultipleImageFiles(sharingGroupUUID: sharingGroupUUID)
                if failImmediatelyAfterStarting {
                    fatalError()
                }
            }
        }) {
            Text(displayText)
        }
    }
}

struct UploadFileView: View {
    let sharingGroupUUID:String?
    let fileGroupUUID:String?
    let newFileText:String?
    let serverInterface:ServerInterface = Services.session.serverInterface
    
    var body: some View {
        Button(action: {
            var fileGroup:UUID?
            if let fileGroupUUIDString = fileGroupUUID {
                fileGroup = UUID(uuidString: fileGroupUUIDString)
            }
            
            if let sharingGroupUUIDString = sharingGroupUUID,
                let sharingGroupUUID = UUID(uuidString: sharingGroupUUIDString),
                let newFileText = newFileText {
                
                //serverInterface.uploadNewFile(sharingGroupUUID: sharingGroupUUID, fileGroupUUID: fileGroup, textForFile: newFileText)
            }
        }) {
            Text("Upload file")
        }
    }
}

struct SyncSharingGroupView: View {
    let sharingGroupUUID:String?
    let serverInterface:ServerInterface = Services.session.serverInterface
    var body: some View {
        Button(action: {
            if let sharingGroupUUIDString = sharingGroupUUID,
                let sharingGroupUUID = UUID(uuidString: sharingGroupUUIDString) {
                serverInterface.sync(sharingGroupUUID: sharingGroupUUID)
            }
        }) {
            Text("File index for sharing group")
        }
    }
}

struct HideKeyboardView: View {
    let serverInterface:ServerInterface = Services.session.serverInterface
    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                hideKeyboard()
            }) {
                Text("Dismiss Keyboard")
            }
        }
    }
}

struct SharingGroupsView: View {
    let serverInterface:ServerInterface = Services.session.serverInterface
    var body: some View {
        Button(action: {
            serverInterface.sharingGroups()
        }) {
            Text("Sharing Groups")
        }
    }
}

struct SyncView: View {
    let serverInterface:ServerInterface = Services.session.serverInterface
    var body: some View {
        Button(action: {
            serverInterface.sync()
        }) {
            Text("Sync")
        }
    }
}

// See https://stackoverflow.com/questions/57021722/swiftui-optional-textfield
func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
