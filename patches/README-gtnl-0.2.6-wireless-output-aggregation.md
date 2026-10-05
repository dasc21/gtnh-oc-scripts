# GTNL 0.2.6 wireless output/Waila performance patch

Target: **GT: New Horizons 2.8.4 + GT-Not-Leisure 0.2.6**.

Patch file: `gtnl-0.2.6-wireless-output-aggregation.patch`

## What is happening

`WirelessEnergyMultiMachineBase` can run up to 100,000 internal processing cycles in one machine check. In GTNL 0.2.6 each cycle appends its item/fluid output arrays with `Utils.mergeArray()`.

For machines such as `CompoundDistillationFractionator` this can produce very large `mOutputItems` / `mOutputFluids` arrays containing the same output type many times.

GTNH's multiblock Waila code only renders the first three outputs in the tooltip, but its server-side NBT builder still walks every entry and creates icon/name/count data for every item and fluid before the packet is sent. Looking directly at a controller with a huge wireless output array can therefore cause severe frame-time/network/server work.

## Patch behavior

1. In wireless mode, equal item outputs are merged by item/meta/NBT and equal fluid outputs are merged by fluid/tag.
2. Amounts are split only when an `ItemStack.stackSize` or `FluidStack.amount` would exceed `Integer.MAX_VALUE`.
3. Waila is additionally protected: while its NBT is being built it sees at most three item and three fluid stacks, while the real output arrays are restored immediately afterwards.
4. The original full output counts are written back to Waila's `outputItemLength` / `outputFluidLength`, so the existing `and N more` line still reports the real number of output entries.

The patch does **not** intentionally change recipe selection, parallel count, wireless EU cost, overclocking, output totals, or output hatch handling.

## Apply to source

From a clean checkout of GT-Not-Leisure tag `0.2.6`:

```bash
git apply /path/to/gtnl-0.2.6-wireless-output-aggregation.patch
```

Then build GTNL using its normal build process and replace the existing GTNL jar on both server and clients if the mod jar is required client-side by the pack.

## Test checklist

1. Back up the world and old GTNL jar.
2. Start the `Compound Distillation Fractionator` in normal wired mode and confirm recipe outputs are unchanged.
3. Enable the wireless upgrade and run the same workload.
4. Look directly at the controller with Waila enabled; FPS should no longer collapse because of thousands of duplicate output entries.
5. Compare input consumption and final output totals before/after for at least one known recipe batch.
6. Check the server log for exceptions involving `WirelessEnergyMultiMachineBase`, Waila, or output hatches.

## Scope

The aggregation change affects GTNL machines using the base implementation of `WirelessEnergyMultiMachineBase.wirelessModeProcessOnce`. Machines that override that method keep their own output handling unless separately patched.
