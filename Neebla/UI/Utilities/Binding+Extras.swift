//
//  Binding+Extras.swift
//  Neebla
//
//  Created by Christopher G Prince on 11/15/20.
//

import Foundation
import SwiftUI

// See https://stackoverflow.com/questions/57021722/swiftui-optional-textfield
func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
