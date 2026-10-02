-- godforge_qgp.lua
-- Custom Heliofusion Exoticizer controller for GTNH 2.8.4.
-- Based on GTNH-OC-God-Forge-Control by Bohdan Kutsulima (MIT).
--
-- Changes for this installation:
--   * no Redstone I/O / ME Fluid Level Emitter requirement
--   * keeps Degenerate Quark Gluon Plasma at 100,000,000 L
--   * pins the fake craft to one selected AE crafting CPU
--   * does not require Crafting Monitor blocks
--   * persists the selected CPU name for safe restart recovery
--   * persists ME cell flushing state
--   * no auto updater
--
-- MIT License notice for the upstream-derived portions:
-- Copyright (c) 2025 Bohdan Kutsulima
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.


local component = require("component")
local computer = require("computer")
local serialization = require("serialization")


local CFG = {
  productionEnabled = true,


  -- Current mode. Keep QGP for this setup.
  mode = "QGP",


  -- Main AE stock control.
  targetFluidName = "quarkgluonplasma",
  targetAmount = 100000000, -- 100 million L


  -- Component addresses measured on this setup.
  outputMeInterfaceAddress = "46417c62-a97e-41f6-a259-7e02af9a39a8",
  inputMeInterfaceAddress  = "98b180d5-8796-435b-a091-08a2e5a323b5",
  transposerAddress        = "acb68a98-d884-4edf-97b6-b440bb3c00e2",


  -- Transposer sides measured in game.
  meDriveSide = 0,  -- down
  meIoPortSide = 1, -- up


  -- Dedicated AE crafting CPU. Rename any block in one CPU multiblock to this name.
  cpuName = "GODFORGE",


  -- Current QGP output subnet uses three cells.
  driveCount = 3,


  -- Pattern slot in the input ME Dual Interface.
  patternSlot = 1,


  -- Timings.
  idlePollSeconds = 1,
  stockPollSeconds = 30,
  ioFlushTimeoutSeconds = 120,
  craftComputeTimeoutSeconds = 60,
  longWaitWarningSeconds = 240,


  -- Persistent recovery state.
  stateFile = "/home/godforge_custom.state"
}


local plasmaList = {
  ["Aluminium"] = "plasma.aluminium",
  ["Americium"] = "plasma.americium",
  ["Antimony"] = "plasma.antimony",
  ["Ardite"] = "plasma.ardite",
  ["Argon"] = "plasma.argon",
  ["Arsenic"] = "plasma.arsenic",
  ["Barium"] = "plasma.barium",
  ["Beryllium"] = "plasma.beryllium",
  ["Cadmium"] = "plasma.cadmium",
  ["Caesium"] = "plasma.caesium",
  ["Calcium"] = "plasma.calcium",
  ["Carbon"] = "plasma.carbon",
  ["Cerium"] = "plasma.cerium",
  ["Chlorine"] = "plasma.chlorine",
  ["Cobalt"] = "plasma.cobalt",
  ["Copper"] = "plasma.copper",
  ["Curium"] = "plasma.curium",
  ["Desh"] = "plasma.desh",
  ["Deuterium"] = "plasma.deuterium",
  ["Dysprosium"] = "plasma.dysprosium",
  ["Erbium"] = "plasma.erbium",
  ["Europium"] = "plasma.europium",
  ["Fluorine"] = "plasma.fluorine",
  ["Gadolinium"] = "plasma.gadolinium",
  ["Gallium"] = "plasma.gallium",
  ["Germanium"] = "plasma.germanium",
  ["Gold"] = "plasma.gold",
  ["Hafnium"] = "plasma.hafnium",
  ["Helium"] = "plasma.helium",
  ["Holmium"] = "plasma.holmium",
  ["Hydrogen"] = "plasma.hydrogen",
  ["Indium"] = "plasma.indium",
  ["Iodine"] = "plasma.iodine",
  ["Iron"] = "plasma.iron",
  ["Lanthanum"] = "plasma.lanthanum",
  ["Lithium"] = "plasma.lithium",
  ["Lutetium"] = "plasma.lutetium",
  ["Magnesium"] = "plasma.magnesium",
  ["Manganese"] = "plasma.manganese",
  ["Mercury"] = "plasma.mercury",
  ["Meteoric Iron"] = "plasma.meteoriciron",
  ["Molybdenum"] = "plasma.molybdenum",
  ["Neodymium"] = "plasma.neodymium",
  ["Nickel"] = "plasma.nickel",
  ["Niobium"] = "plasma.niobium",
  ["Nitrogen"] = "plasma.nitrogen",
  ["Oriharukon"] = "plasma.oriharukon",
  ["Palladium"] = "plasma.palladium",
  ["Phosphorus"] = "plasma.phosphorus",
  ["Potassium"] = "plasma.potassium",
  ["Praseodymium"] = "plasma.praseodymium",
  ["Promethium"] = "plasma.promethium",
  ["Radon"] = "plasma.radon",
  ["Raw Silicon"] = "plasma.silicon",
  ["Rhenium"] = "plasma.rhenium",
  ["Rhodium"] = "plasma.rhodium",
  ["Rubidium"] = "plasma.rubidium",
  ["Ruthenium"] = "plasma.ruthenium",
  ["Samarium"] = "plasma.samarium",
  ["Silver"] = "plasma.silver",
  ["Sodium"] = "plasma.sodium",
  ["Strontium"] = "plasma.strontium",
  ["Sulfur"] = "plasma.sulfur",
  ["Tantalum"] = "plasma.tantalum",
  ["Tellurium"] = "plasma.tellurium",
  ["Terbium"] = "plasma.terbium",
  ["Thallium"] = "plasma.thallium",
  ["Thorium 232"] = "plasma.thorium232",
  ["Thulium"] = "plasma.thulium",
  ["Tin"] = "plasma.tin",
  ["Titanium"] = "plasma.titanium",
  ["Tritium"] = "plasma.tritium",
  ["Tungsten"] = "plasma.tungsten",
  ["Uranium 235"] = "plasma.uranium235",
  ["Uranium 238"] = "plasma.uranium",
  ["Vanadium"] = "plasma.vanadium",
  ["Ytterbium"] = "plasma.ytterbium",
  ["Yttrium"] = "plasma.yttrium",
  ["Zinc"] = "plasma.zinc",
  ["Zirconium"] = "plasma.zirconium"
}


-- Kept for future Magmatter support. Do not switch CFG.mode without
-- separately checking the output-cell layout and target stock settings.
local magmatterPlasmaList = {
  ["Awakened Draconium"] = "plasma.draconiumawakened",
  ["Bedrockium"] = "plasma.bedrockium",
  ["Celestial Tungsten"] = "plasma.celestialtungsten",
  ["Chromatic Glass"] = "plasma.chromaticglass",
  ["Cosmic Neutronium"] = "plasma.cosmicneutronium",
  ["Draconium"] = "plasma.draconium",
  ["Dragonblood"] = "plasma.dragonblood",
  ["Flerovium"] = "plasma.flerovium_gt5u",
  ["Hypogen"] = "plasma.hypogen",
  ["Ichorium"] = "plasma.ichorium",
  ["Infinity"] = "plasma.infinity",
  ["Neutronium"] = "plasma.neutronium",
  ["Rhugnor"] = "plasma.rhugnor",
  ["Six-Phased Copper"] = "plasma.sixphasedcopper",
  ["Tritanium"] = "plasma.tritanium",
  ["Spatially Enlarged Fluid"] = "spatialfluid",
  ["Tachyon Rich Temporal Fluid"] = "temporalfluid"
}


local outputMe
local inputMe
local transposer
local database
local fakeRecipeName
local plasmaDb = {}


local state = {
  activeCpuName = nil,
  jobActive = false,
  flushInProgress = false
}


local runtime = {
  currentStatus = "starting",
  lastStock = nil,
  lastStockCheck = 0,
  pausedForStock = false,
  partialSince = nil,
  waitSince = nil,
  warnedLongWait = false
}


local function now()
  return computer.uptime()
end


local function log(level, message)
  print(string.format("[%s] %s", level, message))
end


local function fail(message)
  error(message, 0)
end


local function saveState()
  local f, err = io.open(CFG.stateFile, "w")
  if not f then
    log("WARN", "Cannot save recovery state: " .. tostring(err))
    return
  end
  f:write(serialization.serialize(state))
  f:close()
end


local function loadState()
  local f = io.open(CFG.stateFile, "r")
  if not f then return end
  local raw = f:read("*a")
  f:close()


  local ok, data = pcall(serialization.unserialize, raw)
  if ok and type(data) == "table" then
    state.activeCpuName = data.activeCpuName
    state.jobActive = data.jobActive == true
    state.flushInProgress = data.flushInProgress == true
  else
    log("WARN", "Recovery state file is unreadable; starting conservatively.")
  end
end


local function requiredProxy(address, label)
  local ok, proxy = pcall(component.proxy, address)
  if not ok or not proxy then
    fail(label .. " not found at " .. tostring(address))
  end
  return proxy
end


local function discoverDatabase()
  local iterator = component.list("database", true)
  local address = iterator()
  if not address then
    fail("Database Upgrade not found. Tier 3 Database Upgrade is required.")
  end
  return component.proxy(address)
end


local function countOccupied(side)
  local size = transposer.getInventorySize(side)
  if not size then return 0 end
  local count = 0
  for slot = 1, size do
    local n = transposer.getSlotStackSize(side, slot)
    if n and n > 0 then count = count + 1 end
  end
  return count
end


local function getCpuRows()
  local rows = inputMe.getCpus()
  if type(rows) ~= "table" then
    fail("input ME getCpus() returned no table")
  end
  return rows
end


local function getCpuBusy(row)
  if not row or not row.cpu then return true end
  local ok, busy = pcall(row.cpu.isBusy)
  if ok then return busy == true end
  return row.busy == true
end


local function getCpuActive(row)
  if not row or not row.cpu then return false end
  local ok, active = pcall(row.cpu.isActive)
  if ok then return active == true end
  return getCpuBusy(row)
end


local function findCpuByName(name)
  if not name then return nil end
  local rows = getCpuRows()
  for _, row in pairs(rows) do
    if row.name == name then return row end
  end
  return nil
end


local function findTargetCpu()
  local rows = getCpuRows()
  local found = nil


  for _, row in pairs(rows) do
    if row.name == CFG.cpuName then
      if found ~= nil then
        fail("More than one AE crafting CPU is named '" .. CFG.cpuName .. "'. The name must be unique.")
      end
      found = row
    end
  end


  return found
end


local function cancelCpuByName(name)
  local row = findCpuByName(name)
  if not row then
    return false, "CPU not found: " .. tostring(name)
  end


  if not getCpuBusy(row) then
    return true, "already idle"
  end


  local deadline = now() + 30
  while now() < deadline do
    if getCpuBusy(row) then
      local ok, canceled = pcall(row.cpu.cancel)
      if ok and canceled then
        os.sleep(0.2)
        return true, "canceled"
      end
    else
      return true, "became idle"
    end
    os.sleep(0.5)
  end


  return false, "CPU stayed busy but could not be canceled"
end


local function recoverPreviousJob()
  if not state.jobActive or not state.activeCpuName then return end


  log("WARN", "Recovering previous fake craft on CPU: " .. state.activeCpuName)
  local ok, reason = cancelCpuByName(state.activeCpuName)
  if not ok then
    fail("Safe recovery failed for CPU " .. state.activeCpuName .. ": " .. tostring(reason))
  end


  state.jobActive = false
  state.activeCpuName = nil
  saveState()
  log("INFO", "Previous fake craft recovery complete.")
end


local function recoverIoFlush()
  if not state.flushInProgress then return end


  log("WARN", "Recovering storage cells left in ME IO Port.")
  local deadline = now() + CFG.ioFlushTimeoutSeconds


  while now() < deadline do
    local ioCount = countOccupied(CFG.meIoPortSide)
    if ioCount > CFG.driveCount then
      fail("Recovery found " .. ioCount .. " occupied IO Port slots; refusing to move unrelated cells.")
    end
    if ioCount == 0 then
      local driveCount = countOccupied(CFG.meDriveSide)
      if driveCount ~= CFG.driveCount then
        fail("Recovery ended with " .. driveCount .. " cells in ME Drive; expected " .. CFG.driveCount)
      end
      state.flushInProgress = false
      saveState()
      log("INFO", "ME IO Port recovery complete.")
      return
    end


    local moved = transposer.transferItem(CFG.meIoPortSide, CFG.meDriveSide, 1)
    if not moved or moved <= 0 then
      os.sleep(0.5)
    else
      os.sleep(0.1)
    end
  end


  fail("ME IO Port recovery timed out. Check the three storage cells manually.")
end


local function fillDatabase()
  fakeRecipeName = "GodForge Fake " .. database.address:sub(1, 8)


  local ok = database.set(
    1,
    "minecraft:paper",
    0,
    "{display:{Name:\"" .. fakeRecipeName .. "\"}}"
  )
  if ok == false then fail("Cannot write fake recipe marker to Database slot 1") end


  plasmaDb = {}
  local slot = 2
  local sourceList = CFG.mode == "MAGMATTER" and magmatterPlasmaList or plasmaList


  local names = {}
  for name in pairs(sourceList) do table.insert(names, name) end
  table.sort(names)


  for _, name in ipairs(names) do
    local fluid = sourceList[name]
    local result = database.set(
      slot,
      "ae2fc:fluid_drop",
      0,
      "{Fluid:\"" .. fluid .. "\"}"
    )
    if result == false then
      fail("Cannot save " .. name .. " to Database slot " .. slot)
    end
    plasmaDb[name] = {slot = slot, fluid = fluid}
    slot = slot + 1
  end


  log("INFO", "Database loaded. Fake recipe: " .. fakeRecipeName)
end


local function getPattern()
  local pattern = inputMe.getInterfacePattern(CFG.patternSlot)
  if not pattern then
    fail("No encoded fluid crafting pattern in input ME Dual Interface slot " .. CFG.patternSlot)
  end
  return pattern
end


local function clearPattern()
  local pattern = getPattern()


  if pattern.outputs then
    for index in pairs(pattern.outputs) do
      inputMe.clearInterfacePatternOutput(CFG.patternSlot, index)
    end
  end


  if pattern.inputs then
    for index in pairs(pattern.inputs) do
      inputMe.clearInterfacePatternInput(CFG.patternSlot, index)
    end
  end


  -- Preserve the upstream 2.8.4 calling convention:
  -- (patternSlot, databaseAddress, databaseEntry, size, patternIndex)
  inputMe.setInterfacePatternOutput(CFG.patternSlot, database.address, 1, 1, 1)
  inputMe.setInterfacePatternInput(CFG.patternSlot, database.address, 1, 1, 1)
end


local function addOutput(outputs, key, label, amount, isLiquid)
  if outputs[key] then
    outputs[key].count = outputs[key].count + amount
  else
    outputs[key] = {
      label = label,
      count = amount,
      isLiquid = isLiquid
    }
  end
end


local function getOutputs()
  local items = outputMe.getItemsInNetwork({})
  local fluids = outputMe.getFluidsInNetwork()


  local outputs = {}
  local uniqueCount = 0


  for _, value in pairs(items or {}) do
    local originalLabel = value.label or value.name or "unknown"
    local label = originalLabel:match("Pile of%s(.+)%sDust")
    local coefficient = 1


    if not label then
      label = originalLabel:match("(.+)%sDust")
      coefficient = 9
    end


    if not label then label = originalLabel end


    local key = "I:" .. label
    if not outputs[key] then uniqueCount = uniqueCount + 1 end
    addOutput(outputs, key, label, (value.size or 0) * coefficient, false)
  end


  for _, value in pairs(fluids or {}) do
    local originalLabel = value.label or value.name or "unknown"
    local label = originalLabel:gsub("%s?[Gg][Aa][Ss]$", "")
    local key = "F:" .. label
    if not outputs[key] then uniqueCount = uniqueCount + 1 end
    addOutput(outputs, key, label, value.amount or value.size or 0, true)
  end


  return outputs, uniqueCount
end


local function expectedOutputCount()
  if CFG.mode == "MAGMATTER" then return 3 end
  return 7
end


local function encodePattern(outputs)
  local pattern = getPattern()


  if pattern.inputs then
    for index in pairs(pattern.inputs) do
      inputMe.clearInterfacePatternInput(CFG.patternSlot, index)
    end
  end


  local keys = {}
  for key in pairs(outputs) do table.insert(keys, key) end
  table.sort(keys)


  local sourceList = CFG.mode == "MAGMATTER" and magmatterPlasmaList or plasmaList
  local index = 1


  for _, key in ipairs(keys) do
    local value = outputs[key]
    local amount


    if CFG.mode == "MAGMATTER" then
      if value.label == "Spatially Enlarged Fluid" or value.label == "Tachyon Rich Temporal Fluid" then
        amount = value.count
      else
        local spatial
        local temporal
        for _, v in pairs(outputs) do
          if v.label == "Spatially Enlarged Fluid" then spatial = v.count end
          if v.label == "Tachyon Rich Temporal Fluid" then temporal = v.count end
        end
        if not spatial or not temporal then
          fail("Magmatter challenge is missing Spatially Enlarged Fluid or Tachyon Rich Temporal Fluid")
        end
        amount = math.abs(spatial - temporal) * 144
      end
    else
      amount = value.count * (value.isLiquid and 1000 or 144)
    end


    local db = plasmaDb[value.label]
    if not db or not sourceList[value.label] then
      fail("Unknown Exoticizer output: " .. tostring(value.label))
    end


    inputMe.setInterfacePatternInput(
      CFG.patternSlot,
      database.address,
      db.slot,
      amount,
      index
    )


    index = index + 1
  end


  return index - 1
end


local function getTargetStock()
  -- OpenComputers 1.11.20-GTNH (GTNH 2.8.4) exposes only
  -- getFluidsInNetwork(), not the later exact getFluidInNetwork(name) call.
  -- Fluids are normally a much smaller list than items; we never enumerate
  -- the main AE item storage here.
  local ok, fluids = pcall(inputMe.getFluidsInNetwork)
  if not ok then
    fail("Cannot read fluids from main AE: " .. tostring(fluids))
  end


  local amount = 0
  for _, fluid in pairs(fluids or {}) do
    if fluid.name == CFG.targetFluidName then
      amount = amount + (fluid.amount or fluid.size or 0)
    end
  end


  fluids = nil
  collectgarbage("collect")
  return amount
end


local function formatAmount(n)
  n = tonumber(n) or 0
  if n >= 1000000000 then return string.format("%.3fB", n / 1000000000) end
  if n >= 1000000 then return string.format("%.3fM", n / 1000000) end
  if n >= 1000 then return string.format("%.3fk", n / 1000) end
  return tostring(n)
end


local function flushOutputAe()
  state.flushInProgress = true
  saveState()


  local driveBefore = countOccupied(CFG.meDriveSide)
  local ioBefore = countOccupied(CFG.meIoPortSide)
  if driveBefore ~= CFG.driveCount then
    fail("ME Drive must contain exactly " .. CFG.driveCount .. " output-subnet cells; found " .. driveBefore)
  end
  if ioBefore ~= 0 then
    fail("ME IO Port must be empty before a flush; found " .. ioBefore .. " occupied slots")
  end


  for i = 1, CFG.driveCount do
    local moved = transposer.transferItem(CFG.meDriveSide, CFG.meIoPortSide, 1)
    if not moved or moved <= 0 then
      fail("Could not move storage cell " .. i .. " from ME Drive to ME IO Port")
    end
    os.sleep(0.1)
  end


  local targetOutputSlot = 6 + CFG.driveCount
  local deadline = now() + CFG.ioFlushTimeoutSeconds


  while now() < deadline do
    local stackSize = transposer.getSlotStackSize(CFG.meIoPortSide, targetOutputSlot)
    if stackSize and stackSize >= 1 then break end
    os.sleep(0.1)
  end


  if now() >= deadline then
    fail("Timed out waiting for ME IO Port to process all storage cells")
  end


  for i = 1, CFG.driveCount do
    local moved = transposer.transferItem(CFG.meIoPortSide, CFG.meDriveSide, 1)
    if not moved or moved <= 0 then
      fail("Could not return storage cell " .. i .. " from ME IO Port to ME Drive")
    end
    os.sleep(0.1)
  end


  state.flushInProgress = false
  saveState()
end


local function getFakeRecipe()
  for attempt = 1, 20 do
    local recipes = inputMe.getCraftables({label = fakeRecipeName})
    if recipes and recipes[1] then return recipes[1] end
    os.sleep(0.25)
  end
  return nil
end


local function requestFakeRecipe()
  local recipe = getFakeRecipe()
  if not recipe then
    fail("Fake recipe is not craftable in the main AE network")
  end


  while true do
    local cpuRow = findTargetCpu()
    if not cpuRow then
      fail("Dedicated AE crafting CPU '" .. CFG.cpuName .. "' is not visible.")
    elseif getCpuBusy(cpuRow) then
      runtime.currentStatus = "waiting for dedicated AE CPU " .. CFG.cpuName
      os.sleep(2)
    else
      runtime.currentStatus = "submitting fake craft to " .. CFG.cpuName


      -- GTNH 2.8.4 / OpenComputers 1.11.20-GTNH supports
      -- request(amount, prioritizePower, cpuName), so the fake job is pinned.
      local ok, status = pcall(recipe.request, 1, true, CFG.cpuName)
      if not ok or not status then
        fail("Cannot submit pinned fake craft on CPU " .. CFG.cpuName .. ": " .. tostring(status))
      end


      local deadline = now() + CFG.craftComputeTimeoutSeconds
      while status.isComputing() do
        if now() >= deadline then
          fail("AE crafting calculation timed out")
        end
        os.sleep(0.1)
      end


      local failed, reason = status.hasFailed()
      if failed then
        log("WARN", "Craft request failed on CPU " .. CFG.cpuName .. ": " .. tostring(reason))
        os.sleep(1)
      else
        state.activeCpuName = CFG.cpuName
        state.jobActive = true
        saveState()


        log("INFO", "Fake craft started on CPU: " .. CFG.cpuName)
        return status, CFG.cpuName
      end
    end
  end
end


local function finishCurrentFakeJob(cpuName)
  local ok, reason = cancelCpuByName(cpuName)
  if not ok then
    fail("Could not cancel our fake craft on CPU " .. tostring(cpuName) .. ": " .. tostring(reason))
  end


  state.jobActive = false
  state.activeCpuName = nil
  saveState()
end


local function waitForNextChallenge(status, cpuName)
  runtime.currentStatus = "waiting for Exoticizer cycle"
  runtime.waitSince = now()
  runtime.warnedLongWait = false


  while true do
    local _, count = getOutputs()


    if count ~= 0 then
      finishCurrentFakeJob(cpuName)
      log("INFO", "Next Exoticizer challenge detected; fake craft canceled safely.")
      return
    end


    local canceled = status.isCanceled()
    if canceled then
      state.jobActive = false
      state.activeCpuName = nil
      saveState()
      fail("Fake craft was canceled before the next Exoticizer challenge appeared")
    end


    local done = status.isDone()
    if done then
      state.jobActive = false
      state.activeCpuName = nil
      saveState()
      fail("Fake craft unexpectedly completed before the next Exoticizer challenge appeared")
    end


    local elapsed = now() - runtime.waitSince
    if elapsed > CFG.longWaitWarningSeconds and not runtime.warnedLongWait then
      runtime.warnedLongWait = true
      log("WARN", "More than " .. CFG.longWaitWarningSeconds .. " seconds waiting for Exoticizer output.")
    end


    os.sleep(1)
  end
end


local function runChallenge(outputs, count)
  local expected = expectedOutputCount()
  if count ~= expected then
    fail("Exoticizer output count is " .. count .. ", expected exactly " .. expected)
  end


  runtime.currentStatus = "encoding fake pattern"
  local encoded = encodePattern(outputs)
  if encoded ~= expected then
    fail("Encoded input count is " .. encoded .. ", expected " .. expected)
  end


  runtime.currentStatus = "flushing output subnet"
  flushOutputAe()


  runtime.currentStatus = "requesting plasmas"
  local status, cpuName = requestFakeRecipe()


  waitForNextChallenge(status, cpuName)
end


local function validateSetup()
  outputMe = requiredProxy(CFG.outputMeInterfaceAddress, "Output ME Dual Interface")
  inputMe = requiredProxy(CFG.inputMeInterfaceAddress, "Input ME Dual Interface")
  transposer = requiredProxy(CFG.transposerAddress, "Transposer")
  database = discoverDatabase()


  local driveSize = transposer.getInventorySize(CFG.meDriveSide)
  local ioSize = transposer.getInventorySize(CFG.meIoPortSide)


  if driveSize ~= 10 then
    log("WARN", "ME Drive side reports inventory size " .. tostring(driveSize) .. " instead of 10.")
  end
  if ioSize ~= 12 then
    log("WARN", "ME IO Port side reports inventory size " .. tostring(ioSize) .. " instead of 12.")
  end


  getPattern()


  local cpus = getCpuRows()
  local cpuCount = 0
  for _ in pairs(cpus) do cpuCount = cpuCount + 1 end
  if cpuCount < 1 then fail("No AE crafting CPUs are visible from the input ME interface") end


  local targetCpu = findTargetCpu()
  if not targetCpu then
    fail("Dedicated AE crafting CPU '" .. CFG.cpuName .. "' was not found. Rename any block in one Crafting CPU multiblock to exactly " .. CFG.cpuName .. " using an Anvil or Inscriber, then rebuild/let the CPU reform.")
  end


  log("INFO", "Dedicated AE CPU found: " .. CFG.cpuName)
  log("INFO", "Components validated.")
  log("INFO", "AE crafting CPUs visible: " .. cpuCount)
  log("INFO", "Crafting Monitor blocks are NOT required by this custom controller.")
end


local function initialize()
  loadState()
  validateSetup()


  recoverIoFlush()
  recoverPreviousJob()


  local restingDriveCount = countOccupied(CFG.meDriveSide)
  local restingIoCount = countOccupied(CFG.meIoPortSide)
  if restingDriveCount ~= CFG.driveCount or restingIoCount ~= 0 then
    fail("Storage-cell layout is not at rest: ME Drive=" .. restingDriveCount .. ", ME IO Port=" .. restingIoCount .. ". Expected drive=" .. CFG.driveCount .. ", ioPort=0.")
  end


  fillDatabase()
  clearPattern()


  -- Stock scanning is deliberately after crash recovery.
  runtime.lastStock = getTargetStock()
  log("INFO", "Current DQGP stock: " .. formatAmount(runtime.lastStock) .. " / " .. formatAmount(CFG.targetAmount))


  log("INFO", "God Forge custom controller ready.")
  log("INFO", "Target: keep Degenerate Quark Gluon Plasma at 100,000,000 L.")
end


local function loop()
  local nextStockCheck = 0


  while true do
    if not CFG.productionEnabled then
      runtime.currentStatus = "disabled in config"
      os.sleep(2)
    else
      if now() >= nextStockCheck then
        runtime.lastStock = getTargetStock()
        nextStockCheck = now() + CFG.stockPollSeconds
      end


      if runtime.lastStock >= CFG.targetAmount then
        runtime.currentStatus = "stock target reached"


        if not runtime.pausedForStock then
          runtime.pausedForStock = true
          log(
            "INFO",
            "DQGP target reached: " ..
            formatAmount(runtime.lastStock) ..
            " >= " ..
            formatAmount(CFG.targetAmount) ..
            ". New cycles are paused."
          )
        end


        os.sleep(CFG.idlePollSeconds)
      else
        if runtime.pausedForStock then
          runtime.pausedForStock = false
          log(
            "INFO",
            "DQGP below target: " ..
            formatAmount(runtime.lastStock) ..
            ". Production resumed."
          )
        end


        runtime.currentStatus = "waiting for Exoticizer challenge"
        local outputs, count = getOutputs()
        local expected = expectedOutputCount()


        if count >= expected then
          runtime.partialSince = nil
          runChallenge(outputs, count)
          nextStockCheck = 0
        elseif count > 0 then
          if not runtime.partialSince then runtime.partialSince = now() end
          if now() - runtime.partialSince > CFG.longWaitWarningSeconds then
            log("WARN", "Partial Exoticizer challenge has been present for more than " .. CFG.longWaitWarningSeconds .. " seconds.")
            runtime.partialSince = now()
          end
          os.sleep(CFG.idlePollSeconds)
        else
          runtime.partialSince = nil
          os.sleep(CFG.idlePollSeconds)
        end
      end
    end
  end
end


local function runCheckOnly()
  loadState()
  validateSetup()


  local stock = getTargetStock()
  log("CHECK", "DQGP stock: " .. formatAmount(stock) .. " / " .. formatAmount(CFG.targetAmount))


  local driveCount = countOccupied(CFG.meDriveSide)
  local ioCount = countOccupied(CFG.meIoPortSide)
  log("CHECK", "Storage cells: ME Drive=" .. driveCount .. ", ME IO Port=" .. ioCount)


  if state.flushInProgress then
    log("WARN", "Recovery state says a cell flush was interrupted. A normal run will attempt recovery.")
  elseif driveCount ~= CFG.driveCount or ioCount ~= 0 then
    fail("Storage cells are not in the resting layout. Expected ME Drive=" .. CFG.driveCount .. ", ME IO Port=0.")
  end


  if state.jobActive then
    log("WARN", "Recovery state says a fake craft was active on CPU " .. tostring(state.activeCpuName) .. ". A normal run will cancel only that recorded CPU.")
  end


  local outputs, outputCount = getOutputs()
  log("CHECK", "Exoticizer output entries visible: " .. outputCount .. " (expected 0 or " .. expectedOutputCount() .. ")")


  for _, value in pairs(outputs) do
    local sourceList = CFG.mode == "MAGMATTER" and magmatterPlasmaList or plasmaList
    if not sourceList[value.label] then
      fail("Unknown Exoticizer output during check: " .. tostring(value.label))
    end
  end


  if outputCount ~= 0 and outputCount ~= expectedOutputCount() then
    log("WARN", "A partial Exoticizer challenge is currently present. Do not start production until all expected outputs are visible.")
  end


  log("CHECK", "OK. No patterns, cells, CPUs or crafting jobs were changed.")
end




local function emergencyCleanup()
  if state.jobActive and state.activeCpuName then
    log("WARN", "Runtime error: trying to cancel only our recorded CPU " .. state.activeCpuName)
    local ok, reason = cancelCpuByName(state.activeCpuName)
    if ok then
      state.jobActive = false
      state.activeCpuName = nil
      saveState()
    else
      log("ERROR", "Emergency CPU cleanup failed: " .. tostring(reason))
    end
  end
end


local ok, err = xpcall(function()
  if arg and (arg[1] == "check" or arg[1] == "--check") then
    runCheckOnly()
  else
    initialize()
    loop()
  end
end, debug.traceback)


if not ok then
  print("")
  log("ERROR", tostring(err))
  pcall(emergencyCleanup)
  print("")
  print("The recovery state was kept where needed.")
  print("Fix the reported problem and run this file again.")
  os.exit(1)
end