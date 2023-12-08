# PixeLAW Game (test)
A game built on top of Dojo. See live example at <SECRET_URL: please reach out us on discord>.

This repository includes core components and systems. For more details, please check [PixeLAW Book](https://pixelaw.github.io/book/index.html).

## Concepts
- World : A Cartesian plane (2d grid), where every position represents a "Pixel"
- Pixel : One x/y Position, that has 6 primitive properties and one behavior template (App)
- App : A Pixel can have only one App that defines its behavior
- App2App : Interactions between Apps, where allowed
- Action : A specific behavior in the context of an App
- Queued Action : Action to be executed in the future, can be scheduled during an Action

## App Core Behavior (for owner)
- register : Register the App in the World
- unregister : Remove the App from the World
- allow_app
- disallow_app

## App Properties
- name
- permissions (bool hashmap of appname+property)

  
## Core Pixel Behavior
- **update_all**
- update_app
- update_color
- update_owner
- update_text
- update_alert
- update_timestamp

## Pixel Properties (every Pixel has these)
- position (cannot be changed)
- app
- color
- owner
- text
- alert
- timestamp


## Default App
- paint (put_color , remove_color)

## Checking Permissions
- Is calling Player the owner of the pixel -> they can do anything
- Is calling App allowed to update the Property?
- Problem
  - If scheduled, the calling App is CoreActions
  - How can we reliably check

## Scheduling Actions
- Can schedule anything through the Core.ScheduleAction function (?)
- This stores a hash onchain that will be removed once executed
- Core.ProcessScheduleAction takes the calldata and 
  - checks if the hash exists
  - checks if it's not too early 
- Upside
  - Onchain storage is minimized
- Problem
  - 



## Snake
- properties
  - direction
  - head_position
  - length?
- behavior
  - spawn
     - position
     - color
     - text
     - direction
     - 
  - move
    - 
       - handle_next_pixel
         - normal:
           - head moves to next 
           - rollback last
         - die
           - iterate all pixels and rollback
         - longer
           - head moves to next
         - shorter
           - head moves to next
           - rollback last 2
      - change_direction
## What if..
### Future actions are 1 per Pixel?

## Todo
- handle unregistered apps
- research feasibility of "hooks"
- Properly hook up process_queue so it is allowed to do player_id, but normal calls are not.



## Snake moves onto a non-owned Paint Pixel
- action: snake_move
- check pixel that will be occupied
  - call update_color on that pixel
  - is PaintApp allowing update_color from Snake?




## Prerequisites

-   Rust - install [here](https://www.rust-lang.org/tools/install)
-   Cairo language server - install [here](https://book.dojoengine.org/development/setup.html#3-setup-cairo-vscode-extension)
-   Dojo - install [here](https://book.dojoengine.org/getting-started/quick-start.html)
-   Scarb - install [here](https://docs.swmansion.com/scarb/download)
-   NodeJS - install [here](https://nodejs.org/en/download)

## Developing Locally

### Step 1: Build the contracts

```shell
make build
```

This command compiles your project and prepares it for execution.

### Step 2: Start Keiko
The Keiko is a container that has the [Katana RPC](https://book.dojoengine.org/framework/katana/overview.html),
the [Torii World Indexer](https://book.dojoengine.org/framework/torii/overview.html), and a Dashboard. Once the container starts, it starts running Katana, deploys the World Container from the repo
via the contracts volume (See the docker-compose.yml for more details), runs the post_deploy script from
the repo's Scarb.toml, and starts up Torii. Keiko Dashboard is accesible via http://localhost:3000/fork.

```shell
make start_keiko
```

### Step 3: Get the React frontend ready

```shell
make prep_web
cd web
yarn
```

### Step 4: Run the frontend locally

```shell
cd web
yarn dev
```

### Step 5: Run the queue bot
````shell
cd bots
yarn install
yarn dev
````
- to run here, you can check this page: https://www.npmjs.com/package/canvas
- the following command might fix your issue.
````shell
brew install pkg-config cairo pango libpng jpeg giflib librsvg pixman
````

#### NOTE
To change accounts, add an account query to the frontend url. For example: http://localhost:3000/?account=1. Add
as many accounts as desired by following the pattern set in the env.example.

The following would be example players:
````console
# for player 1
http://localhost:5173/?account=1
# for player 2
http://localhost:5173/?account=2
````

## Project Structure 
This is an overview of the most important folders/files:
- `Makefile` : A collection of helpful commands, mainly for Dojo
- `contracts` : The Dojo Cairo smart contract code
  - `src/components.cairo` : Dojo component definitions
  - `src/systems.cairo` : Dojo component definitions
  - `src/Scarb.toml` : The scarb config file used for katana
- `web` : A [Vite](https://vitejs.dev/) React project 
  - `.env` : (copied from env.example) Contains the hardcoded developer addresses used for Dojo
  - `src/dojo/contractComponents.ts` : Client-side definitions of the components
  - `src/dojo/createClientComponents.ts` : Client-side setup of the components
  - `src/dojo/createSystemCalls.ts` : Client-side definitions of the systems

## Typical development activities
### Add a DOJO system
- Edit `src/systems.cairo` 
- Edit `src/dojo/createSystemCalls.ts`
### Add a DOJO component
- Edit `src/components.cairo`
- Edit `src/dojo/contractComponents.ts`
- Edit `src/dojo/createClientComponents.ts`
### Redeploy to Katana
- Restart Katana
- Redeploy the contracts with `cd contracts && scarb run deploy`

## Troubleshooting / Tricks
### When using vscode, the cairo language server panics with `thread 'main' panicked at 'internal error: entered unreachable code: `
Resolution: None, this is a know issue, can ignore

### When deploying/migrating, consistent exceptions even though the contract compiles.
Resolution: Delete the `contracts/target` dir

### How do I use different accounts while testing?
Register 2 accounts (example from https://github.com/coostendorp/dojo-rps): 
```
let player1 = starknet::contract_address_const::<0x1337>();
let player2 = starknet::contract_address_const::<0x1338>();
```
And then switch accounts like this:
```
starknet::testing::set_contract_address(player1);
```
