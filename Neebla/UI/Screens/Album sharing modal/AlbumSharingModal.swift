
import Foundation
import SwiftUI
import ServerShared
import RadioGroup
import iOSShared

struct AlbumSharingParameters {
    let invitationCode: UUID
    let sharingGroupName: String?
    let allowSocialAcceptance: Bool
    let permission: Permission
}

struct AlbumSharingModal: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    let albumName: String
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    
    // The completion is only called on a successful creation of an invitaton code. This is why a nil invitation code cannot passed.
    init(album: AlbumModel, completion:@escaping (_ parameters: AlbumSharingParameters)->()) {
        self.viewModel = AlbumSharingModalModel(album: album, completion: completion)
        albumName = album.albumName ?? AlbumModel.untitledAlbumName
    }
    
    var body: some View {
        VStack(spacing: 30) {
            ScreenButtons(viewModel: viewModel)
            Text("Invite others to '\(albumName)' album")
                .font(.title)
                
            ScrollView {
                VStack(spacing: 20) {
                    NumberOfPeople(viewModel: viewModel)
                    Divider()
                    PermissionPicker(viewModel: viewModel)
                    Divider()
                    AllowSocialAcceptance(viewModel: viewModel)
                    Divider()
                    ExpiryDuration(viewModel: viewModel)
                    Divider()
                    if let helpText = viewModel.helpString {
                        HelpInfo(helpStringHTML: helpText)
                    }
                }
            }
        }
        .padding([.leading, .trailing, .bottom], 10)
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
    }
}

private struct NumberOfPeople: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        HStack {
            Text("Number of people to invite:")
            Spacer()
        }
        
        HStack {
            Slider(value: $viewModel.numberOfPeopleToInviteRaw, in: 1...Float(ServerConstants.maxNumberSharingInvitationAcceptors))
                .padding(.leading, 10)
            Text("\($viewModel.numberOfPeopleToInvite.wrappedValue)")
                .padding(.leading, 20)
        }
    }
}

private struct ExpiryDuration: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        HStack {
            Text("Number of days before invitation expires:")
            Spacer()
        }
        
        HStack {
            Slider(value: $viewModel.expiryDurationDaysRaw, in: Float(AlbumSharingModalModel.minExpiryDurationDays)...Float(AlbumSharingModalModel.maxExpiryDurationDays))
                .padding(.leading, 10)
            Text("\($viewModel.expiryDurationDays.wrappedValue)")
                .padding(.leading, 20)
        }
    }
}

private struct HelpInfo: View {
    let helpStringHTML: String
    
    var body: some View {
        HStack {
            Text("What are you sharing?")
            Spacer()
        }
        
        HTMLViewer(html: helpStringHTML)
    }
}

private struct AllowSocialAcceptance: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        Toggle(isOn: $viewModel.allowSocialAcceptance, label: {
            Text("Allow social acceptance?")
        })
        .padding(.trailing, 5) // get clipping to right without this.
    }
}

private struct PermissionPicker: View {
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        HStack {
            Text("Permissions for people invited")
            Spacer()
        }

        HStack {
            RadioGroupPicker(
                selectedIndex: $viewModel.permissionSelection,
                titles: viewModel.displayablePermissionText
            ).spacing(5)
            
            .fixedSize()
            .padding(.leading, 20)
            
            Spacer()
        }
    }
}

private struct ScreenButtons: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: AlbumSharingModalModel
    
    var body: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
            })
            
            Spacer()
            
            Button(action: {
                viewModel.createInvitation()
            }, label: {
                Text("Invite")
            })
        }
    }
}
