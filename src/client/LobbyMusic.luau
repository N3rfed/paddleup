-- Two-track lobby playlist; pausing preserves both tracks during a crossfade.
local LobbyMusic={}
function LobbyMusic.new()
 local SoundService=game:GetService("SoundService")
 local tracks={}
 for index,id in ipairs({139556245377384,9043496528}) do
  local sound=Instance.new("Sound")
  sound.Name=index==1 and "LobbyMusic" or "LobbyMusicVice"
  sound.SoundId="rbxassetid://"..id
  sound.Looped=false; sound.Volume=0
  sound.Parent=SoundService
  tracks[index]=sound
 end
 local volume,fadeDuration=0.2,3
 local active,index,transition=false,1,nil
 local self={}
 local function beginTransition()
  local nextIndex=index==1 and 2 or 1
  local incoming=tracks[nextIndex]
  if not incoming.IsLoaded then return end
  incoming.Volume=0; incoming.TimePosition=0; incoming:Play()
  transition={outgoing=index,incoming=nextIndex,elapsed=0}
 end
 local connection=game:GetService("RunService").Heartbeat:Connect(function(dt)
  if not active then return end
  if transition then
   transition.elapsed=math.min(fadeDuration,transition.elapsed+dt)
   local alpha=transition.elapsed/fadeDuration
   tracks[transition.outgoing].Volume=volume*(1-alpha)
   tracks[transition.incoming].Volume=volume*alpha
   if alpha>=1 then
    tracks[transition.outgoing]:Stop()
    index=transition.incoming; transition=nil
   end
  else
   local current=tracks[index]
   if current.IsLoaded and current.TimeLength>0
    and (current.TimePosition>=current.TimeLength-fadeDuration or not current.IsPlaying) then
    beginTransition()
   end
  end
 end)
 function self:setActive(enabled)
  if active==enabled then return end
  active=enabled
  if enabled then
   if transition then
    tracks[transition.outgoing]:Resume()
    tracks[transition.incoming]:Resume()
   else
    tracks[index].Volume=volume
    tracks[index]:Resume()
   end
  else
   for _,sound in ipairs(tracks) do sound:Pause() end
  end
 end
 function self:destroy()
  active=false; connection:Disconnect()
  for _,sound in ipairs(tracks) do sound:Destroy() end
 end
 -- Load the second track before it is needed without blocking the menu.
 task.spawn(function()
  local ok,err=pcall(function() game:GetService("ContentProvider"):PreloadAsync(tracks) end)
  if not ok then warn("Lobby music preload failed: "..tostring(err)) end
 end)
 return self
end
return LobbyMusic
