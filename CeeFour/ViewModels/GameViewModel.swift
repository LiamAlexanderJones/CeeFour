//
//  Board.swift
//  CeeFour
//
//  Created by Liam Jones on 24/02/2022.
//

import Foundation
import SwiftUI
import simd

import Firebase
import FirebaseAuth

enum Disk {
  static let empty = Color.clear
  static let red = Color.red
  static let yellow = Color.yellow
}

class GameViewModel: ObservableObject {
  
  //Creates a grid of 7 columns and 6 rows. Disk state is grid[column][row]
  @Published var grid = Array(repeating: (Array(repeating: Disk.empty, count: 6)), count: 7)
  
  //Turn management
  @Published var playerTurn: Bool = true
  @Published var playerColour: Color = Disk.red
  @Published var lastMove: simd_short2 = simd_short2(x: -1, y: -1)
  @Published var lastMoveColour: Color = Disk.empty
  
  //Scorekeeping and replay management
  @Published var winningPositions: Set<simd_short2> = []
  @Published var winCount = (red: 0, yellow: 0)
  @Published var winColour: Color?
  @Published var showRematchAlert: Bool = false
  @Published var madeRequest: Bool = false
  @Published var rematchMsg = ""
  
  //Firebase properties
  private let database = Firestore.firestore()
  private let user = Auth.auth().currentUser
  var listener: ListenerRegistration?

  
  
  func addDisk(colour: Color, to column: Int) -> Bool {
    guard column < 7 else {
      print("Tried to add disk to nonexistent column")
      return false
    }
    guard let row = grid[column].lastIndex(of: Disk.empty) else {
      return false
    }
    grid[column][row] = colour
    lastMove = simd_short2(x: Int16(column), y: Int16(row))
    lastMoveColour = colour
    checkForWin(column: column, row: row, colour: colour)
    return true
  }
  
  func checkForWin(column: Int, row: Int, colour: Color) {
    var winningPositions: Set<simd_short2> = []
    var adjacents: Set<simd_short2> = []
    let position = simd_short2(x: Int16(column), y: Int16(row))
    [-1, 0, 1].forEach { i in [-1, 0, 1].forEach { j in
      //Throw away the origin, the directly vertical position, and anything off the board
      guard (i, j) != (0, 0),
            (i, j) != (0, -1),
            (0..<7).contains(column + i),
            (0..<6).contains(row + j),
            grid[column + i][row + j] == colour
      else { return }
      let a = simd_short2(x: Int16(i), y: Int16(j))
      
      if adjacents.contains(0 &- a) {
        //We have a triple. Check either side for final disk.
        [-2, 2].forEach { k in
          let fourth = position &+ (Int16(k) &* a)
          if (0..<7).contains(fourth.x) && (0..<6).contains(fourth.y) {
            if grid[Int(fourth.x)][Int(fourth.y)] == colour {
              winningPositions.formUnion([position &- a, position, position &+ a, fourth])
            }
          }
        }
      } else {
        //We have a double. Check in that direction.
        adjacents.insert(a)
        let fourth = position &+ (3 &* a)
        if (0..<7).contains(fourth.x) && (0..<6).contains(fourth.y) {
          let third = position &+ (2 &* a)
          if grid[Int(third.x)][Int(third.y)] == colour && grid[Int(fourth.x)][Int(fourth.y)] == colour {
            winningPositions.formUnion([position, position &+ a, third, fourth])
          }
        }
      }
  
    }}
    
    if !winningPositions.isEmpty {
      winColour = colour
      if colour == Disk.red {
        winCount.red += 1
      } else {
        winCount.yellow += 1
      }
    }
    self.winningPositions = winningPositions
  }
  
}


//MARK: -Networking methods-
extension GameViewModel {

  func sendMove(column: Int, gameID: String) async throws {
    guard user != nil else { throw GameError.userIsNil }
    try await database.collection("games").document(gameID)
      .updateData(["moveColumn": column, "isRed": (playerColour == Disk.red)])
  }
  
  func sendRematchRequest(gameID: String) async throws {
    //We signal the request with False and its acceptance with True
    //OR: 0 = request, 1 = accepted, -1 = declined
    guard user != nil else { throw GameError.userIsNil }
    madeRequest = true
    try await database.collection("games").document(gameID)
      .updateData(["rematchSignal": 0])
  }
  
  func acceptRematchRequest(gameID: String) async throws {
    //We signal the request with False and its acceptance with True
    guard user != nil else { throw GameError.userIsNil }
    try await database.collection("games").document(gameID)
      .updateData(["rematchSignal": 1])
  }
  
  func declineRematchRequest(gameID: String) async throws {
    guard user != nil else { throw GameError.userIsNil }
    try await database.collection("games").document(gameID)
      .updateData(["rematchSignal": -1])
  }
  

  func playAgain(gameID: String) {
    guard user != nil else { return } //Do soemthing better with this
    database.collection("games").document(gameID)
      .updateData(["isRed": (winColour == Disk.red), "moveColumn": -1, "rematchSignal": FieldValue.delete()]) { [weak self] error in
        guard let self = self else {
          print("PLAYAGAIN FAILED TO CAPTURE SELF")
          return
        }
        guard self.winColour != nil else {
          print("PLAYAGAIN COULD WITH NIL WINCOLOUR. THIS SHOULD NEVER HAPPEN")
          return
        }
        if let error = error { print("PLAYAGAIN ERROR: \(error)")}
        self.madeRequest = false
        self.rematchMsg = ""
        self.lastMove = simd_short2(x: -1, y: -1)
        self.playerTurn = (self.winColour == self.playerColour)
        self.grid = Array(repeating: (Array(repeating: Disk.empty, count: 6)), count: 7)
        self.winningPositions = []
        self.winColour = nil
        self.showRematchAlert = false
      }
  }
  
  func listenToBoard(gameID: String) {
    guard user != nil else { return }
    listener = database.collection("games").document(gameID)
      .addSnapshotListener { [weak self] snapshot, error in
        guard let self = self else {
          print("SnapshotListener couldn't capture self")
          return
        }
        guard let data = snapshot?.data() else {
          print("fetchMove couldn't fetch data")
          return
        }
        //Check for rematches first
        if let rematchSignal = data["rematchSignal"] as? Int {
          
          switch rematchSignal {
          case 1:
            self.playAgain(gameID: gameID)
          case -1:
            self.showRematchAlert = false
            self.rematchMsg = "Your opponent declined"
            self.showRematchAlert = self.madeRequest
            //doesn't work.
          default:
            self.rematchMsg = self.madeRequest ? "Waiting for your opponent to accept" : "Your opponent is inviting you to a rematch"
            self.showRematchAlert = true
          }
          
        } else {
        //If there's no match invitation, we listen for moves
          guard let isRed = data["isRed"] as? Bool else {
            print("fetchMove couldn't get isRed")
            return
          }
          let moveColour = isRed ? Disk.red : Disk.yellow
          guard self.playerColour != moveColour else { return }
          guard let moveColumn = data["moveColumn"] as? Int else {
            print("fetchMove couldn't get moveColumn")
            return
          }
          guard moveColumn != -1 else { return }
          guard self.winningPositions.isEmpty else { return }
          guard !self.playerTurn else { return }
          let success = self.addDisk(colour: moveColour, to: moveColumn)
          self.playerTurn = success
          if !success { print("Opponent move failed. This should never happen") }
        }
      }
  }
  
  
}


