//
//  DevNotes.swift
//  CeeFour
//
//  Created by Liam Jones on 07/03/2022.
//

import Foundation

//You will probably want to make this a different file type later

//We send only the move's column number via firebase, and allow the app to keep its own model and calculate the move my by the opponent based on the column number. While this is slightly more demanding of processing, it allows us to keep the model (a nested array of colours) "in house" rather than picking it apart into Firebase collections. This future-proofs the app, should we decided to change from Firebase to another provider. The downside is, there is a potential for the two board models in a game to desycnhronise in a nonobvious way. It ma be useful to introduce bug checking for this possibility.


//To Do:
//General polish: Show correct error messages if joining doesn't work etc, show status of opponent.
//Add feature for draw (When tokens are full or if offered)




