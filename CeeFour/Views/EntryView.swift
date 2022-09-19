//
//  GameListView.swift
//  CeeFour
//
//  Created by Liam Jones on 03/03/2022.
//

import SwiftUI
import FirebaseAuth

struct EntryView: View {
  
  @StateObject var entryViewModel = EntryViewModel()
  @State var joinCode = ""
  @State var isCreator = false
  
  @State var errorHandler = ErrorHandler()
  
  var body: some View {
    NavigationView {
      VStack {
        Text("Create or join a new game!")
          .bold()
        if entryViewModel.game == nil {
          
          if let message = entryViewModel.gameAlert?.rawValue {
            Text(message)
              .foregroundColor(.orange)
              .bold()
          }
          
          TextField("Enter joincode", text: $joinCode)
          Button("Join") {
            entryViewModel.listenForGames()
            isCreator = false
            Task {
              do {
                try await entryViewModel.joinGame(code: joinCode)
              } catch {
                errorHandler.handleError(error, source: .joinGame)
              }
            }
          }
          
          Divider()
          Button("Create") {
            entryViewModel.listenForGames()
            isCreator = true
            do {
              try entryViewModel.createGame()
            } catch {
                print("CREATE GAME ERROR")
              errorHandler.handleError(error, source: .createGame)
            }
          }
        } else {
          Text("Game in progress. This view should never be visible!")
        }
        
      }
      .alert(errorHandler.alertTitle, isPresented: $errorHandler.showErrorAlert, actions: {
        
        switch errorHandler.source {
        case .signInAnon:
          Button("Retry") {
            Task {
              do {
                try await Auth.auth().signInAnonymously()
              } catch {
                errorHandler.handleError(error, source: .signInAnon)
              }
            }
          }
        case .gameAlreadyExists:
          Button("Remove current game") {
            entryViewModel.game = nil
          }
        default:
          Button("OK") { }
        }
        
      }, message: {
        Text(errorHandler.alertMsg)
      })
      .navigationBarTitle("CeeFour")
      .task {
        do {
          try await Auth.auth().signInAnonymously()
        } catch {
          print("LOGIN ERROR: \(error)")
          errorHandler.handleError(error, source: .signInAnon)
        }
      }
    }
    .fullScreenCover(item: $entryViewModel.game) { game in
      GameView(game: game, isCreator: isCreator, entryViewModel: entryViewModel)
    }
  }
}

struct GameListView_Previews: PreviewProvider {
  static var previews: some View {
    EntryView()
  }
}
