//
//  TextFieldWithAccessory.swift
//  Neebla
//
//  Created by Christopher G Prince on 6/27/21.
//

import Foundation
import SwiftUI
import Combine

// Adapted from https://stackoverflow.com/questions/59114647

struct TextFieldOptions {
    let buttonTarget: Any?
    let buttonAction: Selector?
    weak var delegate: UITextFieldDelegate!
    let buttonEnabled: PassthroughSubject<Bool, Never>
}

struct TextFieldWithAccessory: UIViewRepresentable {
    var placeHolder: String
    var button:UIBarButtonItem!
    let options: TextFieldOptions
    var buttonEnabledSubscription:AnyCancellable!

    init(placeHolder: String, options: TextFieldOptions) {
        self.placeHolder = placeHolder
        self.options = options
        
        let button = UIBarButtonItem(title: "Add", style: UIBarButtonItem.Style.done, target: options.buttonTarget, action: options.buttonAction)
        buttonEnabledSubscription = options.buttonEnabled.sink { enabled in
            button.isEnabled = enabled
        }
        self.button = button
        button.isEnabled = false
    }
    
    func makeUIView(context: Context) -> UITextField {
        let toolbar = UIToolbar()
        toolbar.setItems([
                UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil
                ),
                button
            ],
            animated: true
        )
        toolbar.barStyle = UIBarStyle.default
        toolbar.sizeToFit()

        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        textField.inputAccessoryView = toolbar
        textField.placeholder = placeHolder
        textField.delegate = options.delegate

        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.endEditing(true)
        uiView.text = nil
    }
}

