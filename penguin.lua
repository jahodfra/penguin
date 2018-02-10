-- title:  Panguin
-- author: Frantisek Jahoda
-- desc:   Catch the fish and avoid sharks
-- script: lua

-- Sets --
function set_remove(s,x)s[x]=nil end
function set_add(s,x)s[x]=true end
-- RXI class toolkit --
local Class = {}
Class.__index = Class
function Class:new()end
function Class:extend()local a={}for b,c in pairs(self)do if b:find("__")==1 then a[b]=c end end;a.__index=a;a.super=self;setmetatable(a,self)return a end
function Class:__call(...)local a=setmetatable({},self)a:new(...)return a end
function Class:__tostring()return ""end
function Class:implement(...)for a,b in pairs({...})do for c,d in pairs(b)do if self[c]==nil and type(d)=="function"then self[c]=d end end end end
function Class:is(a)local b=getmetatable(self)while b do if b==a then return true end;b=getmetatable(b)end;return false end
-- end --
PointSet=Class:extend()
function PointSet:new(row_size)self.row_size=row_size or 1000;self._points={}end
function PointSet:add(x,y,object)
 self._points[Vect2(x,y)]=object
end
function hypot2(a,b,c,d)return math.sqrt((a-c)^2+(b-d)^2)end
function PointSet:find_nearest(x,y)
 local res,d
 local md=math.huge
 for bi,b in pairs(self._points)do
  d=hypot2(x,y,bi.x,bi.y)
  if 1<d and d<md then md=d res=bi end
 end
 return res, self._points[res]
end
Vect2=Class:extend()
function Vect2:new(x,y)self.x=x self.y=y end
function Vect2:__len()return math.sqrt(self.x^2+self.y^2) end
function Vect2:__sub(v2)return Vect2(self.x-v2.x,self.y-v2.y)end
function Vect2:__add(v2)return Vect2(self.x+v2.x,self.y+v2.y)end
function Vect2:__mul(m)return Vect2(self.x*m,self.y*m)end
function Vect2:__eq(m)return self.x==m.x and self.y==m.y end
function Vect2:__tostring()return"("..self.x..", "..self.y..")"end

Player=Class:extend()

function Player:new(x,y)
 self.x=x
 self.y=y
 self.turn=RIGHT
 self.speed=1
end

function Player:control(up,down,left,right)
 self.speed=1
 if self.x < -16 then
  self.turn=RIGHT
 elseif left then
  self.turn=LEFT;self.speed=2
 end

 if self.x > 256 then
  self.turn=LEFT
 elseif right then
  self.turn=RIGHT;self.speed=2
 end

 if self.turn==LEFT then self.x=self.x-self.speed/2 else self.x=self.x+self.speed/2 end
 if up and self.y > 10 then self.y=self.y-.5 end
 if down and self.y < 130 then self.y=self.y+.5 end
 if self.speed>1 and (t%20)==0 then Bubble(self.x,self.y) end
end

function Player:draw()
 local phase,flip
 phase=t/6*self.speed%3
 if self.turn==LEFT then flip=1 else flip=0 end
 spr(SPR.PENGUIN+phase,self.x,self.y,0,1,flip)
end

Fish=Class:extend()
Fish.list={}

function Fish.draw_all(player_pos)
 local ps=PointSet(1000)
 for f in pairs(Fish.list) do
  f:draw()
  ps:add(f.x,f.y,f)
 end
 local dir,dist,move,pos,penguin
 for f in pairs(Fish.list) do
  pos=Vect2(f.x,f.y)
  dir=ps:find_nearest(f.x, f.y) - pos
  penguin=player_pos - pos
  if #penguin < 30 then
   move=penguin*(0.5 / #penguin)
   f.x=f.x-move.x
   f.y=f.y-move.y
  else
   dist=#dir
   if dist >= 20 then
    move=dir*(0.2 / dist)
    f.x=f.x+move.x
    f.y=f.y+move.y
   elseif dist < 10 then
    move=dir*(-0.2 / dist)
    f.x=f.x+move.x
    f.y=f.y+move.y
   end
  end
 end
end

function Fish:new(x,y)
 self.x=x
 self.y=y
 set_add(Fish.list,self)
end

function Fish:draw()
 spr(SPR.FISH,self.x,self.y,1)
end

Shark=Class:extend()
function Shark:new()
 self.x=250
 self.y=math.random(30, 120)
end

function Shark:draw()
 spr(SPR.SHARK,self.x,self.y,1,1,0,0,4,2)
 self.x = self.x - 1
 if self.x < -100 then
  self.x=250
  self.y=math.random(30, 120)
 end
end

Bubble=Class:extend()
Bubble.list={}

function Bubble:new(x,y)
 self.x=x
 self.y=y
 set_add(Bubble.list,self) 
 self.index=#Bubble.list
end

function Bubble:draw()
 local phase = (t/3+self.index)%4
 spr(SPR.BUBBLE+phase,self.x,self.y,0)
 self.y=self.y-math.random(0,5)/5
 self.x=self.x+math.random(-3, 3)/3
 if self.y < 5 then
  set_remove(Bubble.list, self)
 end
end

player=Player(96,24)

t=0

LEFT=1
RIGHT=0

SPR={
 WATER=32,
 FISH=64,
 PENGUIN=16,
 BUBBLE=48,
 SHARK=80
}

function init()
 for i=1,20 do
   Fish(math.random(240),math.random(110)+16)
 end
 shark=Shark()
end

function TIC()
 player:control(btn(0),btn(1),btn(2),btn(3))
 draw_water()
 Fish.draw_all(Vect2(player.x, player.y))
 for b in pairs(Bubble.list) do
  b:draw()
 end
 player:draw()
 shark:draw()
 print("CATCH THE FISH!",84,64)
 t=t+1
end

function draw_water()
 local i,shift
 cls(8)
 rect(0,11,240,136-11,1)
 for i=0,8 do
  local shift=t//2 % 32
  spr(SPR.WATER,-32+shift+i*32,3,8,1,0,0,4,1)
 end
end

init()
-- <TILES>
-- 000:8888888888888888888888888888888888888881888881118881111111111111
-- 001:8888811188811111811111111111111111111111111111111111111111111111
-- 002:1118888811111888111111181111111111111111111111111111111111111111
-- 003:8888888888888888888888888888888818888888111888881111188811111111
-- 004:fffffeee2222ffee88880fee22280feefff80ffffff80f0f0ff80f0f0ff80f0f
-- 016:0000000000000000033333303333333603aa33a0000033000003300000000000
-- 017:0000000000000000033333303333333603a33aa0000330000033000000000000
-- 018:0000000000000000033333303333333603aa33a0000033000000030000000000
-- 019:f8fffffff8888888f888f888f8888ffff8888888f2222222ff000fffefffffef
-- 020:fff800ff88880ffef8880fee88880fee88880fee2222ffee000ffeeeffffeeee
-- 032:8888888888888888888888888888888888888881888811111111111111111111
-- 033:8888888888888888888811118111111111111111111111111111111111111111
-- 034:8888888888888888111188881111111811111111111111111111111111111111
-- 035:8888888888888888888888888888888818888888111188881111111111111111
-- 048:0000000000000000000ff00000f00f0000f00f00000ff0000000000000000000
-- 049:000000000000000000000000000ff00000f00f00000fff000000000000000000
-- 050:000000000000000000000000000f000000f0f000000f00000000000000000000
-- 051:000000000000000000fff00000f00f00000ff000000000000000000000000000
-- 064:000000000000000000b0bb0000bbbbb000b0bb00000000000000000000000000
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:140c1c20285530346d4e4a4e854c30346524d04648757161597dced27d2c8595a16daa2cd2aa996dc2cadad45edeeed6
-- </PALETTE>

