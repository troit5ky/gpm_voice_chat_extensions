if (CLIENT) then
    return
end

local packageName = "Voice Chat Extensions"

do

    /*
        ConVar's
    */

    local dead_talkers = CreateConVar("voice_dead_talk", "0", FCVAR_ARCHIVE, " - Allows dead players talk with alive players.", 0, 1 ):GetBool()
    cvars.AddChangeCallback("voice_dead_talk", function( name, old, new ) dead_talkers = new == "1" end, packageName)

    local can_hear_himself = CreateConVar("voice_hear_himself", "0", FCVAR_ARCHIVE, " - Allows players hear himself?", 0, 1 ):GetBool()
    cvars.AddChangeCallback("voice_hear_himself", function( name, old, new ) can_hear_himself = new == "1" end, packageName)

    local distance = CreateConVar( "voice_distance", "256", FCVAR_ARCHIVE, " - Voice chat distance.", -1, math.huge ):GetInt() ^ 2
    cvars.AddChangeCallback("voice_distance", function( name, old, new ) distance = tonumber( new ) ^ 2 end, packageName)

    local max_distance = CreateConVar( "voice_max_distance", "512", FCVAR_ARCHIVE, " - Voice chat maximal distance.", -1, math.huge ):GetInt() ^ 2
    cvars.AddChangeCallback("voice_max_distance", function( name, old, new ) max_distance = tonumber( new ) ^ 2 end, packageName)

    local dead_hear_dead = CreateConVar("voice_dead_hear_dead", "0", FCVAR_ARCHIVE, " - Allows dead players hear another dead players.", 0, 1 ):GetBool()
    cvars.AddChangeCallback("voice_dead_hear_dead", function( name, old, new ) dead_hear_dead = new == "1" end, packageName)

    local dead_listeners = CreateConVar("voice_dead_hear", "0", FCVAR_ARCHIVE, " - Allows dead players hear a alive players.", 0, 1 ):GetBool()
    cvars.AddChangeCallback("voice_dead_hear", function( name, old, new ) dead_listeners = new == "1" end, packageName)

    /*
        Player Meta Functions
    */

    local PLAYER = FindMetaTable( "Player" )

    function PLAYER:CanTalk()
        if self:Alive() then
            return true
        end

        return dead_talkers
    end

    do

        local util_TraceLine = util.TraceLine
        local IsValid = IsValid

        function PLAYER:CanHear( ply )
            if (self:EntIndex() == ply:EntIndex()) then
                return can_hear_himself
            end

            if self:Alive() then

                if ply:Alive() then

                    local listener_pos = self:LocalToWorld( self:OBBCenter() )
                    local talker_pos = ply:LocalToWorld( ply:OBBCenter() )

                    if (listener_pos:DistToSqr( talker_pos ) < distance) then
                        return true
                    end

                    local trace = util_TraceLine({
                        ["start"] = listener_pos,
                        ["endpos"] = talker_pos,
                        ["filter"] = self
                    })

                    if IsValid( trace.Entity ) and (trace.Entity:EntIndex() == ply:EntIndex()) and (listener_pos:DistToSqr( trace.HitPos ) < max_distance) then
                        return true
                    end

                    return self:TestPVS( ply )
                end

            else

                if ply:Alive() then
                    return dead_listeners
                end

                return dead_hear_dead
            end

            return ply:CanTalk()
        end

    end

end

hook.Add("PlayerCanHearPlayersVoice", packageName, function( listener, talker )
    if listener:CanHear( talker ) then return end
    return false
end)