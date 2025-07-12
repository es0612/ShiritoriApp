//
//  PlayerManagementView.swift
//  ShiritoriApp
//  
//  Created on 2025/07/13
//

import SwiftUI
import SwiftData
import ShiritoriCore

struct PlayerManagementWrapperView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        PlayerManagementView(onDismiss: {
            isPresented = false
        })
    }
}

#Preview {
    PlayerManagementWrapperView(isPresented: .constant(true))
}