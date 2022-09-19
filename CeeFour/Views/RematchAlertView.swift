//
//  RematchAlertView.swift
//  CeeFour
//
//  Created by Liam Jones on 12/04/2022.
//

import SwiftUI

struct RematchAlertView: View {
  
  @ObservedObject var board: GameViewModel
  let gameID: String
  
  var body: some View {
    VStack {
      Text(board.rematchMsg)
        .foregroundColor(.white)
        .bold()
      if !board.madeRequest {
        HStack {
          Button("Yes", action: rematchAccept)
            .tint(.green)
            .buttonStyle(.borderedProminent)
          Button("No", action: rematchDecline)
            .tint(.red)
            .buttonStyle(.borderedProminent)
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 15)
        .strokeBorder(Color.black, lineWidth: 4)
        .background(RoundedRectangle(cornerRadius: 15).fill(Color.init(red: 0, green: 0, blue: 139))
                   )
    )
  }
  
  
  
  func rematchAccept() {
    Task {
      do {
        try await board.acceptRematchRequest(gameID: gameID)
      } catch {
        print("ACCEPT REQUEST ERROR: \(error)")
        //errorHandler.handleError(error, source: .acceptRematchRequest)
      }
    }
  }
  
  func rematchDecline() {
    Task {
      do {
        try await board.declineRematchRequest(gameID: gameID)
      } catch {
        print("OOPS: \(error)")
      }
    }
  }
  
  
}

struct RematchAlertView_Previews: PreviewProvider {
  static var previews: some View {
    RematchAlertView(board: GameViewModel(), gameID: "ID")
  }
}
