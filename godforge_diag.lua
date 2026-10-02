-- godforge_diag.lua
-- Read-only diagnostic for the currently encoded God Forge fake pattern.
-- Does not edit patterns, move cells, cancel CPUs or start crafts.

local component = require("component")

local function countCpus(proxy)
  local ok, cpus = pcall(proxy.getCpus)
  if not ok or type(cpus) ~= "table" then return 0 end
  local n = 0
  for _ in pairs(cpus) do n = n + 1 end
  return n
end

local inputAddress = nil
local input = nil

for address in component.list("me_interface", true) do
  local ok, proxy = pcall(component.proxy, address)
  if ok and proxy and countCpus(proxy) > 0 then
    if input then
      print("[WARN] More than one ME interface sees crafting CPUs.")
    end
    inputAddress = address
    input = proxy
  end
end

if not input then
  error("Cannot find INPUT ME interface (no me_interface with crafting CPUs visible).", 0)
end

print("============================================================")
print(" God Forge current fake-pattern diagnostic")
print(" READ ONLY - no pattern/cell/CPU/craft changes")
print("============================================================")
print("[INFO] INPUT ME Interface: " .. inputAddress)

local pattern = input.getInterfacePattern(1)
if not pattern then
  error("No pattern in INPUT ME Interface slot 1.", 0)
end

local inputs = pattern.inputs or {}
print("[INFO] Encoded inputs: " .. tostring(#inputs))
print("")

if #inputs == 0 then
  print("[FAIL] The fake pattern currently has no inputs.")
  print("       Do NOT restart production yet.")
  return
end

local missing = 0

for i, req in ipairs(inputs) do
  local name = req.name or "?"
  local need = tonumber(req.count) or 0

  local stored = 0
  local itemCraftableFlag = false

  local okItems, items = pcall(input.getItemsInNetwork, {label = name})
  if okItems and type(items) == "table" then
    for _, item in pairs(items) do
      stored = stored + (tonumber(item.size) or 0)
      if item.isCraftable == true then
        itemCraftableFlag = true
      end
    end
  end

  local craftableCount = 0
  local okCraft, craftables = pcall(input.getCraftables, {label = name})
  if okCraft and type(craftables) == "table" then
    for _ in pairs(craftables) do craftableCount = craftableCount + 1 end
  end

  local enoughStored = stored >= need
  local canCraft = craftableCount > 0 or itemCraftableFlag
  local status

  if enoughStored then
    status = "OK-STORED"
  elseif canCraft then
    status = "CRAFTABLE"
  else
    status = "MISSING"
    missing = missing + 1
  end

  print(string.format(
    "[%d] %s | need=%s | visible-as-drop=%s | craftable=%s | %s",
    i,
    name,
    tostring(need),
    tostring(stored),
    canCraft and "YES" or "NO",
    status
  ))
end

print("")
print("------------------------------------------------------------")
if missing == 0 then
  print("[RESULT] No completely missing fake-pattern inputs were found.")
  print("         If AE still says missing resources, at least one")
  print("         CRAFTABLE input has a broken/incomplete crafting tree,")
  print("         or the Fluid Discretizer is not exposing enough volume.")
else
  print("[RESULT] Completely missing inputs: " .. tostring(missing))
  print("         These are the first things to fix in the main AE.")
end
print("------------------------------------------------------------")
