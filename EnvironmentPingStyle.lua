-- EnvironmentPing: shared visual language for the options window.
--
-- A flat, near-black canvas with a slight green hue cast, lifted controls,
-- recessed insets, hairline borders rather than bevels, and ONE accent (#1DB954)
-- used for state. This is SimpleLootCouncil's current design language,
-- hue-rotated from its blue to this addon's green; the neutrals carry 0.75x
-- SLC's saturation and the accent ramp (accent / accentDim / accentPale / knob)
-- keeps SLC's relationships.
--
-- Everything is drawn with flat SetColorTexture rectangles, never
-- BackdropTemplate: an edgeFile scales with its frame, so a "1px" edge is 1px at
-- exactly one size. Every size, offset and border goes through
-- EnvironmentPingPixel.lua so it stays on the physical pixel grid at any UI scale.
--
-- Everything that is not the canvas, a control surface or the accent is white or
-- black at an alpha, never a colour.

local ADDON_NAME, ns = ...

local S = {}
ns.Style = S

local P = ns.Pixel
local Snap = P.Snap

-- ---------------------------------------------------------------------
-- Palette. Hex in the comments is how each was picked.
-- ---------------------------------------------------------------------
S.color = {
    canvas       = { 0.056, 0.085, 0.066 }, -- #0E1611  panel

    -- Controls are RAISED, with hover and pressed steps either side.
    control      = { 0.070, 0.111, 0.084 }, -- #121C15  button rest
    controlHover = { 0.109, 0.174, 0.132 }, -- #1C2C22  button hover
    controlDown  = { 0.040, 0.066, 0.049 }, -- #0A110D  button pressed

    controlBorder      = { 1, 1, 1, 0.22 },
    controlBorderHover = { 1, 1, 1, 0.55 },

    -- Inputs are RECESSED: black at an alpha.
    inset        = { 0, 0, 0, 0.25 },
    insetDeep    = { 0, 0, 0, 0.35 },

    border       = { 1, 1, 1, 0.05 },       -- hairline
    borderBright = { 1, 1, 1, 0.20 },       -- focused / hovered edge

    text         = { 1, 1, 1, 1.00 },       -- primary
    textMuted    = { 0.736, 0.845, 0.774 }, -- #BCD7C5  secondary
    textFaint    = { 0.553, 0.671, 0.594 }, -- #8DAB98  hints, disabled

    rowOdd       = { 0, 0, 0, 0.10 },       -- alternating list stripe
    rowEven      = { 0, 0, 0, 0.20 },
    rowHover     = { 1, 1, 1, 0.07 },

    -- The one hue.
    accent       = { 0.114, 0.725, 0.329 }, -- #1DB954  green
    accentDim    = { 0.149, 0.443, 0.253 }, -- #267140  pressed accent
    accentPale   = { 0.176, 0.921, 0.439 }, -- #2DEB70

    good         = { 0.400, 0.780, 0.541 }, -- #66C78A  success
    bad          = { 0.898, 0.451, 0.451 }, -- #E57373  error
}

-- A ticked control is the accent.
S.color.check = S.color.accent

S.color.surface      = S.color.control
S.color.surfaceHover = S.color.controlHover

-- The window's three-stop ground (the fall is not linear). S.Window draws the
-- gradient between canvasTop and canvasBottom; canvasMid is the palette's
-- middle stop.
S.color.canvasTop    = { 0.060, 0.089, 0.070 } -- #0F1712
S.color.canvasMid    = { 0.035, 0.059, 0.044 } -- #090F0B
S.color.canvasBottom = { 0.027, 0.048, 0.034 } -- #070C09

S.color.band         = { 0.048, 0.074, 0.057 } -- #0C130F  title band, footer
S.color.rail         = { 0.044, 0.074, 0.054 } -- #0B130E
S.color.railText     = { 0.296, 0.469, 0.357 } -- #4B785B
S.color.card         = { 0.064, 0.097, 0.076 } -- #101913
S.color.cardRaised   = { 0.080, 0.116, 0.093 } -- #141D18
S.color.cardLift     = { 1, 1, 1, 0.03 }       -- white at 3%

-- The divider ramp. Four steps, dimmest to brightest: a rule between rows, a
-- panel edge, a control edge, and the edge of something focused or selected.
S.color.rule         = { 0.119, 0.172, 0.137 } -- #1E2C23
S.color.edge         = { 0.134, 0.187, 0.153 } -- #223027
S.color.edgeBright   = { 0.160, 0.225, 0.183 } -- #29392F
S.color.steel        = { 0.201, 0.277, 0.228 } -- #33473A  control borders
S.color.steelBright  = { 0.217, 0.293, 0.244 } -- #374B3E  hover / focus

S.color.danger       = { 0.769, 0.282, 0.353 } -- #C4485A
S.color.dangerEdge   = { 0.420, 0.200, 0.251 } -- #6B3340
S.color.dangerText   = { 0.878, 0.541, 0.588 } -- #E08A96
S.color.warn         = { 0.851, 0.627, 0.306 } -- #D9A04E

-- A switch's OFF state: a surface, not text alphas.
S.color.neutral600   = { 0.440, 0.490, 0.457 } -- #707D75  the off knob
S.color.neutral700   = { 0.335, 0.394, 0.356 } -- #56645B  the off track

-- The ON knob: a pale tint of the accent rather than white.
S.color.knob         = { 0.244, 0.963, 0.497 } -- #3EF67F

-- The window's outer edge: the only thing separating it from the game UI.
S.color.windowEdge   = { 0.230, 0.295, 0.253 } -- #3B4B41

-- The title band, its own small gradient sitting on the window's.
S.color.headerTop    = { 0.094, 0.114, 0.101 } -- #181D1A
S.color.headerBottom = { 0.068, 0.097, 0.078 } -- #111914

-- ---------------------------------------------------------------------
-- Spacing scale. Named, and computed where derivable.
-- ---------------------------------------------------------------------
local size = {
    PAD       = 15,  -- window edge -> content
    ROW_PAD   = 10,  -- row edge -> label / control
    GAP       = 9,   -- label right bound -> control left
    SECTION   = 11,  -- above a section header

    HEADER_H  = 38,  -- window title band
    CLOSE     = 22,  -- the close button, square

    CTRL_H    = 22,  -- stepper button, compact control
    BTN_H     = 24,  -- the keybind button
    BTN_W     = 130, -- the keybind button

    SWITCH_W  = 34,
    SWITCH_H  = 18,

    ROW_H     = 34,  -- an option row
    ROW_H_SM  = 30,  -- a ping row: icon plus a name
}

S.size = size

local function Unpack(c, alpha)
    return c[1], c[2], c[3], alpha or c[4] or 1
end
S.Unpack = Unpack

-- Colour a string for use in FontStrings, from the same palette.
function S.Colorize(color, text)
    return ("|cff%02x%02x%02x%s|r"):format(
        math.floor(color[1] * 255 + 0.5),
        math.floor(color[2] * 255 + 0.5),
        math.floor(color[3] * 255 + 0.5),
        text)
end

-- ---------------------------------------------------------------------
-- Fonts. CreateFont names are GLOBAL, hence the EnvironmentPing prefix.
-- ---------------------------------------------------------------------
-- URW Gothic (Demi) as in SimpleLootCouncil. Latin, Cyrillic and Greek; licence
-- fonts/LICENSE-URW.txt. Caps has +.14em tracking baked into the file, since
-- SetFont has no tracking argument.
local FONT_DIR = "Interface\\AddOns\\EnvironmentPing\\fonts\\"
local FALLBACK = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local CLIENT_LOCALE = type(GetLocale) == "function" and GetLocale() or "enUS"
local CLIENT_FONT_ONLY = CLIENT_LOCALE == "koKR" or CLIENT_LOCALE == "zhCN"
    or CLIENT_LOCALE == "zhTW"

local FONT_REGULAR  = FONT_DIR .. "URWGothic-Demi.ttf"
local FONT_TABULAR  = FONT_DIR .. "URWGothic-DemiTabular.ttf"
local FONT_CAPS     = FONT_DIR .. "URWGothic-DemiCaps.ttf"

-- Never probed: the client loads a font file in the background, so a first
-- SetFont on it returns false and a probe would send every font to Friz.
local fontsLoaded = not CLIENT_FONT_ONLY
S.fontsLoaded = fontsLoaded

local function MakeFallbackFont(name, path, fontSize, color, flags)
    local f = CreateFont(name)
    local clientFont = path == FONT_CAPS
        and (UNIT_NAME_FONT or FALLBACK) or FALLBACK
    f:SetFont(fontsLoaded and path or clientFont, fontSize, flags or "")
    f:SetTextColor(Unpack(color))
    f:SetShadowColor(0, 0, 0, 0)
    f:SetShadowOffset(0, 0)
    return f
end

-- Blizzard's own faces for the alphabets URW Gothic does not cover.
local ALPHABET_FONTS = {
    korean             = "Fonts\\2002.TTF",
    simplifiedchinese  = "Fonts\\ARKai_T.ttf",
    traditionalchinese = "Fonts\\blei00d.TTF",
}

-- A font FAMILY: CreateFont + SetFont fills only the roman member.
local function MakeFont(name, path, fontSize, color, flags)
    if type(CreateFontFamily) ~= "function" then
        return MakeFallbackFont(name, path, fontSize, color, flags)
    end
    flags = flags or ""
    local ours = fontsLoaded
    local members = {
        { alphabet = "roman", file = ours and path or FALLBACK,
          height = fontSize, flags = flags },
        { alphabet = "russian", file = ours and path or "Fonts\\FRIZQT___CYR.TTF",
          height = fontSize, flags = flags },
    }
    for alphabet, file in pairs(ALPHABET_FONTS) do
        members[#members + 1] = { alphabet = alphabet, file = file,
            height = fontSize, flags = flags }
    end
    local ok, f = pcall(CreateFontFamily, name, members)
    if not ok or not f then
        return MakeFallbackFont(name, path, fontSize, color, flags)
    end
    f:SetTextColor(Unpack(color))
    f:SetShadowColor(0, 0, 0, 0)
    f:SetShadowOffset(0, 0)
    return f
end

S.fontTitle   = MakeFont("EnvironmentPingFontTitle",   FONT_REGULAR, 16,   S.color.text)
S.fontHeading = MakeFont("EnvironmentPingFontHeading", FONT_CAPS,    11,   S.color.textFaint)
S.fontBody    = MakeFont("EnvironmentPingFontBody",    FONT_REGULAR, 12.5, S.color.text)
S.fontButton  = MakeFont("EnvironmentPingFontButton",  FONT_REGULAR, 12,   S.color.text)
S.fontHint    = MakeFont("EnvironmentPingFontHint",    FONT_REGULAR, 11,   S.color.textFaint)
S.fontNum     = MakeFont("EnvironmentPingFontNum",     FONT_TABULAR, 12,   S.color.text)

-- ---------------------------------------------------------------------
-- Primitives
-- ---------------------------------------------------------------------

-- Rounded corners, for WINDOW SURFACES ONLY (as in CastQueueOverlay and SLC):
-- controls are square with a one-pixel border. Nine-sliced art in art/, radius
-- 8, which must match CastQueueOverlay's dev/make_art.py.
local ART = "Interface\\AddOns\\EnvironmentPing\\art\\"
local ROUND_FILL    = ART .. "rounded"
local ROUND_OUTLINE = ART .. "rounded-outline"
local RADIUS = 8

-- Whether the art actually loaded. A mask that fails to load masks everything,
-- which would present as a blank window; the flat path is the fallback.
local rounded = false
do
    local scratch = CreateFrame("Frame")
    local probe = scratch:CreateTexture(nil, "BACKGROUND")
    rounded = probe:SetTexture(ROUND_FILL) and true or false
    probe:SetTexture(nil)
    scratch:Hide()
end
S.rounded = rounded

local function SliceNine(tex, asset)
    tex:SetTexture(asset)
    tex:SetTextureSliceMargins(RADIUS, RADIUS, RADIUS, RADIUS)
    tex:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    return tex
end

-- A mask that clips whatever it is applied to down to the rounded rectangle.
-- `bounds` is the frame the CORNERS follow: the title band is clipped by the
-- WINDOW's corners, since masks are positional.
function S.RoundMask(bounds)
    if not rounded then return nil end
    local mask = bounds:CreateMaskTexture()
    mask:SetAllPoints(bounds)
    -- CLAMPTOBLACKADDITIVE, or the mask tiles and clips nothing outside its rect.
    mask:SetTexture(ROUND_FILL, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetTextureSliceMargins(RADIUS, RADIUS, RADIUS, RADIUS)
    mask:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    return mask
end

-- Every FontString goes through here. Bounded on both sides by the caller, with
-- word wrap off: a text region free to grow is what turns a long localized
-- string into an overlap.
function S.Label(parent, fontObject, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFontObject(fontObject or S.fontBody)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(false)
    return fs
end

function S.Fill(frame, color, alpha, layer)
    local t = frame:CreateTexture(nil, layer or "BACKGROUND")
    t:SetAllPoints(frame)
    t:SetColorTexture(Unpack(color, alpha))
    P.Crisp(t)
    return t
end

-- Hairline border as four edges in a container of their own, so it stays one
-- PHYSICAL pixel at any frame size and any UI scale. `thickness` is counted in
-- physical pixels. Idempotent per frame.
local borders = setmetatable({}, { __mode = "k" })

function S.Border(frame, color, layer, thickness)
    local existing = borders[frame]
    if existing then
        if color then existing:SetColor(color) end
        if thickness then existing:SetThickness(thickness) end
        return existing
    end

    local px = thickness or 1

    local ring = CreateFrame("Frame", nil, frame)
    ring:EnableMouse(false)
    ring:SetAllPoints()
    -- The host's own level, not one above: a child outranks every draw layer of
    -- its parent, which would put the edges over the host's label.
    ring:SetFrameLevel(frame:GetFrameLevel())

    local edges = {}
    local function edge(p1, p2, horizontal)
        local t = ring:CreateTexture(nil, layer or "BORDER")
        t:SetColorTexture(Unpack(color))
        P.Edge(t)
        t:SetPoint(p1)
        t:SetPoint(p2)
        t.epHorizontal = horizontal
        edges[#edges + 1] = t
        return t
    end

    local function applyThickness()
        local w = P.Hairline(ring) * px
        for i = 1, #edges do
            local t = edges[i]
            if t.epHorizontal then t:SetHeight(w) else t:SetWidth(w) end
        end
    end

    edge("TOPLEFT", "TOPRIGHT", true)
    edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
    edge("TOPLEFT", "BOTTOMLEFT", false)
    edge("TOPRIGHT", "BOTTOMRIGHT", false)
    applyThickness()

    -- The effective scale is not final in the frame the border is created in.
    P.AfterLayout(applyThickness)
    P.Settle(applyThickness)
    P.OnRescale(applyThickness)

    local handle = {
        SetColor = function(_, c, alpha)
            for i = 1, #edges do edges[i]:SetColorTexture(Unpack(c, alpha)) end
        end,
        SetShown = function(_, on)
            ring:SetShown(on and true or false)
        end,
        SetThickness = function(_, n)
            px = n or 1
            applyThickness()
        end,
        Frame = ring,
    }

    borders[frame] = handle
    return handle
end

-- The rounded counterpart of S.Border, with the same SetColor/SetShown handle.
-- One nine-sliced ring, derived from the same shape as the mask.
function S.RoundBorder(frame, color, layer)
    if not rounded then return S.Border(frame, color, layer) end

    local ring = frame:CreateTexture(nil, layer or "BORDER")
    ring:SetAllPoints(frame)
    SliceNine(ring, ROUND_OUTLINE)
    ring:SetVertexColor(Unpack(color))

    return {
        SetColor = function(_, c) ring:SetVertexColor(Unpack(c)) end,
        SetShown = function(_, on) ring:SetShown(on and true or false) end,
    }
end

-- A recessed panel: a hole cut in the window rather than something on it.
function S.Inset(parent, deep)
    local f = CreateFrame("Frame", nil, parent)
    S.Fill(f, deep and S.color.insetDeep or S.color.inset)
    f.border = S.Border(f, S.color.border)
    return f
end

-- ---------------------------------------------------------------------
-- Controls
-- ---------------------------------------------------------------------

-- The close X is two drawn bars: a typed x sits low and can ellipsise.
local function CloseGlyph(button, extent)
    local bars = {}
    local thickness = math.max(P.Hairline(button), extent / 9)

    for i = 1, 2 do
        local bar = button:CreateTexture(nil, "OVERLAY")
        bar:SetColorTexture(1, 1, 1, 1)
        P.Size(bar, extent, thickness)
        bar:SetPoint("CENTER")
        bar:SetRotation(i == 1 and (math.pi / 4) or -(math.pi / 4))
        bars[i] = bar
    end

    return {
        SetColor = function(_, c)
            for i = 1, #bars do bars[i]:SetVertexColor(Unpack(c)) end
        end,
    }
end

-- S.Button(parent, text, opts): width, height, primary (accent edge and ink),
-- glyph ("close"), font. Outline buttons, as in SimpleLootCouncil: the edge
-- carries the variant, the fill is only a hover surface (white alphas), and
-- hover brightens the edge, never the ink.
function S.Button(parent, text, opts)
    opts = opts or {}

    local b = CreateFrame("Button", nil, parent)
    local h = opts.height or size.BTN_H
    local w = opts.width or size.BTN_W

    -- Raise a size that cannot fit the font: 1.6 x its height.
    local _, fontHeight = (opts.font or S.fontButton):GetFont()
    fontHeight = tonumber(fontHeight) or 12
    h = math.max(h, math.ceil(fontHeight * 1.6))
    -- Never narrower than tall, so a one-character label centres.
    w = math.max(w, h)
    P.Size(b, w, h)
    P.OnRescale(function() P.Size(b, w, h) end)

    local edge, ink, brightEdge
    if opts.primary then
        edge, ink, brightEdge = S.color.accent, S.color.accent, S.color.knob
    else
        edge, ink, brightEdge = S.color.steel, S.color.text, S.color.steelBright
    end
    local defaultEdge, defaultInk, defaultBright = edge, ink, brightEdge

    local base  = { 1, 1, 1, 0.00 }
    local hover = { 1, 1, 1, 0.06 }
    local down  = { 0, 0, 0, 0.20 }

    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(b)
    bg:SetColorTexture(Unpack(base))
    P.Crisp(bg)

    local border = S.Border(b, edge, "BORDER")

    -- Bounded both sides so a long label ellipsises; 1 at 24px or less, or an
    -- 18px close button renders "..".
    local pad = opts.labelPad or (w <= 24 and 1 or 6)
    local label = S.Label(b, opts.font or S.fontButton, "CENTER")
    local function placeLabel(dy)
        label:SetPoint("LEFT", b, "LEFT", Snap(pad), dy)
        label:SetPoint("RIGHT", b, "RIGHT", Snap(-pad), dy)
    end
    placeLabel(0)
    label:SetText(text or "")
    b.Label = label

    local glyph
    if opts.glyph == "close" then
        label:Hide()
        glyph = CloseGlyph(b, math.floor(math.min(w, h) * 0.42))
    end
    b.Glyph = glyph

    local function setInk(colour)
        label:SetTextColor(Unpack(colour))
        if glyph then glyph:SetColor(colour) end
    end
    setInk(ink)

    local enabled = true

    local function paint(colour)
        bg:SetColorTexture(Unpack(colour))
    end

    b:SetScript("OnEnter", function()
        if not enabled then return end
        paint(hover)
        border:SetColor(brightEdge)
    end)
    b:SetScript("OnLeave", function()
        if not enabled then return end
        paint(base)
        border:SetColor(edge)
    end)
    b:SetScript("OnMouseDown", function()
        if not enabled then return end
        paint(down)
        label:ClearAllPoints()
        placeLabel(-1)
    end)
    b:SetScript("OnMouseUp", function(self)
        if not enabled then return end
        paint(self:IsMouseOver() and hover or base)
        label:ClearAllPoints()
        placeLabel(0)
    end)

    function b:SetLabel(t) label:SetText(t) end

    -- Recolour in place: the keybind button shows "listening" in the accent.
    -- nil restores the button's own variant.
    function b:SetAccented(on)
        if on then
            edge, ink, brightEdge = S.color.accent, S.color.accent, S.color.knob
        else
            edge, ink, brightEdge = defaultEdge, defaultInk, defaultBright
        end
        if enabled then
            border:SetColor(edge)
            setInk(ink)
        end
    end

    -- Disabled has to be VISIBLE, not merely inert.
    function b:SetEnabled(on)
        enabled = on and true or false
        if enabled then
            paint(base)
            setInk(ink)
            border:SetColor(edge)
            b:EnableMouse(true)
        else
            paint(base)
            setInk(S.color.textFaint)
            border:SetColor(S.color.border)
            b:EnableMouse(false)
        end
    end

    return b
end

-- The toggle (every boolean setting): a flat track and a square knob. It is a
-- picture of the state only; the ROW it sits in owns the click, so the whole row
-- is the target. Controls are square: rounding is for window surfaces only.
function S.Switch(parent)
    local b = CreateFrame("Frame", nil, parent)
    P.Size(b, size.SWITCH_W, size.SWITCH_H)
    P.OnRescale(function() P.Size(b, size.SWITCH_W, size.SWITCH_H) end)

    S.Fill(b, S.color.inset, nil, "BACKGROUND")
    local track = b:CreateTexture(nil, "BACKGROUND", nil, 1)
    track:SetAllPoints(b)
    P.Crisp(track)
    local border = S.Border(b, S.color.neutral700, "BORDER")

    local knob = b:CreateTexture(nil, "ARTWORK")
    knob:SetColorTexture(1, 1, 1, 1)
    P.Crisp(knob)

    local pad = Snap(2)
    local function Place(checked)
        local knobSize = Snap(size.SWITCH_H) - pad * 2
        P.Size(knob, knobSize, knobSize)
        knob:ClearAllPoints()
        if checked then
            knob:SetPoint("RIGHT", b, "RIGHT", -pad, 0)
        else
            knob:SetPoint("LEFT", b, "LEFT", pad, 0)
        end
    end

    local checked = false
    local function Paint()
        if checked then
            local a = S.color.accent
            track:SetColorTexture(a[1], a[2], a[3], 0.20)
            knob:SetVertexColor(Unpack(S.color.knob))
            border:SetColor(S.color.accent)
        else
            track:SetColorTexture(0, 0, 0, 0)
            knob:SetVertexColor(Unpack(S.color.neutral600))
            border:SetColor(S.color.neutral700)
        end
        Place(checked)
    end

    function b:SetChecked(on)
        checked = on and true or false
        Paint()
    end
    function b:GetChecked() return checked end
    P.OnRescale(function() Place(checked) end)
    Paint()

    return b
end

-- A section heading: a caps label and a rule that finishes itself, anchored to
-- the label on one side and to the row on the other.
function S.Heading(parent, text)
    local fs = S.Label(parent, S.fontHeading, "LEFT")
    fs:SetPoint("LEFT", parent, "LEFT", 0, -2)
    fs:SetText((text or ""):upper())

    local rule = parent:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(Unpack(S.color.rule))
    P.Edge(rule)
    rule:SetPoint("LEFT", fs, "RIGHT", Snap(size.GAP), 0)
    rule:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    local function thickness() rule:SetHeight(P.Hairline(parent)) end
    thickness()
    P.OnRescale(thickness)
    return fs
end

-- ---------------------------------------------------------------------
-- Window
-- ---------------------------------------------------------------------
-- A movable frame with a gradient ground, a title band, a close button and a
-- remembered position. `f.Content` is the frame below the band the page builds
-- into; `f.Title` and `f.Header` are exposed. Rounded (art/), with a flat fallback if the art
-- did not load.
function S.Window(globalName, width, height, title)
    local f = CreateFrame("Frame", globalName, UIParent)
    P.Size(f, width, height)
    P.OnRescale(function() P.Size(f, width, nil) end)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:EnableMouse(true)   -- also stops clicks falling through to the world
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:Hide()

    -- SetGradient MODULATES the texture, so it is white underneath.
    -- "VERTICAL" takes minColor at the BOTTOM and maxColor at the TOP.
    local windowMask = S.RoundMask(f)
    local ground = S.Fill(f, { 1, 1, 1, 1 })
    if windowMask then ground:AddMaskTexture(windowMask) end
    ground:SetGradient("VERTICAL",
        CreateColor(S.color.canvasBottom[1], S.color.canvasBottom[2], S.color.canvasBottom[3], 1),
        CreateColor(S.color.canvasTop[1], S.color.canvasTop[2], S.color.canvasTop[3], 1))
    -- The edge ring is its own frame above the band, close button and content,
    -- as in SimpleLootCouncil: those are child frames and would paint over a ring
    -- on the window itself.
    local edge = CreateFrame("Frame", nil, f)
    edge:EnableMouse(false)
    edge:SetAllPoints()
    edge:SetFrameLevel(f:GetFrameLevel() + 4)
    f.border = S.RoundBorder(edge, S.color.windowEdge, "OVERLAY")
    f.Edge = edge

    local header = CreateFrame("Frame", nil, f)
    header:SetFrameLevel(f:GetFrameLevel() + 1)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    P.Size(header, nil, size.HEADER_H)
    P.OnRescale(function() P.Size(header, nil, size.HEADER_H) end)
    local band = S.Fill(header, { 1, 1, 1, 1 })
    -- Clipped by the WINDOW's corners, not its own.
    if windowMask then band:AddMaskTexture(windowMask) end
    band:SetGradient("VERTICAL",
        CreateColor(S.color.headerBottom[1], S.color.headerBottom[2], S.color.headerBottom[3], 1),
        CreateColor(S.color.headerTop[1], S.color.headerTop[2], S.color.headerTop[3], 1))
    f.Header = header

    local rule = header:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(Unpack(S.color.edge))
    P.Edge(rule)
    rule:SetPoint("BOTTOMLEFT")
    rule:SetPoint("BOTTOMRIGHT")
    local function ruleThickness() rule:SetHeight(P.Hairline(header)) end
    ruleThickness()
    P.OnRescale(ruleThickness)

    local close = S.Button(f, "", { width = size.CLOSE, height = size.CLOSE, glyph = "close" })
    close:SetFrameLevel(header:GetFrameLevel() + 2)
    -- Centred in the band by construction: the same inset top and right.
    local closeInset = (size.HEADER_H - size.CLOSE) * 0.5
    P.Point(close, "TOPRIGHT", f, "TOPRIGHT", -closeInset, -closeInset)
    close:SetScript("OnClick", function() f:Hide() end)
    f.Close = close

    local titleText = S.Label(header, S.fontTitle, "LEFT")
    P.Point(titleText, "LEFT", header, "LEFT", size.PAD, 0)
    P.Point(titleText, "RIGHT", close, "LEFT", -size.GAP, 0)
    titleText:SetText(title or "")
    f.Title = titleText

    local content = CreateFrame("Frame", nil, f)
    content:SetFrameLevel(f:GetFrameLevel() + 1)
    P.Point(content, "TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    P.Point(content, "TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    f.Content = content

    -- Drag from the title band only; align to the pixel grid on drop.
    local grip = CreateFrame("Frame", nil, header)
    grip:SetPoint("TOPLEFT")
    grip:SetPoint("BOTTOMRIGHT", close, "BOTTOMLEFT")
    grip:EnableMouse(true)
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", function() f:StartMoving() end)
    grip:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        P.AlignFrame(f)
    end)

    if globalName then
        -- Escape closes it, like every other panel in the game.
        tinsert(UISpecialFrames, globalName)
    end

    return f
end
