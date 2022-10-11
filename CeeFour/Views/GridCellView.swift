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
            .padding(4)
            .blendMode(.destinationOut)
        }
      }
      .background(colour)
      .overlay(
        ZStack {
          Circle()
            .stroke(lineWidth: 4)
            .foregroundColor(Color(red: 0, green: 0, blue: 5))
            .padding(4)
          Image(systemName: "star.fill")
            .foregroundColor(highlighted ? Color.white : Color.clear)
            .frame(width: 20, height: 20)
        }
      )
    
  }
}

struct GridCellView_Previews: PreviewProvider {
  static var previews: some View {
    GridCellView(colour: Disk.red, highlighted: true)
  }
}
