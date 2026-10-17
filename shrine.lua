
local M = {}

local function drawTilesNearShrine(layer, shrine, tint, map)
    if not layer then return end
    love.graphics.setColor(tint)

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
    local baseLayer = g.map.layers["bases"]

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

    local bodyColors = {
        neutral = {1, 1, 1, 1},
        blue = {0.6, 0.75, 1, 1},
        red = {1, 0.65, 0.6, 1},
        green = {0.6, 1, 0.5, 1},
        yellow = {1, 0.85, 0.2, 1},
    }

    local symbolColors = {
        neutral = {1, 1, 1, 0},
        blue = {0.65, 0.8, 1, 1},
        red = {1, 0, 0, 1},
        green = {0.3, 1, 0.5, 1},
        yellow = {0.9, 0.8, 0.1, 1},
    }

    local bodyLayer = bodyLayers[shrine.state] or bodyLayers.normal
    local symbolLayer = symbolLayers[shrine.state] or symbolLayers.normal
    local bodyTint = bodyColors[shrine.team] or bodyColors.neutral
    local symbolTint = symbolColors[shrine.team] or symbolColors.neutral

    drawTilesNearShrine(baseLayer, shrine, bodyTint, g.map)
    drawTilesNearShrine(bodyLayer, shrine, {1,1,1,1}, g.map)
    drawTilesNearShrine(symbolLayer, shrine, symbolTint, g.map)
end

return M