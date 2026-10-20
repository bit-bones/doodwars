local camera = require("libs/hump/camera")

local game = {
    camera = camera.new(0, 0, 2),
    stopCheckTime = 0.5,
    controlledDood = nil,
    currentZoom = 0.5,
    zoomSpeed = 0.15,
    keyPanSpeed = 150,
    mousePanSpeed = 5,
    middleMousePanSpeed = 0.1,
    paused = false,
    cameraLocked = false,
    mouseCameraX = 0,
    mouseCameraY = 0,
    mouseWorldX = 0,
    mouseWorldY = 0,
    mouseStates = {},
    keyStates = {},
    layouts = {},
    fonts = {},
    fontHeights = {},
    doods = {},
    shrines = {},
    bases = {},
    props = {},
}

game.camera.x = 215
game.camera.y = 200

local M = {}

return game