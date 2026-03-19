-- char_profiles.lua
-- Per-character stat profiles and special power definitions.
-- Each profile is keyed by the character's asset folder path.
--
-- Special power rules:
--   • Power Bar fills only during a fruit combo (2+ consecutive same type).
--   • Favorite fruit gives 25 fill per combo hit; other fruits give 15.
--   • Pressing E (or F) when bar == 100 activates the special.

local PROFILES = {}

-- ─── Mask Dude ────────────────────────────────────────────────────────────────
-- Fast runner; moderate jumper.
-- Special: Speed Surge — 1.6x movement speed for 5 seconds.
PROFILES["assets/Main Characters/Mask Dude/"] = {
    name          = "Mask Dude",
    speed         = 130,
    jumpVel       = -450,
    favoriteFruit = "Apple.png",
    specialName   = "Speed Surge",
    specialDesc   = "1.6x speed  5s",
    specialFn     = function(player)
        player.specialActive = true
        player.specialTimer  = 5.0
        player.specialType   = "speed"
    end,
}

-- ─── Ninja Frog ───────────────────────────────────────────────────────────────
-- Fastest but lowest jump.
-- Special: Triple Jump — grants a third mid-air jump for 8 seconds.
PROFILES["assets/Main Characters/Ninja Frog/"] = {
    name          = "Ninja Frog",
    speed         = 150,
    jumpVel       = -400,
    favoriteFruit = "Kiwi.png",
    specialName   = "Triple Jump",
    specialDesc   = "3 jumps  8s",
    specialFn     = function(player)
        player.specialActive = true
        player.specialTimer  = 8.0
        player.specialType   = "triplejump"
        player.jumpsLeft     = 3
    end,
}

-- ─── Pink Man ─────────────────────────────────────────────────────────────────
-- Slowest but highest jump.
-- Special: Shield — full invincibility for 6 seconds.
PROFILES["assets/Main Characters/Pink Man/"] = {
    name          = "Pink Man",
    speed         = 105,
    jumpVel       = -510,
    favoriteFruit = "Strawberry.png",
    specialName   = "Shield",
    specialDesc   = "Invincible  6s",
    specialFn     = function(player)
        player.specialActive = true
        player.specialTimer  = 6.0
        player.specialType   = "shield"
    end,
}

-- ─── Virtual Guy ──────────────────────────────────────────────────────────────
-- Balanced all-rounder.
-- Special: Score Rush — 2× score multiplier for 10 seconds.
PROFILES["assets/Main Characters/Virtual Guy/"] = {
    name          = "Virtual Guy",
    speed         = 118,
    jumpVel       = -470,
    favoriteFruit = "Melon.png",
    specialName   = "Score Rush",
    specialDesc   = "2x score  10s",
    specialFn     = function(player)
        player.specialActive   = true
        player.specialTimer    = 10.0
        player.specialType     = "scorerush"
        player.scoreMultiplier = 2
    end,
}

return PROFILES
