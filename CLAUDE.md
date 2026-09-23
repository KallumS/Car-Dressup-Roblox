# CLAUDE.md — Car Dress Up (Roblox)

A Dress to Impress style game where players customise cars instead of outfits. Everything
is written in Luau and synced with Rojo. The map, cars and UI are all built at runtime in
code, with no imported assets. The README covers features and layout; this file holds what
a new session needs to work safely.

## Status
- v1 is complete on branch `claude/friendly-albattani-ozocq2` (no PR yet).
- **It has never been run in Roblox Studio.** All checks so far were offline (see Verify).
  Things only Studio can confirm: vinyl orientation on SurfaceGuis, feel of client
  animations, performance with 10 cars (up to about 530 parts per car), camera framing,
  UI layout on phones.
- Selene is configured but has never run: its Roblox std download is blocked from cloud
  containers.

## Verify (run before every push)
```bash
tests/setup-tools.sh   # first time per container, ~10 min: run in background
tests/check.sh         # stylua --check, rojo build, luau-lsp type check, runtime harness + API property audit
```
- The harness (`tests/`) bundles the real modules with a mocked Roblox API
  (`mock*.luau`) and runs them in the plain Luau CLI. Every option is built on every car,
  plus 400 random builds, checking for errors, sizes, one joint per part and the required
  motors. It also builds the map and clicks through the whole client UI. Every property
  the code writes is checked against the API dump.
- When you add an Instance method, event or datatype, extend `tests/mock.luau` or
  `tests/mock_client.luau` or the harness will error.
- Network from the container: GitHub releases and roblox.com are blocked. `git clone` of
  github.com, `raw.githubusercontent.com`, crates.io, npm and pypi all work.
- Format with `stylua src` (tabs, 120 columns). luau-lsp must report no errors.

## Architecture invariants (don't break these)
- **Data-driven catalog:** `src/shared/Catalog.luau` holds slots, options and the palette.
  The server validates every edit with `Catalog.IsValidValue` and `Catalog.Sanitize`. A
  new option needs (1) a Catalog entry, (2) drawing code in `CarBuilder`, (3) a harness
  run. Colours travel as palette ids (strings), never as Color3.
- **Car coordinates:** built at the origin, then moved. The car faces **-Z**, +X is its
  right side, y=0 is the ground. `Root` is the only anchored part. Body parts are in
  "chassis space" (`ctx.chassisCF` = ride height) and welded to `Chassis`, which is joined
  to `Root` by the `Suspension` Motor6D. Wheels hang off `Root`.
- A WedgePart is assumed to be tall at +Z and to slope down toward -Z. `Util.facingFront`,
  `facingRear` and `facingUp` point a cylinder's X axis for discs.
- Every non-root part has **exactly one** joint (Weld or Motor6D) whose Part1 is itself.
  Parts driven by a motor use `NoWeld = true` in `Util.part`.
- **Animation contract:** the server only sets model attributes: `DoorsOpen`, `HoodOpen`,
  `TrunkOpen`, `Bounce`, `Burnout`, `Driving`, `HasHydraulics`, `UnderglowMode` and
  `InteriorMode`. `client/CarAnimator` drives `Motor6D.Transform` in PreSimulation. Motors
  are found by name: `Hinge` (attributes `Kind`, `RX`, `RY`, `RZ` in degrees, applied as
  Y·Z·X), `Wheel` (attribute `Rear`), `Spinner`, `SubCone`, `Suspension`. Local previews
  use `CarAnimator.setOverride(carName, flag, value)`.
- **Vinyls:** each side panel registers `{Part, Side, Z0, Z1, Y0, Y1}` in
  `ctx.sideSurfaces`. A SurfaceGui shows that panel's window onto a canvas covering the
  whole side (u = front→rear, v = top→bottom). Right faces are mirrored. Rotated
  GuiObjects are avoided because they break ClipsDescendants; diagonals come from
  UIGradient instead. Racing stripes are thin welded parts laid on `ctx.topSurfaces`.
- **Networking:** `shared/Net.luau` creates every remote on the server; clients wait for
  them. Cars live in `workspace.Cars` as `Car_<UserId>`, with ModelStreamingMode set to
  Persistent. Map models are Persistent too. Timers use `workspace:GetServerTimeNow()`.
- **Match loop:** `server/MatchService.luau` runs Lobby → Intermission → Customize →
  Showcase (per car) → Results. Edits mark cars dirty, and a loop rebuilds dirty cars every
  `Config.RebuildInterval`. A rejected edit resyncs the client with `BuildChanged`, because
  the client updates optimistically.
- The client is a single LocalScript (`client/init.client.luau`). Controllers subscribe
  to `Store.StateChanged` / `Store.BuildChanged`. UI is built with `client/UI.luau`
  helpers under one ScreenGui with a UIScale for small screens.

## Conventions
- Put new tunables in `shared/Config.luau`. Keep modules small and focused, comment only
  the non-obvious, and name things like the surrounding code.
- Commit on the designated branch and push with `git push -u origin <branch>`. Don't open
  a PR unless the user asks.

## Backlog (next steps)
1. Playtest in Studio and fix whatever the offline checks couldn't catch (see Status).
2. Save Wins and favourite builds with DataStoreService.
3. Sounds (engine, bass on TrunkOpen, burnout). They need uploaded asset IDs from the user.
4. More base cars and parts, and unlockables or a currency.
5. Performance pass if needed: cut ring/spoke segment counts, or share one build per
   frame budget.
