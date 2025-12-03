//
//  ContentView.swift
//  PlantBuddy
//
//  Created by Jasmine Zhang on 2/19/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    
    var body: some View {
        TabView {
            MyJungleView()
                .tabItem {
                    Image(systemName: "leaf.fill")
                    Text("My Jungle")
                }

            CareView()
                .tabItem {
                    Image(systemName: "drop.fill")
                    Text("Care")
                }

            ToolsView()
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver")
                    Text("Tools")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
        }
        .background(Color.appBackground.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
