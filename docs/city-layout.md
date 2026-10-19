# City layout, scale rules and detail — world map (Amsterdam)

_2026-10-19. From the reference set in `~/Desktop/New Folder With Items` (16 screenshots + `Details.png`)._

## 1. What the references do that we didn't

| Reference | What makes it feel alive and real |
|---|---|
| `Details.png` (brick street) | **Every surface has a texture**: brick courses, slate roofs, sandstone. Dark outline around each building, light from the left, shadow under every sill and cornice. Chimneys with pots, dormers, a roof vent. Trees *overlap* the facades. Street furniture is sparse but present: a bench, a planter, bins, a tree pit. Nothing is busy, everything has a frame, a sill, a step |
| Shop row (Paris-style) | Shop front = painted wooden frame + signboard + display window with goods on shelves + glass door + two wall lamps + plants in pots. Balconies with iron railings and flower boxes. Bollards on the kerb |
| NY street (thrift / pub / nails) | Variation per shop: every sign has its own colour and lettering; posters in windows; parking meters, hydrant, bin bags. Fire escapes and lintels make the upper floors read |
| Market square / terrace | People, tables, chairs, umbrellas, A-boards, crates of produce — the ground floor is where life happens |
| Corner with bus | Street signs, a traffic light, a no-parking sign, bike rack, benches, trees with light/dark leaf clusters |
| Skylines, rooftops | Depth from layers: haze-blue towers far back, roofs with water tanks/AC units, trees between blocks |
| Canal city with bridge | Brick bridge arches, buildings packed tight with different heights and gable shapes, trees between |
| Park | Hedge, bench, two-tone lamp posts, tree canopies with 3 leaf tones and a dark outline |
| Airport (3 shots) | Long low terminal with a glass band, control tower, planes and service trucks on the apron, light poles, city skyline far behind |
| Industry | Cranes, chimneys, scaffolding, sand heaps |

**Level of detail rule**: every element gets *frame + shadow + one highlight*; one small story per house (a cat in a window, a bike against the wall, flowers) — not more.

## 2. Pixel density

The band sprites are drawn at **2× the world grid** (54 px tall, shown at half size). The old houses were drawn at 1× — that's why they looked blocky next to the band.

**From now on the city is drawn at the sprites' density** ("art px" = half a world px), so a brick, a window frame or a sign letter is as fine as Joep's beard. At 2× city zoom one art pixel is one screen pixel of the 640×360 view — crisp.

## 3. Scale rules (world px; the band is 27 px tall)

| Thing | Size | vs a member | Note |
|---|---|---|---|
| Band member | 27 tall | 1× | |
| Front door | 17 × 34 | 1.25× | the studio door (22 × 38) was already right |
| Shop door | 16 × 34 | 1.25× | with glass panel |
| Window | 11 × 18 | 0.65× | with frame, sill, lintel |
| Ground floor | 44 | 1.6× | shop fronts live here |
| Upper storey | 38 | 1.4× | slightly compressed (real ≈ 2×) so most houses fit the 2× view |
| Canal house | 54–72 wide, 3–4 storeys, 145–185 tall incl. gable | | 3 window bays |
| Car | 62 × 22 | 2.3× long, 0.8× high | |
| Our van | 81 × 34 (sprite at 0.75) | 3× long, 1.25× high | was 108 × 46: too big |
| Delivery van | 76 × 32 | | |
| Truck | 150 × 42 | | |
| Bike + rider | 26 long, 27 tall | | |
| Street tree | trunk 40–50, crown 44–64 wide | | crowns overlap facades |
| Lamp post | 44 | | |

All traffic uses these sizes, so on the highway at 0.5× zoom the cars are as big as ours.

## 4. Layout west → east, and why

```
 W                                                                                              E
 |== country road (polder) ==|highway|hotels|park·theatre|OLD TOWN|=== CANAL BELT ===|ring/flats|industry·storage|road|airport hotels·AIRPORT|
   farms, mills, cows,        joins    town   green edge   churches,  studio, Café      new blocks  station, mall,   ...  terminal, tower,
   turbines, van at a farm    the road edge   + culture    market,    De Kat, 6 bridges  parked     car park, self        planes taking off
                                                           bars       houseboats         cars       storage, OUR STORAGE
```

| District | Where | Why there | Buildings | Street | Traffic / parking |
|---|---|---|---|---|---|
| Country road | far west | the way to the next city; long and calm | polder layers | dike road, 2 lanes | highway traffic both lanes |
| Highway merge | west town edge | cars into town come from the ring road | — | — | ramp traffic |
| Hotels | west edge | by the ring road, near the centre | hotels | lamps, flags | parked cars, taxis |
| Park + theatre | after the hotels | Amsterdam's parks and theatres sit at the edge of the old city | park, theatre | trees, benches, lamps | parked cars |
| Old town | towards the centre | oldest streets: churches, the market, bars | churches, market, narrow houses full of shops/bars | terraces, A-boards, bikes, planters | **no cars** (pedestrian), bikes |
| Canal belt | centre | the postcard: canal houses with gables, bridges | canal houses (brick/painted, hoist beams), studio, Café De Kat | elms on the quay, bollards, bike racks, benches, houseboats | **no cars: one-way, no parking**, only bikes |
| Ring / new flats | east of the belt | 19th–21st century growth around the centre | apartment blocks | young trees, bike sheds | cars parked along the street, some traffic |
| Industry + storage | east | cheap land by the ring road; where bands keep their gear | station, mall, car park, self storage, our storage | tall lamps, fences | traffic + parked cars |
| Airport | far east, outside town | airports sit outside the city by the motorway; with hotels next to them | airport hotels, terminal, control tower, apron with planes | light poles, fences | traffic, planes taking off |

## 5. Ground rules per district (for later additions)

- Centre: bikes, never cars. Trees every 2–3 houses. One bench per ~3 screens.
- Old town: one terrace per bar, an A-board per shop, planters; trees only on squares.
- Ring: parked cars bumper to bumper with gaps at driveways; trees in pits every ~100 px.
- Industry: lamps every ~140 px, fences, no trees on the street side.
- Every building row varies height, gable and material; no two neighbours share a colour.

## 6. Built (2026-10-19)

- **Canal houses** (`city_block.gd`) at sprite density with brick/plaster textures (`pixel_art.gd`), outline + light, sash windows with lintels/sills/curtains/flower boxes/lit rooms (and the odd cat), step/neck/bell/spout/cornice/mansard tops with hoist beams and chimneys, doors with stoops and fanlights, shop fronts with signboards, display windows, gooseneck lamps, awnings, A-boards, café terraces. Three styles: canal belt, old town (narrow, more shops/bars), ring (wider, flat cornices, balconies)
- **Street life** (`street_life.gd`) per district: elms, canal lamps, Amsterdammertjes, bike racks, benches, bins, planters, meters, tall lamps, flags; doors and bridges kept clear
- **Pedestrians** (`pedestrians.gd`) at band scale on both sides of the street (far side behind the band, slightly smaller/hazier; quay side in front), window-shopping pauses, bags, backpacks, dogs; busier in the old town
- **Traffic** (`traffic.gd`) at real scale (car 62×22, van 76×32, truck 150×42, bus 170×40, bike + rider); old town + canal belt car-free (bikes only); parked cars along the ring, industry and airport road; our van drawn at 0.75 (81×34)
- **Houseboats** on the canal, with their own reflection
- **Airport** at the far east past the storage: two airport hotels, terminal, control tower, airfield with a parked plane and take-offs every ~40 s
- Doors on the big buildings (mall, self storage, storage, theatre, hotel, flats) now 34+ px

**Not yet**: the other big buildings (church, theatre, hotels, mall…) still use the older, coarser drawing; background layers (skyline, back street) are still 1×; people don't react to the band; night lighting.

## 7. Views into the city (2026-10-19)

The bridges and side-street gaps are **one-point perspective views** from eye height (`bridge.gd`): facades along both sides recede to a vanishing point with skewed windows, doors, awnings and roof edges; the left row is lit, the right in shade; trees, lamps and people on the quays; a brick bridge further down the side canal; haze with depth. Six canal views (150 px wide) and two side streets (110 px, cobbles, pavements, cyclists).
**Landmark**: the view at the bridge east of the studio ends at the **Pontsteiger** (Houthaven) — low wing, two towers, the top block on its white truss, sky through the gap.
