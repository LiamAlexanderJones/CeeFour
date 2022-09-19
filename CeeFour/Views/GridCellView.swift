//
//  GridCellView.swift
//  CeeFour
//
//  Created by Liam Jones on 01/03/2022.
//

import SwiftUI

struct GridCellView: View {
  
  var colour: Color
  var highlighted: Bool
  
  var body: some View {
    
    Color.blue
      .mask {
        ZStack {
          Rectangle()
          Circle()
            .padding(3)
            .blendMode(.destinationOut)
        }
      }
      .background(colour) // if LASTPOSITION, clear, otherwise colour
      .overlay(
        Circle()
          .fill( highlighted ? Color.white : Color.clear)
          .frame(width: 20, height: 20)
      )
    
  }
}

struct GridCellView_Previews: PreviewProvider {
  static var previews: some View {
    GridCellView(colour: Disk.red, highlighted: true)
  }
}
