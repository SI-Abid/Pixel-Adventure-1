function love.conf(t)
    t.window.title      = "Pixel Adventure"
    t.window.width      = 800
    t.window.height     = 450
    t.window.vsync      = 1
    t.window.resizable  = false
    -- borderless is set at runtime for Android; desktop keeps the title bar
    t.version           = "11.4"
end
