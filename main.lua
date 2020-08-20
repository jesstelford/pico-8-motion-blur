menuitem(1,"debug",function()debugger.expand(true)end)

function _init()
  init_dbg()
end

function _update60()
  if (debugger.expand()) then return end
end

function _draw()
  cls(0)
  debugger.draw()
  sdbg()
end
