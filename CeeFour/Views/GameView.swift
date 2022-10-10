//
//  GameView.swift
//  CeeFour
//
//  Created by Liam Jones on 01/03/2022.
//

import SwiftUI

struct GameView: View {
  
  let game: Game
  let isCreator: Bool
  @StateObject var board = GameViewModel()
  @ObservedObject var entryViewModel: EntryViewModel
  
  @State var errorHandler = ErrorHandler()
  
  
  var body: some View {
    GeometryReader { geo in
      VStack {
        if game.playerCount < 2 {
          Text(game.playerLeft
               ? "Your opponent left"
               : "Share this joinCode: \(game.joinCode)"
          )
        }
        
        ZStack {
          BoardView(gameID: game.id, width: geo.size.width - 20, board: board, errorHandler: $errorHandler)
            .padding(10)
            .frame(width: geo.size.width, height: geo.size.width * (6 / 7))
          
          if board.showRematchAlert {
            RematchAlertView(board: board, gameID: game.id)
            .frame(width: geo.size.width * 0.8)
            
          }
          
        }
        HStack {
          Text(String(board.winCount.red))
            .font(.largeTitle)
            .bold()
            .foregroundColor(Disk.red)
          Text(String(board.winCount.yellow))
            .font(.largeTitle)
            .bold()
            .foregroundColor(Disk.yellow)
        }

        Text(board.playerTurn ? "Player's Turn" : "Opponent's turn")
        
        if !board.winningPositions.isEmpty {
          Text("\(board.winColour == Disk.red ? "RED" : "YELLOW") WINS!")
            .font(.largeTitle)
            .bold()
            .foregroundColor(board.winColour)
          
          Button("Play again?", action: { rematchRequest(signal: 0) })
          .tint(.blue)
          .buttonStyle(.borderedProminent)
          .buttonBorderShape(.roundedRectangle)
        }

        Button("Leave Game", action: leave)
        .tint(.blue)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle)
        
      }
      .alert(errorHandler.alertTitle, isPresented: $errorHandler.showErrorAlert, actions: {
        Button("Retry") {
          switch errorHandler.source {
          case .empty: break
          case .sendMove(column: let column):
            Task {
              do {
                try await board.sendMove(column: column, gameID: game.id)
              } catch {
                //Is this nastily recursive?
                errorHandler.handleError(error, source: .sendMove(column: column))
              }
            }
          case .sendRematchRequest: rematchRequest(signal: 0)
          case .acceptRematchRequest: rematchRequest(signal: 1)
          case .leaveGame: leave()
          default: break
          }
        }
      }, message : {
        Text(errorHandler.alertMsg)
      })
      .onAppear {
        board.playerTurn = isCreator
        board.playerColour = isCreator ? Disk.red : Disk.yellow
        board.listenToBoard(gameID: game.id)
      }
    }
  }

  func rematchRequest(signal: Int) {
    Task {
      do {
        //try await board.sendRematchRequest(gameID: game.id)
        try await board.rematchRequest(gameID: game.id, signal: signal)
      } catch {
        print("REMATCH REQUEST ERROR: \(error)")
        if signal == 0 {
          errorHandler.handleError(error, source: .sendRematchRequest)
        } else if signal == 1 {
          errorHandler.handleError(error, source: .acceptRematchRequest)
        }
      }
    }
  }

  func leave() {
    board.listener?.remove()
    Task {
      do {
        try await entryViewModel.leaveGame()
        try await entryViewModel.clearEmptyGames()
      } catch {
        print("LEAVE GAME ERROR: \(error)")
        errorHandler.handleError(error, source: .leaveGame)
      }
    }
    entryViewModel.listener?.remove()
  }
  
  
  
}

struct GameView_Previews: PreviewProvider {
  static var previews: some View {
    GameView(game: Game(id: "hi", title: "hi", joinCode: 101010, playerCount: 1, playerLeft: false), isCreator: true, entryViewModel: EntryViewModel())
  }
}
