-------------------------------------------------------------------------------
--  EnvironmentPing_Options.lua -- the options window.
--
--  Built on EnvironmentPingStyle.lua (palette, fonts, widgets) and
--  EnvironmentPingPixel.lua (the physical pixel grid). The window lives at the
--  user's normal UI scale; every size and offset is snapped to a physical pixel
--  and re-snapped when the scale changes (see Layout below).
--
--  Two rules do the heavy lifting and are worth stating before the code:
--
--    * EVERY BUILDER RETURNS THE VERTICAL SPACE IT CONSUMED, and the page is a
--      cursor that only ever subtracts. No call site knows a row's height, so
--      no call site can guess one wrong, and a row that grows moves everything
--      below it without a single edit. Whitespace goes through the same
--      channel -- a Spacer that returns its height -- so the cursor stays the
--      one source of truth.
--    * EVERY ROW ANCHORS TO BOTH EDGES, and every FontString is bounded on
--      both sides with SetWordWrap(false). A text region free to grow is what
--      turns a long localized string into an overlap.
--
--  Colour is white or black at an alpha over a near-black ground with a slight
--  teal cast, plus exactly ONE accent -- the same teal-green the wheel uses.
--  Nothing else has a hue, which is what makes the accent mean "on" rather
--  than "decorated".
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...

local S = ns.Style
local P = ns.Pixel
local size = S.size
local Unpack = S.Unpack

local PAD = size.PAD
local ROW_H = size.ROW_H
local COMPACT_H = size.ROW_H_SM
local SECTION_H = 28
local LABEL_GAP = size.GAP
local WINDOW_W = 380
local HINT_H = 24           -- the strip under the page that holds the hint line

local TEXT_SEC = S.color.textFaint

local window, content

-------------------------------------------------------------------------------
--  Layout. Everything positioned here is positioned by a function that can be
--  run again: it is applied now and again whenever the UI scale changes, so a
--  size that was snapped to one scale's pixel grid is never left on another's.
-------------------------------------------------------------------------------
local function Layout(fn)
    fn()
    P.OnRescale(fn)
end

-------------------------------------------------------------------------------
--  Small shared helpers
-------------------------------------------------------------------------------

-- The row shell every option row shares: full width between the page's pads and
-- a stripe so a long list stays readable.
local function Row(parent, y, height, index)
    local r = CreateFrame("Frame", nil, parent)
    Layout(function()
        r:ClearAllPoints()
        P.Size(r, nil, height)
        P.Point(r, "TOPLEFT", parent, "TOPLEFT", PAD, y)
        P.Point(r, "TOPRIGHT", parent, "TOPRIGHT", -PAD, y)
    end)
    local stripe = (index and index % 2 == 0) and S.color.rowEven or S.color.rowOdd
    S.Fill(r, stripe)
    return r
end

-- A row's label: bounded on the left by the row's pad and on the right by the
-- control the caller names.
local function RowLabel(r, text, rightOf)
    local label = S.Label(r, S.fontBody, "LEFT")
    Layout(function()
        label:ClearAllPoints()
        P.Point(label, "LEFT", r, "LEFT", size.ROW_PAD, 0)
        P.Point(label, "RIGHT", rightOf, "LEFT", -LABEL_GAP, 0)
    end)
    label:SetText(text)
    return label
end

local function Tooltip(frame, title, body)
    if not body then return end
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(title, 1, 1, 1)
        GameTooltip:AddLine(body, 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-------------------------------------------------------------------------------
--  Widgets. Each owns its own geometry and returns the height it used.
-------------------------------------------------------------------------------
local W = {}

function W.Spacer(_, _, h)
    return nil, h
end

function W.Section(parent, y, text)
    local r = CreateFrame("Frame", nil, parent)
    Layout(function()
        r:ClearAllPoints()
        P.Size(r, nil, SECTION_H)
        P.Point(r, "TOPLEFT", parent, "TOPLEFT", PAD, y)
        P.Point(r, "TOPRIGHT", parent, "TOPRIGHT", -PAD, y)
    end)
    S.Heading(r, text)
    return r, SECTION_H
end

-- A toggle. Its "on" state is the only place the accent appears in a row,
-- which is what makes a page of settings scannable without reading it. The
-- switch is only a picture of the state: the row owns the click.
function W.Toggle(parent, y, index, text, tip, get, set)
    local r = Row(parent, y, ROW_H, index)

    local switch = S.Switch(r)
    Layout(function()
        switch:ClearAllPoints()
        P.Point(switch, "RIGHT", r, "RIGHT", -size.ROW_PAD, 0)
    end)

    RowLabel(r, text, switch)

    local function Paint()
        switch:SetChecked(get())
    end

    -- The widget owns the control, so the widget owns its refresh. A caller
    -- that had to remember to repaint would eventually forget.
    r.Paint = Paint
    r:EnableMouse(true)
    r:SetScript("OnMouseUp", function()
        set(not get())
        Paint()
        if ns.RefreshPage then ns.RefreshPage() end
    end)
    Tooltip(r, text, tip)
    Paint()

    return r, ROW_H
end

-- The keybind row. Writes the REAL binding with SetBinding/SaveBindings rather
-- than storing a key of its own, so the key shows up in Blizzard's own Key
-- Bindings panel, survives a binding-set switch, and cannot drift out of step
-- with what the game thinks is bound.
--
-- Capture goes through Blizzard's own four helpers (BindingUtil.lua) rather
-- than a hand-rolled modifier check: GetConvertedKeyOrButton normalises the
-- raw key, IsKeyPressIgnoredForBinding is what lets a bare modifier pass
-- through so it can be held as part of a chord, and
-- CreateKeyChordStringUsingMetaKeyState assembles the chord in the exact order
-- the binding system expects. Building "ALT-CTRL-SHIFT-" by hand is the
-- classic way to produce a string the game will not match.
function W.Keybind(parent, y, index, text, tip)
    local r = Row(parent, y, ROW_H, index)
    local listening = false

    local btn = S.Button(r, "", { width = size.BTN_W, height = size.BTN_H })
    Layout(function()
        btn:ClearAllPoints()
        P.Point(btn, "RIGHT", r, "RIGHT", -size.ROW_PAD, 0)
    end)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local keyText = btn.Label

    RowLabel(r, text, btn)

    -- The button's own edge and ink carry the state: accent while listening.
    local function Paint()
        btn:SetAccented(listening)
        if listening then
            keyText:SetText("Press a key...")
            return
        end
        local key = GetBindingKey("ENVIRONMENTPING_HOLD")
        if key then
            keyText:SetText(GetBindingText(key) or key)
        else
            keyText:SetText("Not bound")
            keyText:SetTextColor(Unpack(TEXT_SEC))
        end
    end

    local function StopListening()
        listening = false
        btn:EnableKeyboard(false)
        btn:SetPropagateKeyboardInput(true)
        Paint()
    end

    -- SaveBindings raises "can't be done in combat" and SetBinding would
    -- already be half-applied by then, so nothing is touched until combat ends.
    local function Commit(chord)
        if InCombatLockdown() then
            UIErrorsFrame:AddMessage("EnvironmentPing: keybinds can't be changed in combat.", 1, 0.3, 0.3)
            return
        end

        -- Clear every key currently held, which is what rebinding means -- but
        -- collect them FIRST: SetBinding mutates what GetBindingKey returns,
        -- and clearing while iterating it drops the second key.
        local held = { GetBindingKey("ENVIRONMENTPING_HOLD") }
        for _, k in ipairs(held) do SetBinding(k, nil) end

        if chord then
            -- SetBinding takes a chord away from whatever held it without
            -- asking, so say whose it was rather than letting the user find
            -- out later that something else stopped working.
            local stolenFrom = GetBindingAction(chord)
            if stolenFrom and stolenFrom ~= "" and stolenFrom ~= "ENVIRONMENTPING_HOLD" then
                UIErrorsFrame:AddMessage("EnvironmentPing: took " .. (GetBindingText(chord) or chord)
                    .. " from " .. (GetBindingName(stolenFrom) or stolenFrom) .. ".", 1, 0.82, 0)
            end
            SetBinding(chord, "ENVIRONMENTPING_HOLD")
        end

        SaveBindings(GetCurrentBindingSet())
        -- UPDATE_BINDINGS follows and re-applies the override routing, so
        -- nothing else has to be poked here.
    end

    btn:SetScript("OnClick", function(self, button)
        if listening then return end
        if button == "RightButton" then
            Commit(nil)
            Paint()
            return
        end
        if InCombatLockdown() then
            UIErrorsFrame:AddMessage("EnvironmentPing: keybinds can't be changed in combat.", 1, 0.3, 0.3)
            return
        end
        listening = true
        self:EnableKeyboard(true)
        Paint()
    end)

    btn:SetScript("OnKeyDown", function(self, key)
        if not listening then self:SetPropagateKeyboardInput(true) return end
        key = GetConvertedKeyOrButton(key)
        -- Bare modifiers and anything the binding system ignores pass straight
        -- through, so the user can hold them as part of the chord.
        if IsKeyPressIgnoredForBinding(key) then
            self:SetPropagateKeyboardInput(true)
            return
        end
        self:SetPropagateKeyboardInput(false)
        if key ~= "ESCAPE" then
            Commit(CreateKeyChordStringUsingMetaKeyState(key))
        end
        StopListening()
    end)

    -- Mouse buttons are legal binding keys too, but not the left one: the
    -- wheel claims BUTTON1 for itself the moment the hold key goes down, so a
    -- hold key bound to it could never be released. HookScript, because the
    -- button widget owns the press visual in OnMouseDown.
    btn:HookScript("OnMouseDown", function(_, button)
        if not listening then return end
        if button == "LeftButton" or button == "RightButton" then
            StopListening()
            return
        end
        Commit(CreateKeyChordStringUsingMetaKeyState(GetConvertedKeyOrButton(button)))
        StopListening()
    end)

    btn:HookScript("OnEnter", function()
        if listening then return end
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:AddLine(text, 1, 1, 1)
        GameTooltip:AddLine("Left-click, then press the key you want.\n"
            .. "Escape cancels. Right-click here to unbind.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    btn:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    Tooltip(r, text, tip)
    r.Paint = Paint
    Paint()

    return r, ROW_H
end

-- A stepper rather than a slider, deliberately: the values here are small
-- integers where precision beats sweep, and a hand-rolled slider is a hundred
-- more lines of drag maths that can be subtly wrong at a non-default UI scale.
function W.Stepper(parent, y, index, text, tip, get, set, minV, maxV, step, suffix)
    local r = Row(parent, y, ROW_H, index)

    local function Button(glyph, delta)
        local b = S.Button(r, glyph, { width = size.CTRL_H, height = size.CTRL_H })
        b.delta = delta
        return b
    end

    local plus = Button("+", step)
    Layout(function()
        plus:ClearAllPoints()
        P.Point(plus, "RIGHT", r, "RIGHT", -size.ROW_PAD, 0)
    end)

    local value = S.Label(r, S.fontNum, "CENTER")
    Layout(function()
        value:ClearAllPoints()
        P.Size(value, 52, nil)
        P.Point(value, "RIGHT", plus, "LEFT", -6, 0)
    end)

    local minus = Button("-", -step)
    Layout(function()
        minus:ClearAllPoints()
        P.Point(minus, "RIGHT", value, "LEFT", -6, 0)
    end)

    RowLabel(r, text, minus)

    local function Paint()
        value:SetText(tostring(get()) .. (suffix or ""))
        local v = get()
        minus:SetEnabled(v > minV)
        plus:SetEnabled(v < maxV)
    end

    local function Bump(self)
        local v = get() + self.delta
        if v < minV then v = minV elseif v > maxV then v = maxV end
        set(v)
        Paint()
    end
    minus:SetScript("OnClick", Bump)
    plus:SetScript("OnClick", Bump)

    Tooltip(r, text, tip)
    r.Paint = Paint
    Paint()

    return r, ROW_H
end

-- The ping list. One row per POSITION rather than per type: a row is told
-- which type it currently shows, so reordering repaints six rows in place and
-- never has to move a frame or re-run the page cursor.
--
-- Dragging is by the grip on the left and nowhere else, so the rest of the
-- row keeps its one job -- click to toggle -- and a slightly-moved click can
-- never be mistaken for a reorder. The list reorders LIVE under the cursor:
-- the dragged type swaps places the moment the pointer crosses into another
-- row, which is what makes a drag read as moving the row rather than as
-- choosing a slot to drop it in.
local pingRows = {}
local GRIP_W = 14

local function PingRowAt(y)
    -- Rows and the cursor are compared in the page's own space, so a UI scale
    -- change between opening and dragging cannot skew the hit test.
    local n = #pingRows
    if n == 0 then return nil end
    if y >= (pingRows[1]:GetTop() or 0) then return 1 end
    if y <= (pingRows[n]:GetBottom() or 0) then return n end
    for i = 1, n do
        local r = pingRows[i]
        local top, bottom = r:GetTop(), r:GetBottom()
        if top and bottom and y <= top and y >= bottom then return i end
    end
    return nil
end

-- One drag at a time, driven from a frame of its own so an OnUpdate is only
-- ever paid while the mouse is actually held on a grip.
local drag = CreateFrame("Frame")
drag:Hide()
drag.pos = nil

local function PaintPingRows()
    for _, r in ipairs(pingRows) do r.Paint() end
end

local function EndDrag(commit)
    if not drag.pos then return end
    drag.pos = nil
    drag:Hide()
    PaintPingRows()
    if commit then ns.Refresh() end
end

drag:SetScript("OnUpdate", function()
    if not drag.pos then drag:Hide() return end
    -- The up edge normally arrives at the grip that took the down edge, but
    -- a release swallowed by a window losing focus would leave the drag
    -- armed forever; the button state is the ground truth.
    if not IsMouseButtonDown("LeftButton") then EndDrag(true) return end
    local _, y = InputUtil.GetCursorPosition(content)
    local target = PingRowAt(y)
    if target and target ~= drag.pos and ns.MoveType(drag.pos, target) then
        drag.pos = target
        PaintPingRows()
    end
end)

function W.PingRow(parent, y, index, pos)
    local r = Row(parent, y, COMPACT_H, index)
    r.pos = pos

    -- The accent frame that marks the row being dragged. Off until then.
    local outline = S.Border(r, { S.color.accent[1], S.color.accent[2], S.color.accent[3], 0.9 },
        "OVERLAY", 2)
    outline:SetShown(false)

    local switch = S.Switch(r)
    Layout(function()
        switch:ClearAllPoints()
        P.Point(switch, "RIGHT", r, "RIGHT", -size.ROW_PAD, 0)
    end)

    -- The grip: three short horizontal strips, the universal "this moves"
    -- glyph. Its hit area is the full row height and wider than the glyph,
    -- because a 10px target is not one a player can find in a hurry.
    local grip = CreateFrame("Frame", nil, r)
    Layout(function()
        grip:ClearAllPoints()
        P.Size(grip, GRIP_W + size.ROW_PAD, nil)
        P.Point(grip, "TOPLEFT", r, "TOPLEFT", 0, 0)
        P.Point(grip, "BOTTOMLEFT", r, "BOTTOMLEFT", 0, 0)
    end)
    grip:EnableMouse(true)
    grip.lines = {}
    for i = 1, 3 do
        local t = grip:CreateTexture(nil, "ARTWORK")
        t:SetColorTexture(1, 1, 1, 1)
        P.Edge(t)
        Layout(function()
            t:ClearAllPoints()
            P.Size(t, 10, nil)
            t:SetHeight(P.Hairline(r) * 2)
            P.Point(t, "CENTER", grip, "CENTER", size.ROW_PAD * 0.5, (2 - i) * 4)
        end)
        grip.lines[i] = t
    end

    local icon = r:CreateTexture(nil, "ARTWORK")
    Layout(function()
        icon:ClearAllPoints()
        P.Size(icon, COMPACT_H - 10, COMPACT_H - 10)
        P.Point(icon, "LEFT", grip, "RIGHT", 0, 0)
    end)

    local label = S.Label(r, S.fontBody, "LEFT")
    Layout(function()
        label:ClearAllPoints()
        P.Point(label, "LEFT", icon, "RIGHT", LABEL_GAP, 0)
        P.Point(label, "RIGHT", switch, "LEFT", -LABEL_GAP, 0)
    end)

    local db = ns.DB()

    local function Def()
        return ns.OrderedTypes()[r.pos]
    end

    local function PaintGrip(hover)
        local a = hover and 0.9 or 0.35
        for _, t in ipairs(grip.lines) do
            t:SetVertexColor(1, 1, 1, a)
        end
    end

    local function Paint()
        local def = Def()
        if not def then r:Hide() return end
        r:Show()
        icon:SetAtlas(def.atlas)
        label:SetText(def.name)

        local on = db.enabledTypes[def.key] and true or false
        switch:SetChecked(on)
        if on then
            icon:SetAlpha(1)
            label:SetTextColor(Unpack(S.color.text))
        else
            icon:SetAlpha(0.35)
            label:SetTextColor(Unpack(TEXT_SEC))
        end

        outline:SetShown(drag.pos == r.pos)
        PaintGrip(drag.pos == r.pos or grip:IsMouseOver())
    end

    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or drag.pos then return end
        drag.pos = r.pos
        drag:Show()
        PaintPingRows()
    end)
    grip:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then EndDrag(true) end
    end)
    grip:SetScript("OnEnter", function()
        PaintGrip(true)
        local def = Def()
        if not def then return end
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        GameTooltip:AddLine(def.name, 1, 1, 1)
        GameTooltip:AddLine("Drag to reorder. The top of this list is the top of the wheel, "
            .. "and the rest follow clockwise.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function()
        GameTooltip:Hide()
        PaintGrip(drag.pos == r.pos)
    end)

    r:EnableMouse(true)
    r:SetScript("OnMouseUp", function()
        if drag.pos then return end
        local def = Def()
        if not def then return end
        local on = not db.enabledTypes[def.key]
        -- An empty wheel would leave the player holding a key that can only
        -- ever cancel, so the last entry standing refuses to be turned off.
        if not on then
            local count = 0
            for _, t in ipairs(ns.PING_TYPES) do
                if db.enabledTypes[t.key] then count = count + 1 end
            end
            if count <= 1 then
                UIErrorsFrame:AddMessage("EnvironmentPing: the wheel needs at least one ping.", 1, 0.3, 0.3)
                return
            end
        end
        db.enabledTypes[def.key] = on
        Paint()
        ns.Refresh()
    end)
    r:SetScript("OnEnter", function()
        local def = Def()
        if not def then return end
        GameTooltip:SetOwner(r, "ANCHOR_RIGHT")
        GameTooltip:AddLine(def.name, 1, 1, 1)
        GameTooltip:AddLine("Show this ping on the wheel.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)

    r.Paint = Paint
    pingRows[pos] = r
    Paint()

    return r, COMPACT_H
end

-------------------------------------------------------------------------------
--  The page. A cursor, and no other arithmetic anywhere.
-------------------------------------------------------------------------------
local rows = {}

local function BuildPage(parent)
    local db = ns.DB()
    local y, h = -PAD
    local i = 0
    local function next_index() i = i + 1 return i end

    -- Declared, not left to become a global: a bare "_, h = ..." at file or
    -- function scope writes a global named _ that every other addon shares.
    local r, _
    r, h = W.Section(parent, y, "Keybind");                      y = y - h
    rows[#rows + 1] = r

    r, h = W.Keybind(parent, y, next_index(), "Ping wheel key",
        "Hold this, then left-click where you want to ping.");    y = y - h
    rows[#rows + 1] = r

    _, h = W.Spacer(parent, y, 10);                               y = y - h

    i = 0
    r, h = W.Section(parent, y, "Behaviour");                    y = y - h
    rows[#rows + 1] = r

    r, h = W.Toggle(parent, y, next_index(), "Enabled",
        "Turn the ping wheel off without unbinding its key.",
        function() return db.enabled end,
        function(v) db.enabled = v; ns.Refresh() end);           y = y - h
    rows[#rows + 1] = r

    r, h = W.Toggle(parent, y, next_index(), "Environment only",
        "Pings pass through units and interface frames and land on the world, "
        .. "whatever your Ping Target setting says. Turn this off for ordinary "
        .. "pings that can call out a unit.",
        function() return db.environmentOnly end,
        function(v) db.environmentOnly = v; ns.Refresh() end);    y = y - h
    rows[#rows + 1] = r

    r, h = W.Toggle(parent, y, next_index(), "Instant ping (no wheel)",
        "Skip the wheel entirely: holding the key and pressing the mouse "
        .. "button sends a plain ping the moment you press, exactly where the "
        .. "cursor is. No flick, no release to wait for. The wheel settings "
        .. "below do nothing while this is on.",
        function() return db.instantPing end,
        function(v) db.instantPing = v; ns.Refresh() end);        y = y - h
    rows[#rows + 1] = r

    r, h = W.Toggle(parent, y, next_index(), "Click without moving pings",
        "Release the mouse without flicking and a plain ping lands exactly "
        .. "where you clicked. This is the only gesture with no drift at all. "
        .. "Turn it off to make a no-move release cancel instead.",
        function() return db.plainOnNoMove end,
        function(v) db.plainOnNoMove = v; ns.Refresh() end);      y = y - h
    rows[#rows + 1] = r

    r, h = W.Stepper(parent, y, next_index(), "Dead zone",
        "How far you must flick before an entry is chosen. The ping lands "
        .. "where the cursor is when you release, so this is also how far the "
        .. "ping can miss by. Smaller is more accurate; too small and a "
        .. "twitch picks an entry for you.",
        function() return db.deadZone end,
        function(v) db.deadZone = v; ns.Refresh() end,
        ns.MIN_DEAD_ZONE, ns.MAX_DEAD_ZONE, 2, " px");            y = y - h
    rows[#rows + 1] = r

    r, h = W.Stepper(parent, y, next_index(), "Wheel radius",
        "How far the icons sit from the centre. Appearance only -- an entry is "
        .. "chosen by direction, so a larger wheel does not ask for a longer flick.",
        function() return db.radius end,
        function(v) db.radius = v; ns.Refresh() end,
        ns.MIN_RADIUS, ns.MAX_RADIUS, 10, " px");                 y = y - h
    rows[#rows + 1] = r

    _, h = W.Spacer(parent, y, 10);                               y = y - h

    r, h = W.Section(parent, y, "Pings on the wheel");            y = y - h
    rows[#rows + 1] = r

    i = 0
    for pos = 1, #ns.PING_TYPES do
        r, h = W.PingRow(parent, y, next_index(), pos);           y = y - h
        rows[#rows + 1] = r
    end

    _, h = W.Spacer(parent, y, PAD);                              y = y - h

    -- The page's height IS the cursor. Never precomputed somewhere else, so
    -- the two cannot drift the first time either changes.
    return -y
end

-------------------------------------------------------------------------------
--  The window
-------------------------------------------------------------------------------

local function BuildWindow()
    local f = S.Window("EnvironmentPingOptions", WINDOW_W, nil, "EnvironmentPing")
    f:SetPoint("CENTER")
    content = f.Content

    local hint = S.Label(f, S.fontHint, "LEFT")
    Layout(function()
        hint:ClearAllPoints()
        P.Point(hint, "BOTTOMLEFT", f, "BOTTOMLEFT", PAD, 8)
        P.Point(hint, "BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, 8)
    end)
    f.hint = hint

    -- A drag must not outlive the window: Escape mid-drag would otherwise
    -- leave the row outlined and the driver ticking behind a hidden frame.
    f:SetScript("OnHide", function() EndDrag(true) end)

    f:SetScript("OnShow", function()
        -- Resolution, monitor and UI scale all change while the window is
        -- closed, so PLAYER_LOGIN is not the last word on any of them.
        P.Resnap()
        if ns.RefreshPage then ns.RefreshPage() end
    end)

    return f
end

-- Repaint every row that owns a control. Cheap, and it means a setting that
-- gates another one is never left showing a stale state.
local function RefreshHint()
    if not window then return end
    local key = GetBindingKey("ENVIRONMENTPING_HOLD")
    if not key then
        window.hint:SetText(S.Colorize(S.color.bad, "No key bound") .. " -- set one above.")
    elseif ns.DB().instantPing then
        window.hint:SetText("Hold " .. (GetBindingText(key) or key) .. ", left-click to ping instantly.")
    else
        window.hint:SetText("Hold " .. (GetBindingText(key) or key) .. ", left-click, flick, release.")
    end
end

function ns.RefreshPage()
    for _, r in ipairs(rows) do
        if r and r.Paint then r.Paint() end
    end
    RefreshHint()
end

function ns.ToggleOptions()
    if not window then
        window = BuildWindow()
        local h = BuildPage(content)
        local total = size.HEADER_H + h + HINT_H
        -- The page height comes from the cursor, the window's from the page
        -- plus the band and the hint strip; both re-snap with the scale.
        Layout(function()
            P.Size(content, nil, h)
            P.Size(window, nil, total)
        end)
        -- One proxy in UISpecialFrames (S.Window registers it), so Escape
        -- closes this the way it closes every other window.
    end
    window:SetShown(not window:IsShown())
end
