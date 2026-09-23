# Car Dress Up (Roblox)

A car-themed dress-up game for Roblox, built like *Dress to Impress* but with cars.
Players pick a car, customise it for 5 minutes, present it on a stage while everyone
else rates it from 1 to 5 stars, and the top 3 end up on the podium.

The whole game is code. The map, the lighting, every car and all the UI are made at
runtime from Luau, so you don't need to import any models, meshes or decals.

## Match flow

| Phase | Length | What happens |
|---|---|---|
| Lobby | until enough players | Waits for 2 players (1 when you test in Studio). |
| Intermission | 15 s | Countdown. |
| Customize | 5 min | Up to 10 players each get a garage bay and a car. A random theme is shown (e.g. *Lowrider King*, *Drift Missile*). If everyone presses **Ready**, the timer drops to 10 s. |
| Showcase | 18 s per car | Cars go on stage one at a time in random order. The car drives in, then opens its doors, hood and trunk, does a hydraulic dance if it has hydraulics, and ends with a burnout. Everyone else rates it 1 to 5 stars. The owner gets buttons to show the car off. |
| Results | 20 s | The top 3 cars are parked on the podium with confetti, and a standings panel lists every car's average rating. 1st place gets +1 **Wins** on the leaderboard. |

All timings are in `src/shared/Config.luau`.

## Customisation

| Category | Options |
|---|---|
| **Car** | Street Coupe, Muscle Car, Supercar, Hot Hatch, Classic Cruiser |
| **Body Kit** | Front bumpers (lip, splitter, canards, bull bar), rear bumpers (diffuser, quad exhaust, race diffuser), side skirts / mud flaps, spoilers (lip, ducktail, GT wing, swan neck, drag wing), hoods (vented, carbon, scoop, supercharger blower), roof scoop / vortex generators / roof wing / light bar, bolt-on flares or a full widebody |
| **Lights** | Headlights (angel eyes, LED strip, quad round, pop-ups) with a tint colour, taillights (full-width bar, round quad, tri-bar, smoked), side mirrors (aero, carbon stalk, JDM fender, chrome bullet) |
| **Paint** | Base coat from a 24-colour palette, finish (gloss, matte, satin, metallic, pearl, chrome wrap), window tint, brake caliper colour, engine colour |
| **Vinyls** | 3 stackable layers, each with its own colour: racing stripes, side stripe, two-tone, fade, flames, slash, checkered, camo, pinstripes, sponsor decals, race number |
| **Wheels** | Rims (stock, five spoke, deep dish, mesh, turbofan, **spinners**, beadlock), rim colour, tyres (street, low profile, off-road, whitewall, drag slicks), **tyre smoke colour** |
| **Audio** | Trunk setups from a single sub up to a wall of subs, with amps on the underside of the trunk lid and accent neon. The sub cones pump while the trunk is open. |
| **Neon** | Underglow and interior neon, each off, solid or pulsing, with its own colour |
| **Performance** | Suspension: lowered, slammed, lifted or **hydraulics** (the car hops and dances) |
| **Doors** | Stock, **scissor**, **Lambo**, butterfly, gullwing. All of them open for real. |

While building, the **Preview** buttons let you open the doors, hood and trunk, hit the
hydraulic switches, or do a burnout on your own car. Only you see the preview.

## Project layout

```
src/
  shared/                 -> ReplicatedStorage.Shared
    Config.luau           timings, themes, map layout, rate limits
    Catalog.luau          cars, slots, options, colour palette, validation
    Net.luau              RemoteEvents / RemoteFunction definitions
  server/                 -> ServerScriptService.Server
    init.server.luau      entry point
    MatchService.luau     phase loop, build validation, ratings, showcase, podium
    MapBuilder.luau       lobby, 10 garage bays, stage, podium, lighting
    CarBuilder/           procedural car construction
      init.luau           layout maths + assembly
      Body.luau           shell, glasshouse, hood/trunk/door hinges, interior
      Kits.luau           bumpers, skirts, spoilers, hood/roof add-ons, lights, mirrors
      Wheels.luau         tyres, rims, spinners, brakes, tyre smoke
      Extras.luau         engine, subs/amps, hydraulics, neon
      Vinyls.luau         SurfaceGui vinyl layers + racing stripes
      Util.luau           part/joint helpers
  client/                 -> StarterPlayer.StarterPlayerScripts.Client
    init.client.luau      entry point
    Store.luau            client copy of match state + own build
    CarAnimator.luau      animates doors, wheels, spinners, subs, hydraulics, smoke, neon
    CameraController.luau orbit cameras for garage / stage / podium
    Hud.luau              timer, phase, theme, toasts
    CustomizeMenu.luau    category tabs, options, swatches, preview, Ready
    ShowcaseMenu.luau     star rating / show-off controls
    ResultsMenu.luau      final standings
```

## How it works

- **Cars are one animated assembly.** Each car has an anchored, invisible `Root`. Every
  other part is welded to it or joined with a `Motor6D`: suspension, door, hood and trunk
  hinges, wheel hubs, spinners and sub cones. The server builds the car and sets attributes
  such as `DoorsOpen`, `Bounce` and `Burnout`. Each client animates the motors locally
  through `Motor6D.Transform`, so the animation is smooth and nothing is sent over the
  network per frame.
- **Vinyls wrap across panels.** Every side panel, doors included, gets a `SurfaceGui`
  that shows its part of one shared canvas covering the whole side of the car. Designs
  therefore line up across panel gaps, and a door keeps its part of the design when it
  opens.
- **The server is authoritative.** Every build edit is checked against `Catalog` and
  rate-limited. Ratings are accepted only for the car currently on stage, never for your
  own car, and only as whole stars from 1 to 5.

## Getting started

You need [Rojo](https://rojo.space) 7.4 or newer.

```bash
rojo build default.project.json -o CarDressUp.rbxl   # build a place file, or
rojo serve                                           # live-sync into Studio with the Rojo plugin
```

Open the place in Studio and press **Play**. In Studio, one player is enough to start a
match, so you can test the whole loop on your own. To test the rating flow, use
**Test > Clients and Servers** with 2 or more players.

Recommended place settings (Studio > Game Settings or the Properties panel):

- **Lighting.Technology = Future**: neon, underglow and headlights look much better.
- **Players > Max Players = 10**: matches hold up to 10 players.

## Tooling and tests

Tool versions are pinned in `rokit.toml` (run `rokit install`). Format with `stylua src`
and lint with `selene src`.

`tests/` contains an offline harness that runs the real game code against a mocked
Roblox runtime using the standalone [Luau CLI](https://github.com/luau-lang/luau/releases).
It:

- builds every option on every base car, plus 400 random combinations, and checks each
  one for errors, invalid sizes or positions, parts missing a joint, and missing
  animation motors;
- builds the map;
- starts the client UI and clicks through every category, option, swatch, rating and
  show-off button.

```bash
LUAU=/path/to/luau tests/run.sh
# optional: also check every property the code writes against Roblox's API dump
API_DUMP=API-Dump.json LUAU=/path/to/luau tests/run.sh
```

## Ideas for next steps

- Save wins and favourite builds with DataStoreService.
- Add engine and bass sounds (upload audio and play it on `TrunkOpen` / `Burnout`).
- Add more base cars. Add an entry to `Catalog.Cars` and the builder handles the rest.
- Add unlockable parts, or a currency paid out based on placement.
