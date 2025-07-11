//
//  ContentView.swift
//  ShiritoriApp
//  
//  Created on 2025/07/11
//


import SwiftUI
import SwiftData

struct TitleView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("しりとりあそび")
                .font(.largeTitle)
                .fontWeight(.bold)

            Button(action: {
                // ボタンのアクション
            }) {
                Text("すたーと")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    TitleView()
}
