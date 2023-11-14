# PixeLAW Contracts
Contracts written in Cairo using Dojo to showcase a Pixel World with app interoperability. Its
interoperability is made possible with core actions. Apps are any other contracts that are deployed
to the Pixel World.

## Default Apps
These are apps developed by PixeLAW

## Paint

### Overview
The Paint App is a collection of functions that allow players to manipulate the color of a Pixel.

### Properties
None, Paint is just behavior.

### Behavior
- public put_color (color)
  - context: position
- both put_fading_color (color)
  - context: position
- public remove_color ()
  - context: position


## Snake

### Overview
It it basically the game "snake", but with Pixels not necessarily available to move on/over. It is a player-initialized instance that coordinates pixel's color and text being overriden and reverted (if allowed).
If hitting an unowned Pixel, the snake will move, if Pixel is owned by player, Snake grows, and if Pixel is not owned but it's App allows Snake, it shrinks. In all other cases, Snake dies.

### Properties
- position
- color
- text
- direction

### Behavior

- public spawn ( color, text, direction )
  - context: position
- public turn ( snake_id, direction )
  - context: player
- private move ( snake_id )



## Rock Paper Scissors

### Overview
Each Pixel can contain an instance of the RPS App, where it holds a commitment (rock, paper or scissors) from player1. Any other player can now "join" and submit their move. Player1 can then reveal, the winner is decided then. Winner gains ownership of the losing RPS pixel. In case of a draw, the pixel is reset.
The App is also tracking score for each Player.

### Global Properties
- player+wins

### Game-based Properties
- player1
- player2

### Behavior
- create (position, player1, commit1)
- join (position, player2, move2)
- finish (position, move1, salt1)
- reset (position)


## CommitReveal inputs
### Param of the action
- (Hashed Commit)
  - parametername of action has structure: "PREFIX_TYPE_NAME"
  - PREFIX is "cr_"
  - TYPE for now is the name of an int, felt or Enum declared in the manifest
  - NAME is a chosen name to refer to the param.
- (Value+Salt reveal)
  - parametername of action has structure: "PREFIX_NAME"
  - PREFIX shall always be "rv_"
  - NAME is the same name user during sending the commit
### Clientside functioning
- If client finds a param starting with "cr_"
- It will prompt user for a param with TYPE
  - example:
    - The game RPS needs player1 to choose one option, but only send the hashedcommit
    - Then, during a next stage of the game, the plaintext move and the salt will be requested
    - The challenge is that the UI needsto be capable of doing this without knowing about the specific application. Reveal/Commit is a feature of the platform.
    - Commit
      - RpsMove is an enum with 3 fields, so ui presents user with 3 choices
      - UI stores this clientside related to the pixel/app
      - UI then hashes this with a salt, and also stores the salt with the choice
      - UI then calls the functions with only the hash value
    - Reveal
      - there will be 2 params: "rv_NAME" (the actual param) and "rs_NAME" (the used salt)




