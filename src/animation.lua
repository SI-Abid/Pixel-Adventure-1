-- animation.lua
-- Pure animation class: manages sprite sheet quads and frame timing.

local Animation = {}
Animation.__index = Animation

-- Constructor
-- image:      love.graphics image object (already loaded)
-- frameW/H:   pixel size of one frame in the strip
-- frameCount: total frames (horizontal strip)
-- fps:        playback speed in frames per second
-- loops:      boolean, whether to loop (default true)
function Animation.new(image, frameW, frameH, frameCount, fps, loops)
    local self = setmetatable({}, Animation)
    self.image        = image
    self.frameW       = frameW
    self.frameH       = frameH
    self.frameCount   = frameCount
    self.fps          = fps
    self.loops        = (loops == nil) and true or loops
    self.timer        = 0
    self.currentFrame = 1
    self.done         = false  -- true when a non-looping anim reaches its last frame

    -- Pre-build quads for O(1) frame lookup (horizontal strip at y=0)
    self.quads = {}
    local iw = image:getWidth()
    local ih = image:getHeight()
    for i = 1, frameCount do
        self.quads[i] = love.graphics.newQuad(
            (i - 1) * frameW, 0,
            frameW, frameH,
            iw, ih
        )
    end
    return self
end

function Animation:update(dt)
    if self.done then return end
    self.timer = self.timer + dt
    local frameDuration = 1 / self.fps
    if self.timer >= frameDuration then
        self.timer = self.timer - frameDuration
        self.currentFrame = self.currentFrame + 1
        if self.currentFrame > self.frameCount then
            if self.loops then
                self.currentFrame = 1
            else
                self.currentFrame = self.frameCount
                self.done = true
            end
        end
    end
end

-- Draw current frame at (x, y) in world space.
-- scaleX: pass -1 to flip horizontally; ox correction keeps sprite centered.
function Animation:draw(x, y, scaleX)
    scaleX = scaleX or 1
    local ox = (scaleX == -1) and self.frameW or 0
    love.graphics.draw(
        self.image,
        self.quads[self.currentFrame],
        x, y,
        0,          -- rotation
        scaleX, 1,  -- x scale, y scale
        ox, 0       -- origin offset for flip correction
    )
end

function Animation:reset()
    self.timer        = 0
    self.currentFrame = 1
    self.done         = false
end

return Animation
