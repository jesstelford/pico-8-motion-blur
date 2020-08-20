menuitem(1,"debug",function()debugger.expand(true)end)

local defaultFills = {
  0b0000000000000000,   -- solid
  0b0000000000000001.1, -- single pixel missing
  0b0000010100000101.1, -- 4 pixels missing
  0b0101101001011010.1, -- half pixels missing
  0b1111101011111010.1, -- 4 pixels rendered
  0b1111111111111110.1, -- 1 pixel rendered
}

-- Derived from https://stackoverflow.com/a/10086034/473961
function resizeAndFill(input, outputLength)
  assert(outputLength >= 2, "behaviour not defined for n<2")
  local step = (#input-1)/(outputLength-1)
  local result = {}
  for x=1,outputLength do
    result[x] = input[ceil(0.5 + (x-1)*step)]
  end
  return result
end

function createTrailSystem(shapes)
  local longestTrail = 0
  foreach(shapes, function(shape)
    shape.trailPositions = shape.trailPositions or {}
    shape.trails = shape.trails or 1
    shape.framesPerTrail = shape.framesPerTrail or 1
    -- Normalise the length of .fills to match number of trails
    shape.fills = resizeAndFill(shape.fills or defaultFills, shape.trails + 1)
    -- Normalise the length of .colors to match number of trails
    shape.colors = resizeAndFill(shape.colors or { shape.color }, shape.trails + 1)
    longestTrail = max(longestTrail, shape.trails)
  end)

  return {
    update=function()
      foreach(shapes, function(shape)
        if (#shape.trailPositions > (shape.trails * shape.framesPerTrail)) then
          -- Remove the oldest / now stale trail
          deli(shape.trailPositions, 1)
        end
        -- Add a new trail at the last position
        add(shape.trailPositions, { x=shape.x, y=shape.y })
      end)
    end,

    draw=function()
      -- Draw all the trail layers at the same time to avoid weird overlay
      -- artefacts
      for trail=longestTrail,1,-1 do
        foreach(shapes, function(shape)
          if (shape.trails < trail) then return end
          local frame = ((shape.trails - trail) * shape.framesPerTrail) + 1
          if (not shape.trailPositions[frame]) then return end
          -- +1 for 1-index in lua
          -- +1 for the actual shape itself
          local color = shape.colors[shape.trails - trail + 2]
          local fill = shape.fills[trail + 1]
          pal(shape.colors[1], color)
          shape.draw(
            shape.trailPositions[frame].x,
            shape.trailPositions[frame].y,
            shape.colors[1],
            fill
          )
        end)
      end
      foreach(shapes, function(shape)
        pal(shape.colors[1], shape.colors[1])
        shape.draw(shape.x, shape.y, shape.colors[1], shape.fills[1])
      end)
    end
  }
end

shapes = {
  {
    colors={1,2,3,4},
    x=0,
    y=0,
    trails=4,
    framesPerTrail=7,
    draw=function(x, y, color, fill)
      fillp(fill)
      circfill(x, y, 8, color)
    end
  },
  {
    colors={5,6,7,8,9},
    -- Force no dithering
    fills={0b0000000000000000},
    x=0,
    y=0,
    trails=4,
    framesPerTrail=4,
    draw=function(x, y, color, fill)
      fillp(fill)
      circfill(x, y, 8, color)
    end
  },
  {
    colors={10,11,12,13},
    x=0,
    y=0,
    trails=3,
    framesPerTrail=2,
    draw=function(x, y, color, fill)
      fillp(fill)
      circfill(x, y, 12, color)
    end
  },
  {
    colors={10,11,12,13},
    x=0,
    y=0,
    trails=3,
    framesPerTrail=8,
    draw=function(x, y, color, fill)
      fillp(fill)
      circfill(x, y, 7, color)
    end
  },
  {
    -- Single color will be automatically dithered
    colors={14},
    x=0,
    y=0,
    trails=3,
    framesPerTrail=3,
    draw=function(x, y, color, fill)
      fillp(fill)
      circfill(x, y, 5, color)
    end
  },
}

local trails

function _init()
  init_dbg()
  -- Setup the palettes in use
  -- Colors figured out thanks to http://kometbomb.net/pico8/fadegen.html
  pal(1, 12, 1)
  pal(2, 129, 1)
  pal(3, 131, 1)
  pal(4, 140, 1)

  pal(5, 10, 1)
  pal(6, 128, 1)
  pal(7, 132, 1)
  pal(8, 4, 1)
  pal(9, 138, 1)

  pal(10, 8, 1)
  pal(11, 128, 1)
  pal(12, 132, 1)
  pal(13, 136, 1)

  foreach(shapes, function(shape)
    -- Move it somewhere random
    shape.x=flr(rnd(112))+10
    shape.y=flr(rnd(112))+10
    -- Give it a random velocity
    shape.vx=flr(rnd(3)) - 1
    shape.vy=flr(rnd(3)) - 1
    if (shape.vx == 0 and shape.vy == 0) then shape.vx = 1 end

  end)

  -- Initialise the shapes ready for motion trail
  trails = createTrailSystem(shapes)
end

function _update60()
  if (debugger.expand()) then return end
  -- For this demo, move shapes around automatically
  foreach(shapes, function(shape)
    shape.x+=shape.vx
    shape.y+=shape.vy

    -- Bounce off the edges of the screen
    if (shape.x < 10) then
      shape.x = 10
      shape.vx = abs(shape.vx)
    end
    if (shape.x > 117) then
      shape.x = 117
      shape.vx = -abs(shape.vx)
    end
    if (shape.y < 10) then
      shape.y = 10
      shape.vy = abs(shape.vy)
    end
    if (shape.y > 117) then
      shape.y = 117
      shape.vy = -abs(shape.vy)
    end
  end)

  trails.update()
end

function _draw()
  cls(0)
  trails.draw()
  debugger.draw()
  sdbg()
end
