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
function PointSet:new()self._points={}end
function PointSet:add(v,object)
 self._points[v]=object
end
function hypot2(a,b,c,d)return math.sqrt((a-c)^2+(b-d)^2)end
function PointSet:find_near(v, dist)
 local results={}
 for bv,b in pairs(self._points)do
  local d=hypot2(v.x,v.y,bv.x,bv.y)
  if 0.1<d and d<dist then results[b]=d end
 end
 return results
end
function PointSet:find_nearest(v, dist)
 local results={}
 local cur_dist=dist
 local cur_nearest
 for bv,b in pairs(self._points)do
  local d=hypot2(v.x,v.y,bv.x,bv.y)
  if 0.1<d and d<cur_dist then cur_nearest=b;cur_dist=d end
 end
 return cur_nearest, cur_dist
end
Vect2=Class:extend()
function Vect2:new(x,y)self.x=x self.y=y end
function Vect2:__len()return math.sqrt(self.x^2+self.y^2) end
function Vect2:__sub(v2)return Vect2(self.x-v2.x,self.y-v2.y)end
function Vect2:__add(v2)return Vect2(self.x+v2.x,self.y+v2.y)end
function Vect2:__mul(m)return Vect2(self.x*m,self.y*m)end
function Vect2:__eq(m)return self.x==m.x and self.y==m.y end
function Vect2:__tostring()return"("..self.x..", "..self.y..")"end
function Vect2:norm()
 if self.x~=.0 or self.y~=.0 then
  return self*(1.0/#self)
 else
  return Vect2(.0,.0)
 end
end

REPEL_FISH_DIST=15
REPEL_SHARK_DIST=40
REPEL_PENGUIN_DIST=20


Player=Class:extend()
Player.repel_distance=REPEL_PENGUIN_DIST

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
 if up and self.y > SURFACE then self.y=self.y-.5 end
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
Fish.prev_move=Vect2(.0,.0)

function Fish.draw_all()
 local ps=PointSet()
 for f in pairs(Fish.list) do
  f:draw()
  ps:add(Vect2(f.x,f.y), f)
 end
 local dir,dist,move,pos,penguin
 --[[ Behavior of fish
 Stay in screen - when moving to the edge push the fish back
 Don't go over surface - prevent fish moving over the water surface
 Synchronize speed with the flock
 ]]
 local fish_mass=Vect2(.0,.0)
 local fish_move=Vect2(.0,.0)
 local count=0
 for f in pairs(Fish.list) do
  fish_mass=fish_mass+Vect2(f.x,f.y)
  count=count+1
 end
 if count>0 then
  fish_mass=fish_mass*(1.0/count)
 end
 for f in pairs(Fish.list) do
  fish_move = fish_move + f:move(ps,fish_mass)
 end
 Fish.prev_move = fish_move:norm()
end

function Fish:new(x,y)
 self.x=x
 self.y=y
 self.turn = RIGHT
 set_add(Fish.list,self)
end

function Fish:move(ps,fish_mass)
 local fish_vector, predator_vector
 fish_repel=Vect2(0,0)
 fish_pos=Vect2(self.x,self.y)
 local nearest = ps:find_nearest(fish_pos, REPEL_FISH_DIST)
 if nearest then
  fish_repel=fish_repel + (Vect2(nearest.x,nearest.y) - fish_pos)
 end
 fish_attract=fish_mass-fish_pos
 predator_vector=Vect2(.0,.0)
 local threatened = false
 for _,predator in ipairs({player, shark}) do
  local pred_v=Vect2(predator.x,predator.y)-fish_pos
  if #pred_v < predator.repel_distance then
   predator_vector=predator_vector+pred_v
   threatened = true
  end
 end
 local center = (Vect2(120, 70) - fish_pos):norm()
 move=predator_vector:norm()*-4 + fish_attract:norm() + fish_repel:norm()*-2 + Fish.prev_move + center*0.5
 move=move:norm() * (threatened and 1.0 or 0.3)
 self.x=self.x+move.x
 self.y=self.y+move.y
 if self.y < SURFACE then self.y = SURFACE end
 if move.x < 0 then self.turn=LEFT else self.turn=RIGHT end
 return move
end

function Fish:draw()
 spr(SPR.FISH,self.x,self.y,1,1,self.turn==RIGHT and 0 or 1)
end

Shark=Class:extend()
Shark.repel_distance=REPEL_SHARK_DIST
function Shark:new()
 self:generate()
end

function Shark:generate()
 self.y=math.random(SURFACE, 136-16)
 if math.random(0,1) == 1 then
  self.turn=LEFT
  self.x=250
 else
  self.turn=RIGHT
  self.x=-30
 end
end

function Shark:draw()
 if self.turn==LEFT then
     spr(SPR.SHARK,self.x,self.y,1,1,0,0,4,2)
     self.x = self.x - 1
     if self.x < -100 then
       self:generate()
     end
 else
     spr(SPR.SHARK,self.x,self.y,1,1,1,0,4,2)
     self.x = self.x + 1
     if self.x > 340 then
       self:generate()
     end
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

SURFACE = 20

function init()
 for i=1,20 do
   Fish(math.random(240),math.random(110)+16)
 end
 shark=Shark()
end

function TIC()
 player:control(btn(0),btn(1),btn(2),btn(3))
 draw_water()
 Fish.draw_all()
 for b in pairs(Bubble.list) do
  b:draw()
 end
 player:draw()
 shark:draw()
 --print("CATCH THE FISH!",84,64)
 t=t+1
end

function draw_water()
 local i,shift
 cls(8)
 rect(0,SURFACE,240,136-SURFACE,1)
 for i=0,8 do
  local shift=t//2 % 32
  spr(SPR.WATER,-32+shift+i*32,SURFACE-8,8,1,0,0,4,1)
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
-- 064:1111111111101111110000111100000111000011111011111111111111111111
-- 080:1111111111111111111111111111111111111111111111111111000030000000
-- 081:1111111111111110111111001111100011110000111000000000000000000000
-- 082:1111111111111111011111110111111101111111011111110000011100000000
-- 083:1111111111111111111111111111111111111101111110010110000100000011
-- 096:3330000013333333111333331111133311111111111111111111111111111111
-- 097:0000000033333330300003333000003311000011111000011111100011111111
-- 098:0000000000000000333333333330110111101111111111111111111111111111
-- 099:0000011100000111330011111330011111130011111133111111111111111111
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
