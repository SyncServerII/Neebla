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

struct TextFieldWithAccessory: UIViewRepresentable {
    var placeHolder: String
    let model: EditKeywordsModel
    let textField: UITextField
    let button: UIBarButtonItem
    
    init(placeHolder: String, model: EditKeywordsModel) {
        self.placeHolder = placeHolder
        self.model = model
        textField = UITextField(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        button = UIBarButtonItem(title: "Add", style: UIBarButtonItem.Style.done, target: model, action: #selector(EditKeywordsModel.addButtonAction))
    }
    
    func makeUIView(context: Context) -> UITextField {
        // Using a frame as a workaround for some constraint breakage: See https://developer.apple.com/forums/thread/121474
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        toolbar.setItems([
                UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil
                ),
                button
            ],
            animated: true
        )
        toolbar.barStyle = UIBarStyle.default
        toolbar.sizeToFit()

        textField.inputAccessoryView = toolbar
        textField.placeholder = placeHolder
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.smartQuotesType = .no
        textField.smartDashesType = .no
        textField.smartInsertDeleteType = .no

        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.endEditing(true)
        uiView.text = nil
    }
    
    func makeCoordinator() -> Coordinator {
        let coord = Coordinator(model: model, button: button)
        self.textField.delegate = coord
        return coord
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let model: EditKeywordsModel
        let button: UIBarButtonItem
        
        init(model: EditKeywordsModel, button: UIBarButtonItem) {
            self.model = model
            self.button = button
        }
        
        // MARK: UITextFieldDelegate
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let enableAddButton = model.textField(textField, enableAddButtonWithCharactersIn: range, replacementString: string)
            button.isEnabled = enableAddButton
            return false
        }
        
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
            guard let text = textField.text else {
                button.isEnabled = false
                return true
            }
            
            button.isEnabled = text.count != 0
            return true
        }
    }
}
