//
//  CeeFourApp.swift
//  CeeFour
//
//  Created by Liam Jones on 24/02/2022.
//

import SwiftUI
import Firebase

@main
struct CeeFourApp: App {
  
  init() {
    FirebaseApp.configure()
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
