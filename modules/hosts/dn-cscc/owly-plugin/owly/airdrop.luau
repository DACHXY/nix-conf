--!nonstrict
-- Bar widget: AirDrop through owly on dn-cscc.
--   left click  -> open the send panel
--   right click -> stop both owly units, or start both again
--
-- Both units have to run for the machine to answer. A glyph rather than an
-- image, so the colour and size resolve through the bar host like every other
-- widget; "on_surface" is the host-default sentinel, "error" means half on.

local PANEL_ID = "dachxy/owly:send"

local radio = false
local receive = false
local checking = false

local function render()
  barWidget.setText("")
  if radio and receive then
    barWidget.setGlyph("broadcast")
    barWidget.setGlyphColor("on_surface")
    barWidget.setTooltip("AirDrop\nClick: send to a nearby device\nRight-click: turn off")
  elseif radio or receive then
    barWidget.setGlyph("broadcast")
    barWidget.setGlyphColor("error")
    barWidget.setTooltip("AirDrop is half on: owly-radio " .. (radio and "active" or "inactive")
      .. ", owly-receive " .. (receive and "active" or "inactive") .. "\nRight-click: turn off")
  else
    barWidget.setGlyph("broadcast-off")
    barWidget.setGlyphColor("on_surface")
    barWidget.setTooltip("AirDrop is off\nRight-click: turn on")
  end
end

local function check()
  if checking then
    return
  end
  checking = true
  noctalia.runAsync({ "systemctl", "is-active", "owly-radio", "owly-receive" }, function(result)
    checking = false
    local i = 0
    for line in (result.stdout or ""):gmatch("[^\r\n]+") do
      i += 1
      if i == 1 then
        radio = line == "active"
      elseif i == 2 then
        receive = line == "active"
      end
    end
    render()
  end)
end

function update()
  noctalia.setUpdateInterval(3000)
  check()
end

function onClick()
  noctalia.togglePanel(PANEL_ID)
end

function onRightClick()
  local argv = (radio or receive)
      and { "systemctl", "stop", "owly-receive", "owly-radio" }
    or { "systemctl", "start", "owly-radio", "owly-receive" }
  noctalia.runAsync(argv, check)
end

render()
