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
          Button("Yes", action: { rematchRequest(signal: 1) })
            .tint(.green)
            .buttonStyle(.borderedProminent)
          Button("No", action: { rematchRequest(signal: -1) })
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
  
  func rematchRequest(signal: Int) {
    //Signal determines the request type. 0 makes a request, 1 accepts, -1 declines
    Task {
      do {
        try await board.rematchRequest(gameID: gameID, signal: signal)
      } catch {
        print("REMATCH REQUEST ERROR: \(error)")
      }
    }
  }
 
}

struct RematchAlertView_Previews: PreviewProvider {
  static var previews: some View {
    RematchAlertView(board: GameViewModel(), gameID: "ID")
  }
}
