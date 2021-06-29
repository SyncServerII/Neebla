//
//  EditKeywordsView.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/27/21.
//

import Foundation
import SwiftUI
import iOSShared

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

                Section(header: Text("Other keywords")) {
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
                        }
                    }
                }
            }
            
            Spacer()
            
            TextFieldWithAccessory(placeHolder: "New keyword", options: model.textFieldOptions)
                .frame(height: 20) // view is too high otherwise.
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
        .alertyDisplayer(show: $alerty.show, subscriber: alerty)
    }
}
