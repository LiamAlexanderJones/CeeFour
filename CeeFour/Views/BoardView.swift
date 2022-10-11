//
//  BoardView.swift
//  CeeFour
//
//  Created by Liam Jones on 24/02/2022.
//

import SwiftUI
import simd

struct BoardView: View {
  
  let gameID: String
  let width: CGFloat
  
  @ObservedObject var board: GameViewModel
  
  @State var dropHeight: CGFloat = -100
  @State var dropColumn: CGFloat = 0.0
  @State var dropColour = Disk.empty
  @State var obscured: (Int, Int) = (-1, -1)
  
  @Binding var errorHandler: ErrorHandler
  
  var body: some View {
    
    ZStack {
      
      Circle()
        .fill(dropColour)
        .offset(x: dropColumn, y: dropHeight)
        .frame(width: width / 7.5, height: width / 7.5)
      
      HStack(spacing: 0) {
        ForEach((0...6), id: \.self) { columnIndex in
          VStack(spacing: 0) {
            ForEach((0...5), id: \.self) { rowIndex in
              GridCellView(
                colour: obscured == (columnIndex, rowIndex)
                ? Disk.empty
                : board.grid[columnIndex][rowIndex],
                highlighted: board.winningPositions.contains(simd_short2(x: Int16(columnIndex), y: Int16(rowIndex)))
              )
            }
          }
          .onTapGesture {
            if board.winningPositions.isEmpty && board.playerTurn {
              let success = board.addDisk(colour: board.playerColour, to: columnIndex)
              if success {
                board.playerTurn = false
                Task {
                  do {
                    try await board.sendMove(column: columnIndex, gameID: gameID)
                  } catch {
                    errorHandler.handleError(error, source: .sendMove(column: columnIndex))
                  }
                }
              } else {
                print("Move failed!")
                //Alert the user that the move isn't legitimate
              }
            }
          }
        }
      }
      .padding(4)
      .border(Color(red: 0, green: 0, blue: 5), width: 4)
    }
    .onChange(of: board.lastMove) { move in
      animateDiskDrop(colour: board.lastMoveColour, column: Int(move.x), row: Int(move.y))
    }
    
  }
  
  
  func animateDiskDrop(colour: Color, column: Int, row: Int) {
    //Animating the disk drop relies on a bit of smoke and mirrors. When a disk is placed at a certain grid cell, it should change colour immediately. So what we do is hide that with obscured tuple,then animate a circle falling to that location. When it's time to animate the next move, we remove the circle and the obscured variable, and use them both again.
    obscured = (column, row)
    dropHeight = -3.5 * (width / 7)
    if column == -1 && row == -1 {
      //-1 signals replay. We hide the disk and return.
      dropColour = Disk.empty
      return
    }
    dropColour = colour
    let fall = (CGFloat(row) + 1) * (width / 7)
    let horizontalShift = (CGFloat(column) - 3) * (width / 7)

    dropColumn = horizontalShift
    withAnimation {
      dropHeight += fall
    }
  }

  
}


struct BoardView_Previews: PreviewProvider {
  static var previews: some View {
    BoardView(gameID: "id", width: 200.0, board: GameViewModel(), errorHandler: .constant(ErrorHandler()))
  }
}
