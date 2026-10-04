# GTNH 2.8.4 / GTNL 0.2.6 — MAX circuit compatibility patch

This patch adds one missing production route for GregTech's existing **Temporally Transcendent Mainframe [MAX]**.

GTNL 0.2.6 uses two of these circuits in **Compressed Stargate Tier 0**, while GTNH 2.8.4 already contains the item and registers it as a MAX-tier circuit but does not provide a normal production route for it.

The patch intentionally **does not modify the GTNL Stargate recipe** and **does not add a new Planck Circuit item**.

## Added recipe

Machine: **Assembly Line**

Research item: **Quantum Circuit [UXV]**

Research time: **36,000 ticks / 30 min at 20 TPS**

Items:

- 16x Quantum Circuit
- 64x High Energy Flow Circuit
- 64x QPIC
- 64x Optical SMD Resistor
- 64x Optical SMD Diode
- 64x Optical SMD Transistor
- 64x Optical SMD Capacitor
- 64x Optical SMD Inductor

Fluids:

- 9,216 L Molten Mutated Living Solder
- 4,608 L Molten White Dwarf Matter
- 4,608 L Molten Black Dwarf Matter
- 4,608 L Molten SpaceTime

Output: **1x Temporally Transcendent Mainframe [MAX]**

Craft time: **24,000 ticks / 20 min**

EU/t: **503,316,480 EU/t**, the practical UXV recipe voltage in GTNH 2.8.4.

## Installation

Copy:

`crafttweaker/zzz_97_max_circuit_compat.zs`

into the instance/server `scripts/` directory, so the final path is:

`scripts/zzz_97_max_circuit_compat.zs`

A full server restart is recommended. MineTweaker reloads are less reliable for machine-recipe registration and can produce duplicate recipe entries during testing.

## Removal

Delete `scripts/zzz_97_max_circuit_compat.zs` and restart.

## Why this recipe

GTNH 2.9 solves MAX circuits by adding the Planck-Scale Circuit and a dedicated Nanochip Assembly Complex chain. That chain does not exist in the same form in 2.8.4, so directly backporting it would require much more than a recipe patch.

This compatibility route keeps the GTNL 0.2.6 gate unchanged, uses the MAX circuit that 2.8.4 already registers, requires UXV circuitry, and additionally gates the recipe behind White/Black Dwarf Matter from the Eye of Harmony.
