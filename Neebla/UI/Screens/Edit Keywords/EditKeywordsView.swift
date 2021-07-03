//
//  EditKeywordsView.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/27/21.
//

import Foundation
import SwiftUI
import iOSShared

/*
I'm having problems with the "Add" button in the toolbar text field becoming disabled and not being re-enablable. This happens in one of two cases:
1) Either if I do a refetch of the model when the view appears and the model is updated.
2) Or when, if the keyword list is updated, then if the keyboard comes up, the "Add" button is again broken.
*/

struct EditKeywordsView: View {
    @Environment(\.presentationMode) var isPresented
    @StateObject var model:EditKeywordsModel
    @StateObject var alerty = AlertySubscriber(publisher: Services.session.userEvents)
    
    var body: some View {
        VStack {
            ZStack {
                TopView {
                   Button(action: {
                        isPresented.wrappedValue.dismiss()
                    }, label: {
                        SFSymbolIcon(symbol: .multiplyCircle)
                    })
                        
                    Spacer()
                }

                TopView {
                    Spacer()
                    Text("Edit Keywords")
                    Spacer()
                }
            }
            
            Spacer()
                .frame(height:20)
            
            List {
                Section(header: Text("Keywords for media item")) {
                    if model.keywords.count == 0 {
                        Text("There are none. Add some :)")
                            .foregroundColor(.yellow)
                    }
                    else {
                        ForEach(model.keywords, id: \.self) { keyword in
                            Text(keyword)
                        }
                        .onDelete(perform: model.delete)
                    }
                }

                Section(header: Text("Other keywords used in album")) {
                    if model.otherKeywords.count == 0 {
                        Text("There are none.")
                            .foregroundColor(.yellow)
                    }
                    else {
                        ForEach(model.otherKeywords, id: \.self) { keyword in
                            Button(action: {
                                model.addKeywordWithPrompt(keyword: keyword)
                            }) {
                                Text(keyword)
                            }
                        }.onDelete(perform: model.otherKeywordDelete)
                    }
                }
            }
            
            Spacer()
            
            TextFieldWithAccessory(placeHolder: "New keyword", model: model)
                .frame(height: 20) // view is too high otherwise.
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
        .onAppear() {
            DispatchQueue.main.async {
                self.model.reFetch()
            }
        }
    }
}
