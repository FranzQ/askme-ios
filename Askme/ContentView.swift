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
            
            VerificationsView()
                .tabItem {
                    Label("Verifications", systemImage: "checkmark.seal.fill")
                }
                .tag(2)
            
            LogoutView()
                .tabItem {
                    Label("Logout", systemImage: "arrow.right.square")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
}

