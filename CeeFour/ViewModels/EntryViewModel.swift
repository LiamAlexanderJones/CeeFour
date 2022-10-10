//
//  GamesViewModel.swift
//  CeeFour
//
//  Created by Liam Jones on 03/03/2022.
//

import Foundation
import Firebase
import FirebaseAuth
//import FirebaseFirestoreSwift



enum GameAlert: String {
  case badJoinCode = "A join code needs six digits (and be greater than 100000)"
  case noGameForJoinCode = "There's no game with that join code."
  case gameFull = "That game is full"
  case deadGame = "That game is unavailable because a player has left"
}

enum GameError: Error {
  case userIsNil
  case gameNotNil
}

class EntryViewModel: ObservableObject {
  
  @Published var game: Game? = nil
  @Published var gameAlert: GameAlert? = nil
  
  private let database = Firestore.firestore()
  var listener: ListenerRegistration?

  //TODO: Make sure creategame checks in joincode already exists
  func createGame() throws {

    guard let user = Auth.auth().currentUser else { throw GameError.userIsNil }
    guard game == nil else { throw GameError.gameNotNil }
    database.collection("games")
      .addDocument(data: ["joinCode": Int.random(in: 100000...999999), "isRed": true, "moveColumn": -1, "users": [user.uid]]) { error in
        if let error = error {
          //TODO: Handle this error better
          print("Error adding document: \(error)")
        }
      }
  }
  
  @MainActor
  func joinGame(code: String) async throws {
    guard let user = Auth.auth().currentUser else { throw GameError.userIsNil }
    guard game == nil else { throw GameError.gameNotNil }
    guard let joinCode = Int(code),
    (100000...999999).contains(joinCode) else {
      gameAlert = .badJoinCode
      return
    }
    let snapshot = try await database.collection("games")
      .whereField("joinCode", isEqualTo: joinCode)
      .getDocuments()
    guard let document = snapshot.documents.first else {
      self.gameAlert = .noGameForJoinCode
      return
    }
    guard let users = document.data()["users"] as? [String] else { return } // TODO: What goes here?
    guard users.count < 2 else {
      self.gameAlert = .gameFull
      return
    }
    if let playerLeft = document.data()["playerLeft"] as? Bool, playerLeft {
      self.gameAlert = .deadGame
      return
    }
    try await self.database.collection("games")
      .document(document.documentID)
      .updateData(["users": FieldValue.arrayUnion([user.uid])])
  }
  
  //TODO: Leave the game if the app is closed?
  @MainActor
  func leaveGame() async throws {
    guard let user = Auth.auth().currentUser else { throw GameError.userIsNil }
    let snapshot = try await database.collection("games")
      .whereField("users", arrayContains: user.uid)
      .getDocuments()
    for document in snapshot.documents {
      try await self.database.collection("games")
        .document(document.documentID)
        .updateData(["users": FieldValue.arrayRemove([user.uid]), "playerLeft": true])
    }
    self.game = nil
  }

  func clearEmptyGames() async throws {
    let snapshot = try await database.collection("games")
      .getDocuments()
    for document in snapshot.documents {
      if let users = document.data()["users"] as? [String],
         users.isEmpty {
        try await self.database.collection("games")
          .document(document.documentID)
          .delete()
      }
    }
  }
  
  
  
  func listenForGames() {
    listener?.remove()
    guard let user = Auth.auth().currentUser else {
      print("listenForGames was called while user was nil. This should never happen")
      return
    }
    

    listener = database.collection("games")
      .whereField("users", arrayContains: user.uid)
      .addSnapshotListener(){ [weak self] (snapshot, error) in
        if let error = error {
          print("Error in listenForGames: \(error.localizedDescription)")
          return
        }
        guard let self = self else {
          print("listenForGames failed to weakly capture self")
          return
        }
        guard let documents = snapshot?.documents else {
          print("listenForGames found no documents")
          return
        }
        guard let document = documents.first else { return }
        
        let documentId = document.documentID
        let data = document.data()
        let title = data["title"] as? String ?? ""
        let joinCode = data["joinCode"] as? Int ?? -1
        let players = data["users"] as? [String] ?? []
        let playerCount = players.count
        let playerLeft = data["playerLeft"] as? Bool ?? false
        self.game = Game(id: documentId, title: title, joinCode: joinCode, playerCount: playerCount, playerLeft: playerLeft)
        self.gameAlert = nil
      }
  }
  
  
}

