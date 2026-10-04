// GTNH 2.8.4 + GTNL 0.2.6 compatibility patch
// Adds a missing production route for the existing MAX-tier
// Temporally Transcendent Mainframe used by GTNL Compressed Stargate Tier 0.
//
// Design:
// - Does NOT alter GTNL's Compressed Stargate recipe.
// - Does NOT add a new Planck Circuit item.
// - Uses the existing GregTech MAX circuit, already registered as circuitMAX.
// - Research item: Quantum Circuit (UXV).
// - Crafting voltage: UXV practical recipe voltage.
// - Requires both White/Black Dwarf Matter, so the recipe stays after Eye of Harmony progression.
//
// Item metadata verified for GTNH 2.8.4:
// 32177 Temporally Transcendent Mainframe
// 32165 QPIC
// 32178/179/180/181 Optical XSMD R/D/T/C
// 32184 Optical XSMD Inductor

val quantumCircuit = <dreamcraft:item.QuantumCircuit>;
val highEnergyFlowCircuit = <dreamcraft:item.HighEnergyFlowCircuit>;

val qpic = <gregtech:gt.metaitem.03:32165>;
val xsmdResistor = <gregtech:gt.metaitem.03:32178>;
val xsmdDiode = <gregtech:gt.metaitem.03:32179>;
val xsmdTransistor = <gregtech:gt.metaitem.03:32180>;
val xsmdCapacitor = <gregtech:gt.metaitem.03:32181>;
val xsmdInductor = <gregtech:gt.metaitem.03:32184>;

val transcendentMainframe = <gregtech:gt.metaitem.03:32177>;

mods.gregtech.AssemblyLine.addRecipe(
    quantumCircuit,
    36000,
    [
        quantumCircuit * 16,
        highEnergyFlowCircuit * 64,
        qpic * 64,
        xsmdResistor * 64,
        xsmdDiode * 64,
        xsmdTransistor * 64,
        xsmdCapacitor * 64,
        xsmdInductor * 64
    ],
    [
        <liquid:molten.mutatedlivingsolder> * 9216,
        <liquid:molten.whitedwarfmatter> * 4608,
        <liquid:molten.blackdwarfmatter> * 4608,
        <liquid:molten.spacetime> * 4608
    ],
    transcendentMainframe,
    24000,
    503316480
);
