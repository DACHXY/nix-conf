--!nonstrict
-- Panel: the receivers that answer `owly browse`, one card row each, styled
-- like dachxy/vpn's panel. The send button hands the receiver to owly-drop
-- (owly.nix), which asks for the files and runs `owly send`.

local devices = {}
local scanning = false
local failed = nil

local function deviceRow(d)
  return ui.row({
    key = "device-" .. d.id,
    align = "center",
    gap = 8,
    paddingH = 12,
    paddingV = 9,
    radius = 8,
    fill = "surface_variant/0.35",
  }, {
    ui.glyph({ name = "device-mobile", size = 16, color = "on_surface_variant" }),
    ui.label({ text = d.name, color = "on_surface", flexGrow = 1 }),
    ui.button({
      glyph = "send",
      variant = "default",
      controlSize = "sm",
      tooltip = "Send files",
      onClick = function()
        noctalia.runAsync({ "owly-drop", d.id, d.name })
        panel.close()
      end,
    }),
  })
end

local function render()
  local rows = {}

  table.insert(rows, ui.row({ align = "center", gap = 8 }, {
    ui.label({ text = "AirDrop", fontWeight = "bold", fontSize = 15, flexGrow = 1 }),
    ui.button({
      glyph = "refresh",
      variant = "ghost",
      controlSize = "sm",
      tooltip = "Search again",
      enabled = not scanning,
      onClick = function()
        scan()
      end,
    }),
  }))

  if failed ~= nil then
    table.insert(rows, ui.box({ radius = 6, padding = 8, fill = true }, {
      ui.label({ text = failed, color = "error", fontSize = 11 }),
    }))
  elseif scanning then
    table.insert(rows, ui.label({ text = "Looking for nearby devices…", color = "on_surface_variant", fontSize = 12 }))
  elseif #devices == 0 then
    table.insert(rows, ui.label({
      text = "No devices found. The other device has to be unlocked, with AirDrop set to Everyone.",
      color = "on_surface_variant",
      fontSize = 12,
    }))
  end

  for _, d in devices do
    table.insert(rows, deviceRow(d))
  end

  panel.render(ui.column({ gap = 6, padding = 6 }, rows))
end

function scan()
  if scanning then
    return
  end
  scanning = true
  failed = nil
  render()
  noctalia.runAsync({ "owly", "browse", "--seconds", "8" }, function(result)
    scanning = false
    devices = {}
    -- 00e513333c7f   ";D" ([fe80::bc86:85ff:fe1f:609%94]:8770)
    for line in (result.stdout or ""):gmatch("[^\r\n]+") do
      local id, name = line:match('^(%x+)%s+"(.-)"%s+%(')
      if id then
        table.insert(devices, { id = id, name = name })
      end
    end
    if #devices == 0 and result.exitCode ~= 0 then
      local err = (result.stderr or ""):match("([^\r\n]+)%s*$")
      failed = "owly browse failed" .. (err and (": " .. err) or "") .. ". Is AirDrop on? Right-click the bar icon."
    end
    render()
  end)
end

function onOpen(_context)
  render()
  scan()
end

render()
