//
//  ContentView.swift
//  Askme
//
//  Created by Franz Quarshie on 11/22/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MyFieldsView()
                .tabItem {
                    Label("My Fields", systemImage: "person.fill")
                }
                .tag(0)
            
            RequestsView()
                .tabItem {
                    Label("Requests", systemImage: "bell.fill")
                }
                .tag(1)
            
            ShareView()
                .tabItem {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .tag(2)
            
            VerificationsView()
                .tabItem {
                    Label("Verifications", systemImage: "checkmark.seal.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}

