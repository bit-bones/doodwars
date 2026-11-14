local graphics = require "graphics"
local colors = graphics.colors
local setColor = graphics.setColor

local bodyColors = {
    neutral = {1, 1, 1, 1},
    blue = {0.5, 0.7, 1},
    red = {1, 0.6, 0.55},
    green = {0.55, 1, 0.4},
    yellow = {1, 0.9, 0},
}

local symbolColors = {
    neutral = {1, 1, 1, 0},
    blue = {0.5, 0.8, 1},
    red = {1, 0.1, 0.1},
    green = {0.2, 1, 0.3},
    yellow = {1, 0.8, 0.3},
}


local M = {}

function M.getShrineBox(s)
    local fw, fh = s.animation[s.dir]:getDimensions() -- get animation frame dimensions
    local sw =  fw * s.scale -- multiply by dood scale to get current sprite dimensions
    local sh = fh * s.scale
    local bw = sw * 0.4      -- multiply by shrink factor to get box dimensions
    local bh = sh * 0.5
    local bx = s.x + (sw - bw) / 2
    local by = s.y + (sh - bh) / 2
    s.box = {
        x = bx,
        y = by,
        w = bw,
        h = bh,
        centerX = bx + bw / 2,
        centerY = by + bh / 2,
    }
end

local function drawTilesNearShrine(layer, shrine, tint, map)
    if not layer then return end
    setColor(tint)

    for row = math.max(1, shrine.tileY - 3),
            math.min(layer.height, shrine.tileY + 2) do
        for column = math.max(1, shrine.tileX - 2),
                    math.min(layer.width, shrine.tileX + 2) do
            local tile = layer.data[row] and layer.data[row][column]

            if tile then
                local x, y = map:getLayerTilePosition(layer, tile, column, row)
                local image = map.tilesets[tile.tileset].image

                love.graphics.draw(
                    image,
                    tile.quad,
                    x + layer.x,
                    y + layer.y
                )
            end
        end
    end
end

function M.drawShrine(shrine, g)
    local bodyLayers = {
        broken = g.map.layers["shrines.broken"],
        normal = g.map.layers["shrines.normal"],
        upgraded = g.map.layers["shrines.upgraded"],
    }

    local symbolLayers = {
        broken = g.map.layers["shrines.broken-symbols"],
        normal = g.map.layers["shrines.normal-symbols"],
        upgraded = g.map.layers["shrines.upgraded-symbols"],
    }

    local bodyLayer = bodyLayers[shrine.state] or bodyLayers.normal
    local symbolLayer = symbolLayers[shrine.state] or symbolLayers.normal
    local bodyTint = bodyColors[shrine.team] or colors.neutral
    local symbolTint = symbolColors[shrine.team] or colors.neutral

    drawTilesNearShrine(bodyLayer, shrine, bodyColors.neutral, g.map)
    drawTilesNearShrine(symbolLayer, shrine, symbolTint, g.map)
end

function M.drawBase(base, g)
    local baseLayer = g.map.layers["bases"]
    local bodyTint = bodyColors[g.shrines[base.index].team]

    drawTilesNearShrine(baseLayer, base, bodyTint, g.map)
end

return M