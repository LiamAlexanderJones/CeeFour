//
//  ErrorHandler.swift
//  CeeFour
//
//  Created by Liam Jones on 01/04/2022.
//

import Foundation
import SwiftUI

enum ErrorSource {
  case empty
  case gameAlreadyExists
  case sendMove(column: Int)
  case sendRematchRequest
  case acceptRematchRequest
  case leaveGame
  case joinGame
  case createGame
  case signInAnon
}

struct ErrorHandler {
  
  var showErrorAlert = false
  var alertTitle = ""
  var alertMsg = ""
  var failure = ""
  var advice = "try restarting the app"
  var source = ErrorSource.empty
  
  //make it a static func that return an instance, and assign that in the file?
  mutating func handleError(_ error: Error, source: ErrorSource) {
    if let gameError = error as? GameError,
       gameError == .gameNotNil {
      
      alertTitle = "Game already exists"
      alertMsg = "CeeFour tried to create or join a game, but already has one on file. Remove the present game and try again."
      self.source = .gameAlreadyExists
      
    } else {
      
      self.source = source
      switch source {
      case .empty:
        print("Empty. This should never happen")
      case .gameAlreadyExists:
        print("GameAlreadyExists. This should never run.")
      case .sendMove(_):
        failure = "send your move"
        advice = "leave the game and start again"
      case .sendRematchRequest:
        failure = "send a rematch request"
        advice = "leave the game and start again"
      case .acceptRematchRequest:
        failure = "send your acceptance"
        advice = "leave the game and start again"
      case .leaveGame:
        failure = "remove you from the game"
      case .joinGame:
        failure = "join the game you asked for"
      case .createGame:
        failure = "create a game"
      case .signInAnon:
        failure = "sign you in"
      }
      alertTitle = "ConnectionError"
      alertMsg = "CeeFour couldn't \(failure). The error was \(error.localizedDescription). Ensure you have a connection and retry. If the problem persists, \(advice)."
 
    }
    showErrorAlert = true
  }
  
}


