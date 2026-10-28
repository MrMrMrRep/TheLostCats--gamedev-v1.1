# Skills and abilities (v2, 2026-10-28)

The one place for what each band member can do in a level. Replaces the M6 set
(Joep's climb, Nikki's double jump and hover, The Germ's shield). Code:
`scripts/abilities/` (one `MemberAbility` per member) and
`scripts/characters/band_member.gd` (the moves everyone shares). Numbers:
`resources/config/stamina_config.tres` and `resources/profiles/<member>.tres`.
Test level: `scenes/levels/abilities_test.tscn` (a station per member, see the
end). Tests: `tests/test_abilities.gd` (69 checks).

## Controls

| Action | Keyboard | Gamepad | Touch |
|---|---|---|---|
| Walk | arrows / WASD | stick, d-pad | stick |
| Run | hold Shift | L3 | push the stick all the way |
| Crouch | hold down | down | stick down |
| Jump | Space / C | A | JUMP |
| Punch (swings a weapon if one is selected) | J / X | X | PNCH |
| Special skill | K / Z | Y | SPCL |
| Instrument skill | L | RT | INST |
| Door, talk, hack panel; with nothing near: use the selected item | E | B | E |
| Use item (a beer is drunk) | R | (B with nothing near) | ITEM |
| Next item / give / drop | T / F / V | R3 / LT / — | NEXT / GIVE / DROP |

On the world map only walking (Shift sprints) and jumping work: the skills are
for the levels (`BandMember.map_mode`).

## Everyone

| Move | What it does | Numbers |
|---|---|---|
| Walk | the member's own speed (profile `run_speed_tiles`) | Joep 7.5, Nikki 8.5, others 5.5 tiles/s |
| Run | hold Shift: 1.35x faster, longer jumps | 12 stamina/s on the ground; not while exhausted |
| Crouch | hold down on the ground: half height (14 px), 0.45x speed. Fits under 1-tile gaps; stays down while something is overhead | |
| Wall-slide | push into a wall while falling: slide at 40 px/s | no wall jump |
| Punch | knocks rats back (stunned). Breaks nothing | 22 px reach, 0.35 s |
| Punch with a weapon | the selected item has `weapon` (the mic stand): longer reach, knocks rats out | mic stand 40 px |
| Beer | R drinks it: +1 HP for anyone. Joep: quick for 5 s. Nikki: heals members within 2 tiles too | |

Instrument skills cost stamina and share a 3 s cooldown ("Not yet...",
"Too tired"). Everyone has a stamina pool; Geoff's is smaller (60).

## Per member

| Member | Special (K) | Instrument (L) |
|---|---|---|
| **Joep** (keys) | **Hack** the nearest electrical thing within 40 px: hack panels, electronic door locks (`Door.hack_lock`), security cameras, amps. A **wall plug** wired to a device reaches it through the wall. (E on a hack panel works too.) | **Electric shockwave** (60): rats within 3 tiles knocked out, within 7 tiles stunned 2.5 s; every hackable device within 7 tiles switches (panels, doors, cameras, amps) |
| **Jay** (bass) | **Lift and throw**: next to a flight case he lifts it over his head (0.7x speed, 20 stamina/s, dropped when he runs out or gets hit); K again throws it ~4 tiles. Next to a member: throws them ~4.3 tiles up. Pushes cases by walking into them | **Slap bass** (40): sub-bass in front of him, 6 tiles: rats knocked back, glass and fragile walls shatter, flight cases shoved away, and a **defence bubble** (2.5 s, no damage) for him and everyone within 3.5 tiles |
| **The Germ** (drums) | **Rage punch** (30): charges ~4.5 tiles on fire, straight through rats (knocked out) and wooden crates / cracked floors; ends in a shockwave that stuns rats around him. People stop the charge. In the air: a **slam** straight down (cracked floors) | **Drumbeat Master** (70): the beat stops time for everything but the band (rats, flight cases, timed gates, moving platforms). L again: **rewind** the last seconds (up to 4 s, at 2x). L once more: **play**. Ends by itself after 6 s; a death or a door ends it too (`TimeControl`) |
| **Nikki** (guitar) | **Grapple**: fires at the nearest hook (`GrappleHook`) within 150 px, above her and not behind; she swings (left/right pump, up/down climb the line), jump lets go with a boost, K lets go | **Guitar solo** (50): a bridge of notes straight ahead (7 tiles), or with up held a **ramp** rising 5 tiles. One-way platforms the whole band can use; they fade after 8 s (`NoteBridge`) |
| **Geoff** (vocals) | **Bubble gun**: bubbles do nothing to anyone, but distractible people (security, fans: `Bouncer.distractible`) look at them and drift after them, leaving the way open. Rats don't care | **The voice and the charm** (15): talks the nearest person within 80 px out of the way (bouncers, sound guy, security, bartenders, early-bird fans, managers) and opens staff-only doors (`Door.charm_lock`). Not rats ("Can't charm a rat"), not machines. E up close works too. **While Geoff is selected everything is 30% cheaper** (`Game.price()`) |

## Gating matrix (for level design)

| Obstacle | Who | How |
|---|---|---|
| 1-tile-high gap | everyone | crouch |
| Wooden crates, cracked floor | The Germ | rage punch / slam |
| Glass, fragile wall | Jay | slap bass |
| Hack panel, electronic lock, camera, amp | Joep | hack (K); out of reach: wall plug or shockwave |
| Security camera (shuts its gate when it sees you) | Joep | shockwave from outside its view |
| Ledge 2 tiles | Jay (2.3), Joep/Nikki (3.3) jump; others need a step | Jay lifts/pushes a flight case there |
| Ledge 4 tiles | nobody alone | Jay throws someone; Nikki's ramp (5 tiles) |
| Pit wider than a running jump | Nikki | grapple; her solo bridge takes everyone |
| Timed gate (0.6 s) | The Germ | Drumbeat Master holds it open |
| Bouncer, sound guy, manager | Geoff | charm |
| Security, fans | Geoff | charm, or bubbles to distract them |
| Staff-only door | Geoff | charm |
| Spikes on the way | Jay | the slap-bass bubble |

## Level props (`scripts/props/`, `scripts/enemies/`)

`SwitchPanel` (lever / hack panel), `Door` (`locked` + `key_id`, `hack_lock`,
`charm_lock`), `Gate` (`open()` / `close()` / `trigger()`), `TimedGate`
(`open_time`), `MovingPlatform` (`travel`, `period`), `SecurityCamera` (`view`,
`facing`, `targets` it shuts), `Amp`, `WallPlug` (`target`), `GrappleHook`,
`Breakable` (glass / fragile wall / wood / cracked floor), `FlightCase`,
`Hazard` (spikes / electric), `Rat`, `Bouncer` (any person: `role`, `refusal`,
`agreement`, `distractible`), `Vendor` (`item`, `base_price`), `CoinPickup`,
`ItemPickup`. Anything in the `timed` group is under The Germ's beat; give it
`time_state()` / `set_time_state()` if a rewind should restore more than its
position.

## The test level

`scenes/levels/abilities_test.tscn` (behind the studio door and the storage
gate on the map) is generated by
`tools/scene_edits/2026_10_28_make_abilities_test.gd`, then edited by hand. One
hall, west to east: BASICS (crouch beam, mic stand, rat pen) → JOEP (wall plug
to the panel that kills the electric floor, a camera only the shockwave
reaches, an amp) → JAY (glass wall, flight case, 2-tile ledge with spikes, a
throw shelf) → THE GERM (crates, cracked slab, rats, a 0.6 s timed gate, a
moving platform over a pit) → NIKKI (8-tile pit with a hook, 5-tile wall) →
GEOFF (bouncer, distractible security, sound guy, tip jar, bar, staff door to
the green room) → exit to the map.
