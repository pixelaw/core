# Pixelaw Contracts

Contracts written in Cairo using Dojo to showcase a Pixel World with app interoperability. Its interoperability is made possible with core actions. Apps are any other contracts that are deployed to the Pixel World.

## Prerequisites

- [asdf](https://asdf-vm.com/)
- [scarb](https://docs.swmansion.com/scarb/)
- [dojo](https://github.com/dojoengine/dojo)

### Install asdf

Follow the asdf installation instructions.

### Install dojo

```
asdf plugin add dojo https://github.com/dojoengine/asdf-dojo
asdf install dojo 1.7.0-alpha.0
```

### Install scarb

```
asdf plugin add scarb
asdf install scarb 2.7.0
```

And after moving into contracts directory, the versions for these libs are set in the `.tool-versions` file.

## Running Locally

**If you use vscode,**

#### 1. Run the katana and torii
just open this repo and press `⌘` + `⇧` + `B`

#### 2. Migrate contracts

```bash
sozo build --manifest-path Scarb_deploy.toml
sozo migrate apply --manifest-path Scarb_deploy.toml
scarb --manifest-path Scarb_deploy.toml run init_auth
```

**Otherwise,**

#### 1.Terminal one (Make sure this is running)

```bash
# Run Katana
katana --disable-fee --allowed-origins "*" --db-dir db/katana
```

#### 2. Terminal two

```bash
# Build the example
sozo build

# Migrate the example
sozo migrate apply

# Initialize the pixelaw app
scarb run init

# Start Torii
torii --world 0x263ae44e5414519a5c5a135cccaf3d9d7ee196d37e8de47a178da91f3de9b34 --allowed-origins "*" --database db/torii
```

## How to Deploy to Starknet

### Sepolia

1. Build

```zsh
sozo build --manifest-path Scarb_deploy.toml --profile sepolia
```

2. Migrate

```zsh
sozo migrate plan --account-address $YOUR_ACCOUNT_ADDRESS --private-key $YOUR_PRIVATE_KEY --profile sepolia --manifest-path Scarb_deploy.toml
```

3. Deploy

```zsh
sozo migrate apply --account-address $YOUR_ACCOUNT_ADDRESS --private-key $YOUR_PRIVATE_KEY --profile sepolia --manifest-path Scarb_deploy.toml
```

## Default Apps

These are apps developed by PixeLAW

## Paint

### Overview

The Paint App is a collection of functions that allow players to manipulate the color of a Pixel.

### Properties

None, Paint is just behavior.

### Behavior

- public `put_color(color)`
  - context: position
- both `put_fading_color(color)`
  - context: position
- public `remove_color()`
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

- public `spawn(color, text, direction)`
  - context: position
- public `turn(snake_id, direction)`
  - context: player
- private `move(snake_id)`

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
  - PREFIX is "cr\_"
  - TYPE for now is the name of an int, felt or Enum declared in the manifest
  - NAME is a chosen name to refer to the param.
- (Value+Salt reveal)
  - parametername of action has structure: "PREFIX_NAME"
  - PREFIX shall always be "rv\_"
  - NAME is the same name user during sending the commit

### Clientside functioning

- If client finds a param starting with "cr\_"
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
