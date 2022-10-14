# CeeFour
Allows two users to play Connect Four over the internet. Demonstrates use of SwiftUI and networking with Firebase.

To play, you need two devices. The first player creates the game from the landing screen, then shares the six digit game code with the second player. With the game code, the second player can then join the game.

As of September 2022, running this project will generate a warning of "Publishing changes from within view updates is not allowed, this will cause undefined behavior." This warning is being reported a great deal after the Xcode update, and may be an issue with Apple. Because it doesn't seem to impact functionality, I have chosen to leave it for the moment.
