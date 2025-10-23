//
//  ContentView.swift
//  SnowMateWatch Watch App
//
//  Created by 이혜빈 on 10/24/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.snowboarding")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("SnowMate")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
