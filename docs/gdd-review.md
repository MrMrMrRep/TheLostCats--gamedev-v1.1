# GDD Review — "The Lost Cats: Nine Lives on the Road"

Review of the GDD (Notion export, 2026-10-18) plus the reference images (Kingdom Eighties) and the assets in `public/assets/amwoods/`.

## 1. What the document gets right

- **A clear identity:** Lost Vikings–style co-op puzzles, Celeste-style controls and Kingdom Eighties–style pixel art. Each part does a different job (puzzles, feel, looks), so they don't fight each other.
- **A real band as the cast.** Personal and funny, and it works as marketing too.
- **Two paces of play** (calm world map vs. tense levels). Kingdom Eighties shows this works: the reflective water, the soft parallax and the slow ride make the world map feel safe.
- **"Geoff goes missing" as the recurring finale.** It's a strong running gag, and it also forces the other four to solve the last puzzle without the singer.
- **"Finished vs. Completed" plus audio cues for hidden NPCs.** Cheap to build and good for replay value.
- **Jump tuning by feel** (tiles and seconds, not raw numbers). That's the right way to tune.

## 2. Contradictions and gaps to fix first

These block implementation, because code needs one answer for each.

| # | Problem in the GDD | Suggested resolution |
|---|---|---|
| 1 | **Old names are still in the text.** "David", "Jan Jaap" and "Nickolas" appear in Items, the Combat summary and the NPC twist, but the band is Geoff, Jay, Joep, The Germ and Nikki. | Replace them: David → **The Germ** (rats and pests), Jan Jaap → **Jay** (knockback), Nickolas → **Nikki**. |
| 2 | **Who uses whiskey?** Items says "only David", Jay's B is "drinks whiskey → rage aura", and The Germ gets rage from "joint or whiskey". | Whiskey = **Jay's** rage aura (him plus neighbours, short). **The Germ's** Rage Mode (15 s, star-power) comes from the **joint**. Each item has one owner. |
| 3 | **The joint has two uses:** the lure for Geoff (joint *skin*) and The Germ's rage trigger. | Keep both, but as two items: **Rolling papers** = Geoff lure, **Joint** = Germ rage. |
| 4 | **"Use the starting values below" for stamina, but no values are given.** | Proposed values in §4. |
| 5 | **Beer is three things at once:** a heal item (+1 HP), Joep's speed/stealth buff and Nikki's heal aura. | One rule: **anyone who drinks a beer heals 1 HP, and some band members get a bonus effect** (Joep: quick and quiet for 5 s. Nikki: heals neighbours too. Geoff: see #7). Beer becomes a shared resource the player has to decide how to spend. |
| 6 | **Two different death rules.** "Restart the level from the last checkpoint" and "checkpoints in every room". | Death → **the whole room resets to its checkpoint** for every band member (Lost Vikings rule). Hard mode: restart the level. |
| 7 | **Geoff has no real verb.** His bubbles "do nothing", his stats are all 1–2 and he has 1 HP, so he's the least fun to play. | Bubbles **distract**: humans and animals turn toward the bubble for 2 s. That gives stealth and "get past the guard" puzzles. **Persuade** stays his key ability. 1 HP is fine, because his role is to be escorted. |
| 8 | **Bike vs. van vs. walking** on the world map. Why would anyone walk? | The van is fast but **can only stop at parking spots**. The bike is medium speed and can stop anywhere. Walking is needed to enter doors and pick things up. That gives each one a reason to exist. |
| 9 | **Procedural world map vs. fixed key locations** (studio in the middle, festival and stadium at the edges). | Hand-built for v1. Later: **seeded procedural filler segments** between hand-made anchors (studio, venues, service station, edges). |
| 10 | **Nikki's "bridge" has no rules.** | The cable bridge is cast between **two anchor points** (hooks/poles) within 6 tiles. It lasts until Nikki moves away, and only light members can cross it unless it's a "strong cable" upgrade. |

## 3. Gameplay and playability suggestions

### 3.1 Celeste controls vs. "slow" characters
Celeste feels good because of **consistency**, not just speed. Speed 2/5 and Jump 1/5 can feel sluggish if you just lower the numbers.

- Every character shares **the same controller code**: coyote time, jump buffer, variable jump, corner correction and fast acceleration.
- Characters differ only in **max speed**, **jump height** and **one movement verb** each. Keep the range narrow: slowest is about 65% of the fastest. Acceleration stays snappy (0.05–0.1 s) for everyone.
- Turn the 1–5 stats into **tiles**, so levels can be designed around them:

| Stat | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Jump (tiles high) | 1.3 | 2.3 | 2.8 | 3.3 | 3.8 |
| Climbs ledges up to | 1 | 2 | 2 | 3 | 3 |
| Speed (tiles/s) | 5 | 5.5 | 6.5 | 7.5 | 8.5 |

Then "a 2-tile ledge stops Geoff and The Germ" is a rule a level designer can rely on. That's the core of Lost Vikings gating.

*Running-jump reach (measured in M5):* Geoff and The Germ about 2.2 tiles, Jay 2.9, Joep 4.7, Nikki 5.3. Anything **everyone** must cross alone should be at most **1 tile wide** (Geoff/The Germ clear about 1.5 tiles edge to edge). Islands in a pit must be wide enough to catch both the short and the long jumps (4 tiles works). Wider gaps are deliberate gates for a co-op solution (Jay throws, Nikki hovers).

*Updated in M3 after playtesting:* jump heights carry a **0.3-tile margin** above the ledge they're meant to clear. With a jump exactly as high as the ledge (2.0 vs 2), clearing it took a frame-perfect jump.

### 3.2 One clear job per member (the gating matrix)
Each member needs one thing that **only they** can do. Level design builds on this table:

| Member | Movement verb | Unique interaction | Breaks | Stamina use |
|---|---|---|---|---|
| **Joep** (keys) | Wall-slide, wall-jump, climb | Hack panels/machines, place traps | — | Climbing |
| **Jay** (bass) | — | Push, pull and lift heavy objects. **Lift/throw a band member** up one level | Glass, speakers, ice, fragile walls (bass wave, ranged) | Holding a lift |
| **Nikki** (guitar) | Double jump, guitar hover | Cable bridge | — | Hover |
| **The Germ** (drums) | Ground-pound (air attack) | Drum-stick shield (blocks projectiles, forward or up) | Wood, crates, cracked floors | Shield |
| **Geoff** (vocals) | — | Persuade humans, bubble distraction | — | — |

Suggestion: **Jay can throw a band member** up (Lost Vikings 2 did something similar). That fixes "how do The Germ and Geoff get up a ledge" and adds a lot of co-op puzzles.

### 3.3 Five characters is a lot at once
Lost Vikings used 3 characters, and switching between 5 every room gets tedious. Suggestions:
- Most rooms use **2–3 members**. The level start (or a split door) picks the team, which the GDD already hints at with "party splits up".
- Inactive members **stay where they are** (Lost Vikings rule). A **"Gather" button** brings the others back to the active member when nothing blocks the path, so the player doesn't have to walk each one over.
- Doors (built in M5): the whole group goes through only when everyone in the room stands within 3 tiles of the member using the door; otherwise that member goes alone. That lets you split into teams on purpose.
- Switch with **Tab / Q-E (cycle)** and **1–5 (direct)**. The camera moves smoothly to the new member (0.25 s).

### 3.4 Balancing the two paces (the most important thing for you)
Concrete targets you can measure in playtests:

| | World map | Level rooms |
|---|---|---|
| Time per visit | 1–3 min between levels | 8–15 min per level (4–6 rooms, about 2 min each) |
| Danger | None that kills. Police = fine/time loss | Kills, with a checkpoint per room |
| Camera | Zoomed out (1×), slow follow, wide look-ahead | Zoomed in (2×), tight deadzone |
| Music | ~80–90 BPM dub/reggae, calm | ~140–160 BPM ska-punk |
| Controls | Leader walks, the rest follow (Kingdom style) | Full character switching |
| Transition | 1–2 s music crossfade plus a zoom tween at the door | Same, in reverse |

Rule of thumb: **after every hard room there is a short calm moment** (a corridor with an NPC or a beer). After every level, the world map acts as the "breather".

### 3.5 World map
- On the world map **the band moves as one group**: the leader walks and the others follow in a line. No switching is needed.
- **Police at night:** don't use jail (game over). Getting caught costs money or a lost gig. Danger should mean "lose time or money" there, never "die", so the pace stays relaxed.
- Add a **tour-day / time-of-day clock**, so getting to the venue before showtime adds light pressure without combat.
- Packages and tour posters work well as "something to do": posters could raise fans in that town.

### 3.6 Health, items and inventory
- 3 HP each, Geoff 1 HP. After a hit: **1 s of invulnerability** plus knockback, so one mistake doesn't kill twice.
- **3 inventory slots per member.** Trade with a single "Give" button when two members are within 1 tile.
- Show a **shared inventory bar** with the active member highlighted, Lost Vikings style.

### 3.7 Abilities B ("Drinks …")
Drinking needs a cost or the beer button gets spammed. Drinks are **consumed from inventory**, so no extra cooldown is needed. Buffs never stack.

## 4. Proposed starting values (put these in one config resource)

**Stamina (`StaminaConfig.tres`)**

| Member | max | regen /s | regen delay | ground regen × | exhausted threshold |
|---|---|---|---|---|---|
| Joep (climb) | 100 | 35 | 0.4 s | 2.0 | 20 |
| Jay (lift) | 100 | 25 | 0.6 s | 2.0 | 20 |
| Nikki (hover) | 100 | 30 | 0.5 s | 2.0 | 20 |
| The Germ (shield) | 100 | 25 | 0.6 s | 2.0 | 20 |
| Geoff | — (doesn't use stamina) | | | | |

Drain rates: climb 25/s, wall-jump 15 each, hover 45/s (about 2.2 s of hover), shield 30/s plus 10 per blocked hit, holding a lift 20/s.

**Movement (`MovementProfile.tres` per member, filled from the §3.1 tables)**

| | Speed | Jump | Extra |
|---|---|---|---|
| Joep | 4 | 4 | wall-jump |
| Jay | 2 | 2 | — |
| Nikki | 5 | 4 | double jump + hover |
| The Germ | 2 | 1 | ground-pound |
| Geoff | 2 | 1 | — |

Shared: same gravity for everyone (time to apex scales with √height: 0.357 s at 3.3 tiles, 0.224 s at 1.3), fall gravity 1.8×, coyote 0.1 s, buffer 0.12 s, jump cut 0.45, apex hang 0.5× when |vy| < 60 px/s with jump held, ceiling corner correction 4 px, ledge correction 3 px, fall 18 tiles/s (26 holding down). Implemented in `resources/profiles/*.tres`.

## 5. Technical and art notes from the asset pack

- **Backgrounds are 320×180**, so the native pixel grid is 320×180. Suggested setup: viewport 640×360, integer scaling to 1080p/1440p/4K, `canvas_items` stretch (already set), **nearest-neighbour texture filtering**. Rooms use camera zoom 2× and the world map 1×, which keeps both pixel-perfect.
- **`char_blue.png` (448×392)** = 8×7 grid of **56×56** frames: idle (6), attack (6), run (8), jump/fall (8), extra row (8), hurt/death (8+4). It's one blue knight with a sword and shield. For v1 we use **5 color-tinted copies** as stand-ins for the band. There are no climb, hover, wall-slide or push animations, so those get placeholders until custom band sprites exist.
- **`amwoods_tileset.png` (504×360)**: the tile size looks like **24 px** (21×15 grid), to be verified in step 1.
- `shop_anim.png` (708×128) = 6 frames of 118×128. Good as a first "shop / venue door".
- The project is GDScript-friendly, but `project.godot` has a `[dotnet]` section. Recommendation: **GDScript only** for this project.
- The renderer is Forward+. That's fine for 2D, and *Compatibility* would also run on older Macs. Both work, so no change is needed now.

## 6. Risks

1. **Scope.** The full GDD (procedural map, economy, upgrades, day/night, police, festival, stadium) is a multi-year game. v1 must be a *vertical slice*, see `v1-plan.md`.
2. **Art.** Kingdom Eighties–level art needs custom sprites for 5 members. Until those exist, the slice should prove the *gameplay*, not the looks.
3. **Real people.** Agree with the band on how their likenesses and jokes (drinking, joints) are shown, and check the age rating if this ships on stores.
