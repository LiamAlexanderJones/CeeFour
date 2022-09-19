//
//  Game.swift
//  CeeFour
//
//  Created by Liam Jones on 12/04/2022.
//

import Foundation

struct Game: Codable, Identifiable {
  var id: String
  var title: String
  var joinCode: Int
  var playerCount: Int
  var playerLeft: Bool
}
