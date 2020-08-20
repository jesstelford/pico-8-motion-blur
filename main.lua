menuitem(1,"debug",function()debugger.expand(true)end)

function createTrailSystem(shapes)
  local longestTrail = 0
  foreach(shapes, function(shape)
    shape.trailPositions = shape.trailPositions or {}
    shape.trails = shape.trails or 1
    shape.framesPerTrail = shape.framesPerTrail or 1
    assert(#shape.colors == shape.trails + 1, "Provide one color per shape drawn (including all trails)")
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
          local color = shape.colors[ceil(frame / shape.framesPerTrail) + 1]
          pal(shape.colors[1], color)
          shape.draw(
            shape.trailPositions[frame].x,
            shape.trailPositions[frame].y,
            shape.colors[1]
          )
        end)
      end
      foreach(shapes, function(shape)
        pal(shape.colors[1], shape.colors[1])
        shape.draw(shape.x, shape.y, shape.colors[1])
      end)
    end
  }
end

shapes = {
  {
    colors={1,2,3,4},
    x=0,
    y=0,
    trails=3,
    framesPerTrail=3,
    draw=function(x, y, color)
      circfill(x, y, 8, color)
    end
  },
  {
    colors={1,2,3,4},
    x=0,
    y=0,
    trails=3,
    framesPerTrail=2,
    draw=function(x, y, color)
      circfill(x, y, 9, color)
    end
  },
  {
    colors={5,6,7,8},
    x=0,
    y=0,
    trails=3,
    framesPerTrail=4,
    draw=function(x, y, color)
      circfill(x, y, 8, color)
    end
  },
  {
    colors={5,6,7,8,9},
    x=0,
    y=0,
    trails=4,
    framesPerTrail=1,
    draw=function(x, y, color)
      circfill(x, y, 4, color)
    end
  },
  {
    colors={10,11,12,13},
    x=0,
    y=0,
    trails=3,
    framesPerTrail=2,
    draw=function(x, y, color)
      circfill(x, y, 12, color)
    end
  },
  {
    colors={10,11,12,13},
    x=0,
    y=0,
    trails=3,
    framesPerTrail=8,
    draw=function(x, y, color)
      circfill(x, y, 7, color)
    end
  }
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
    shape.vx=flr(rnd(5)) - 2
    shape.vy=flr(rnd(5)) - 2
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
