TOOL.Category   = "Metro"
TOOL.Name       = "Signalling Tool"
TOOL.Command    = nil
TOOL.ConfigName = ""
TOOL.ClientConVar["signaldata"] = ""
TOOL.ClientConVar["signdata"] = ""
TOOL.ClientConVar["autodata"] = ""
TOOL.ClientConVar["type"] = 1
TOOL.ClientConVar["routetype"] = 1

if SERVER then util.AddNetworkString "metrostroi-stool-signalling" end


local Types = {"Signal","Sign","Autodrive",[0] = "Choose Type"}
local TypesOfSignal = {"Inside","Outside big","Outside small","Small","Virus New","pz"}
local TypesOfSign = {"NF","40","60","70","80","Station border","C(horn) Street","STOP Street","Dangerous","Deadlock",
    "Stop marker","!(stop)","X","T Start","T End","T Sbor(engage)","Engines off","Engines on","C(horn)","T stop emer","Shod",
    "Left doors","Phone▲","Phone▼","1up","STOP Street cyka","NF outside","35 outside","40 outside","60 outside","70 outside","80 outside",
    "T Sbor(engage) outside","35","Dangerous 200","CR End","CR End(inv)","2up","3up","4up","5up","6up","X outside", "Metal","50","50 outside","Hod2","Hod3","Green shield", "Yellow shield", 
    "0o", "1o", "2o", "3o", "4o", "5o", "6o", "7o", "8o", "9o", "10o", "11o", "12o", "13o",
    "0o-st", "1o-st", "2o-st", "3o-st", "4o-st", "5o-st", "6o-st", "7o-st", "8o-st", "9o-st", "10o-st", "11o-st", "12o-st", "13o-st",
}
local RouteTypes = {"Auto", "Manual","Repeater","Emerg"}

local TypesOfAuto = {
    "Drive commands","Station brake command", "Door command","Light sensor","PA Marker","UPPS Sensor","SBPP Sensor"
}
TOOL.Type = 0
TOOL.RouteType = 1

--TOOL.Signal.Type = 1

if CLIENT then
    language.Add("Tool.signalling.name", "Signalling Tool")
    language.Add("Tool.signalling.desc", "Adds and modifies signalling equipment (ARS/ALS) or signs")
    language.Add("Tool.signalling.0", "Primary: Spawn/update selected signalling entity (point at the inner side of rail)\nReload: Copy ARS/light settings\nSecondary: Remove")
    language.Add("Undone_signalling", "Undone ARS/signalling equipment")
end

function TOOL:SpawnSignal(ply,trace,param)
    local pos = trace.HitPos

    -- Use some code from rerailer --
    local tr = Metrostroi.RerailGetTrackData(pos,ply:GetAimVector())
    if not tr then return end
    -- Create self.Signal entity
    local ent
    local found = false
    local entlist = ents.FindInSphere(pos,64)
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_signal" then
            if v.Name==self.Signal.Name then
                ent = v
                found=0
                break
            end
            if not found or found > pos:Distance(v:GetPos()) then
                ent = v
                found = pos:Distance(v:GetPos())
            end
        end
    end
    if param == 2 then
        if not ent then return end
        self.Signal.Type = ent.SignalType + 1
        self.Signal.Name = ent.Name
        self.Signal.Lenses = ent.LensesStr
        self.Signal.RouteNumber =   ent.RouteNumber
        self.Signal.RouteNumberSetup =  ent.RouteNumberSetup
        self.Signal.IsolateSwitches = ent.IsolateSwitches
        self.Signal.Approve0 = ent.Approve0
        self.Signal.TwoToSix = ent.TwoToSix
        self.Signal.ARSOnly = ent.ARSOnly
        self.Signal.NonAutoStop = ent.NonAutoStop
        self.Signal.PassOcc = ent.PassOcc
        self.Signal.Routes = ent.Routes
        self.Signal.Left = ent.Left
        self.Signal.Double = ent.Double
        self.Signal.DoubleL = ent.DoubleL
        net.Start("metrostroi-stool-signalling")
            net.WriteUInt(0,8)
            net.WriteTable(self.Signal)
        net.Send(self:GetOwner())
    else
        if not ent then ent = ents.Create("gmod_track_signal") end
        if IsValid(ent) then
            if param ~= 2 then
                ent:SetPos(tr.centerpos - tr.up * 9.5)
                ent:SetAngles((-tr.right):Angle())
            end
            if not found then
                ent:Spawn()
                -- Add to undo
                undo.Create("signalling")
                    undo.AddEntity(ent)
                    undo.SetPlayer(ply)
                undo.Finish()
            end
            ent.SignalType = self.Signal.Type - 1
            ent.ARSOnly = self.Signal.ARSOnly
            ent.Name = self.Signal.Name
            ent.LensesStr = self.Signal.Lenses
            ent.RouteNumber =   self.Signal.RouteNumber
            ent.RouteNumberSetup =  self.Signal.RouteNumberSetup
            ent.IsolateSwitches = self.Signal.IsolateSwitches
            ent.Approve0 = self.Signal.Approve0
            ent.NonAutoStop = self.Signal.NonAutoStop
            ent.TwoToSix = self.Signal.TwoToSix
            ent.Routes = self.Signal.Routes
            ent.Left = self.Signal.Left
            ent.Double = self.Signal.Double
            ent.DoubleL = self.Signal.DoubleL
            ent.Lenses = string.Explode("-",ent.LensesStr)
            ent.PassOcc = self.Signal.PassOcc
            ent.InS = nil
            ent:SendUpdate()
            for i = 1,#ent.Lenses do
                if ent.Lenses[i]:find("W") then
                    ent.InS = i
                end
            end
            Metrostroi.UpdateSignalEntities()
            Metrostroi.PostSignalInitialize()
        end
        return ent
    end
end

function TOOL:SpawnSign(ply,trace,param)
    local pos = trace.HitPos

    -- Use some code from rerailer --
    local tr = Metrostroi.RerailGetTrackData(pos,ply:GetAimVector())
    if not tr then return end
    -- Create self.Sign entity
    local ent
    local found = false
    local entlist = ents.FindInSphere(pos,64)
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_signs" then
            ent = v
            found = true
        end
    end
    if param == 2 then
        if not ent then return end
        self.Sign.Type = ent.SignType
        self.Sign.YOffset = ent.YOffset
        self.Sign.ZOffset = ent.ZOffset
        self.Sign.Left = ent.Left
        net.Start("metrostroi-stool-signalling")
            net.WriteUInt(1,8)
            net.WriteTable(self.Sign)
        net.Send(self:GetOwner())
    else
        if not ent then ent = ents.Create("gmod_track_signs") end
        if IsValid(ent) then
            if param ~= 2 then
                ent:SetPos(tr.centerpos - tr.up * 9.5)
                ent:SetAngles((-tr.right):Angle() + Angle(0,90,0))
            end
            if not found then
                ent:Spawn()
                -- Add to undo
                undo.Create("signalling")
                    undo.AddEntity(ent)
                    undo.SetPlayer(ply)
                undo.Finish()
            end
            ent.SignType = self.Sign.Type
            ent.YOffset = self.Sign.YOffset
            ent.ZOffset = self.Sign.ZOffset
            ent.Left = self.Sign.Left
            ent:SendUpdate()
        end
        return ent
    end
end

function TOOL:SpawnAutoPlate(ply,trace,param)
    local pos = trace.HitPos

    -- Use some code from rerailer --
    local tr = Metrostroi.RerailGetTrackData(pos,ply:GetAimVector())
    if not tr then return end

    local ent
    local found = false
    local entlist = ents.FindInSphere(pos,self.Auto.Type == 5 and 192 or 64)
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_pa_marker" and self.Auto.Type == 5 or v:GetClass() == "gmod_track_autodrive_plate" and v.PlateType == self.Auto.Type and not v.Linked then
            ent = v
            found = true
            break
        end
    end
    if param == 2 then
        if not ent then return end
        --self.Auto.Type = ent.PlateType

        if self.Auto.Type == METROSTROI_ACOIL_DRIVE then
            self.Auto.Right = ent.Right
            self.Auto.Mode = ent.Mode
            self.Auto.StationID = ent.StationID
            self.Auto.StationPath = ent.StationPath
        elseif self.Auto.Type == METROSTROI_ACOIL_DOOR then
            self.Auto.Right = ent.Right
        elseif self.Auto.Type == 5 then
            self.Auto.PAType = ent.PAType or 1
            if self.Auto.PAType == 1 then
                self.Auto.PAStationPath = ent.PAStationPath
                self.Auto.PAStationID = ent.PAStationID
                self.Auto.PAStationName = ent.PAStationName
                self.Auto.PALastStation = ent.PALastStation
                self.Auto.PAWrongPath = ent.PAWrongPath
                self.Auto.PADeadlockStart = ent.PADeadlockStart
                self.Auto.PADeadlockEnd = ent.PADeadlockEnd
                self.Auto.PALineChange = ent.PALineChange
                self.Auto.PALineChangeStationPath = ent.PALineChangeStationPath
                self.Auto.PALineChangeStationID = ent.PALineChangeStationID
                self.Auto.PALastStationName = ent.PALastStationName
                self.Auto.PAStationHasSwtiches = ent.PAStationHasSwtiches
                self.Auto.PAStationRightDoors = ent.PAStationRightDoors
                self.Auto.PAStationHorlift = ent.PAStationHorlift
            end
        elseif self.Auto.Type == METROSTROI_SBPPSENSOR and not ent.Linked then
            self.Auto.SBPPType = ent.Type
            self.Auto.SBPPDeadlock = ent.IsDeadlock
            self.Auto.SBPPStationPath = ent.StationPath
            self.Auto.SBPPStationID = ent.StationID
            self.Auto.SBPPDriveMode = ent.DriveMode
            self.Auto.SBPPRightDoors = ent.RightDoors
            self.Auto.SBPPWTime = ent.WTime
            self.Auto.SBPPRK = ent.RKPos
            self.Auto.LXp = ent.DistanceToOPV
        end
        self.Auto.LXp = ent.DistanceToOPV or ent.LXp or self.Auto.LXp
        self.Auto.LYp = ent.LYp or self.Auto.LYp
        self.Auto.LZp = ent.LZp or self.Auto.LZp
        net.Start("metrostroi-stool-signalling")
            net.WriteUInt(2,8)
            net.WriteTable(self.Auto)
        net.Send(self:GetOwner())
    else
        if self.Auto.Type ~= 5 then
            if not ent then ent = ents.Create("gmod_track_autodrive_plate") end
            if IsValid(ent) then
                local angle = (-tr.right):Angle()
                angle:RotateAroundAxis(tr.up,90)

                ent.PlateType = self.Auto.Type
                local center = (tr.centerpos - tr.up * 9.5)
                if self.Auto.Type == METROSTROI_ACOIL_DRIVE then
                    local dist = 50
                    if self.Auto.Dist == 1 then
                        ent.Model = "models/metrostroi/signals/autodrive/doska5.mdl"
                        dist = 5
                    elseif self.Auto.Dist == 2 then
                        ent.Model = "models/metrostroi/signals/autodrive/doska20.mdl"
                        dist = 20
                    else
                        ent.Model = "models/metrostroi/signals/autodrive/doska50.mdl"
                    end
                    ent.Right = self.Auto.Right
                    ent.Mode = self.Auto.Mode
                    if self.Auto.Mode == 3 or self.Auto.Mode == 4 then
                        dist = -dist/2+2.5+1.5
                        ent.StationID = self.Auto.StationID
                        ent.StationPath = self.Auto.StationPath
                    else
                        dist = 0
                        ent.StationID = nil
                        ent.StationPath = nil
                    end

                    if self.Auto.Mode < 3 or self.Auto.Mode == 5 or 6 < self.Auto.Mode then ent.Power = true end
                    if ent.Right then
                        ent:SetPos(center + (tr.forward*(-(dist)/0.01905)+tr.right*-66+tr.up*5))
                    else
                        ent:SetPos(center + (tr.forward*(-(dist)/0.01905)+tr.right*66+tr.up*5))
                    end
                elseif self.Auto.Type == METROSTROI_ACOIL_SBRAKE then
                    ent.Model = "models/metrostroi/signals/autodrive/doska160.mdl"
                    ent:SetPos(center + (tr.forward*(-(80+2.5+1.5+0.4)/0.01905)+tr.right*66+tr.up*5)) ---75
                elseif self.Auto.Type == METROSTROI_ACOIL_DOOR then
                    ent.Model = "models/metrostroi/signals/autodrive/doska5.mdl"
                    ent.Right = self.Auto.Right
                    if ent.Right then
                        ent:SetPos(center + (tr.forward*(-(4-2.5)/0.01905)+tr.right*66+tr.up*5))
                    else
                        ent:SetPos(center + (tr.forward*(-(4-2.5)/0.01905)+tr.right*-66+tr.up*5))
                    end
                elseif self.Auto.Type == METROSTROI_LSENSOR then
                    ent.Model = "models/mus/metro/station_marker_4.mdl"
                    ent:SetPos(center + (tr.forward*(-(self.Auto.LXp or 0)/0.01905)+tr.right*((self.Auto.LYp or 0)/0.01905+120)+tr.up*((self.Auto.LZp or 0)/0.01905+130)))
                    angle:RotateAroundAxis(tr.up,90)
                elseif self.Auto.Type == METROSTROI_UPPSSENSOR then
                    ent.Model = "models/metrostroi/upps.mdl"
                    ent:SetPos(center + (tr.forward*(-(self.Auto.LXp or 0)/0.01905)+tr.right*((self.Auto.LYp or 0)/0.01905)+tr.up*((0.8+(self.Auto.LZp or 0))/0.01905)))
                    ent.DistanceToOPV = self.Auto.LXp
                    ent.UPPS=true
                    angle:RotateAroundAxis(tr.forward,self.Auto.Roll or 0)
                elseif self.Auto.Type == METROSTROI_SBPPSENSOR then
                    ent.SBPPType = self.Auto.SBPPType or 1
                    ent.IsDeadlock = ent.SBPPType<=3 and self.Auto.SBPPDeadlock
                    ent.StationPath = 2<=ent.SBPPType and ent.SBPPType<=3 and tonumber(self.Auto.SBPPStationPath)
                    ent.StationID = 2<=ent.SBPPType and ent.SBPPType<=3 and tonumber(self.Auto.SBPPStationID)
                    ent.DriveMode = ent.SBPPType==3 and self.Auto.SBPPDriveMode
                    ent.RightDoors = ent.SBPPType==3 and self.Auto.SBPPRightDoors
                    ent.WTime = (ent.SBPPType==3 or ent.SBPPType>=5) and self.Auto.SBPPWTime
                    ent.RKPos = ent.SBPPType==7 and self.Auto.SBPPRK
                    if ent.SBPPType<=2 then ent.DistanceToOPV = self.Auto.LXp end
                    ent.Model = "models/metrostroi/signals/autodrive/rfid.mdl"
                    local pos
                    if ent.SBPPType==1 then
                        pos = center
                    else
                        pos = center + (tr.forward*(-(self.Auto.LXp or 0)/0.01905)+tr.right*(-80+(self.Auto.LYp or 0)/0.01905)+tr.up*(52+(self.Auto.LZp or 0)/0.01905))
                    end
                    angle:RotateAroundAxis(tr.up,90)
                    angle:RotateAroundAxis(tr.forward,90)
                    if ent.SBPPType==1 then
                        local rpos = Metrostroi.GetPositionOnTrack(pos,angle)
                        local res = rpos[1]
                        if res then
                            local tpos, tang = Metrostroi.GetTrackPosition(res.path,res.x-self.Auto.LXp*(self.Auto.LInvX and -1 or 1))
                            if tpos then
                                tang = tang:Angle()
                                pos = tpos + (tang:Right()*(-79+(self.Auto.LYp or 0)/0.01905)*(self.Auto.LRightP and -1 or 1)+tang:Up()*(-60+(self.Auto.LZp or 0)/0.01905))

                                tang:RotateAroundAxis(tang:Up(),-90)
                                tang:RotateAroundAxis(tang:Right(),self.Auto.LRightP and 90 or -90)
                                angle = tang
                            end
                        end
                    elseif ent.SBPPType==3 and not ent.BrakeProps then
                        ent.BrakeProps = {}
                        for i=-1,1,2 do
                            local entL = ents.Create("gmod_track_autodrive_plate")
                            entL.Model = "models/metrostroi/signals/autodrive/rfid.mdl"
                            entL:SetPos(pos + (tr.forward*(-1.5*i)/0.01905))
                            entL:SetModel(ent.Model)
                            entL:SetAngles(angle)
                            entL:Spawn()
                            entL.Linked = ent
                            entL.SBPPType = ent.SBPPType
                            entL.PlateType = METROSTROI_SBPPSENSOR
                            table.insert(ent.BrakeProps,entL)
                        end
                    end
                    ent:SetPos(pos)
                end
                if not ent.DistanceToOPV then ent.LXp = self.Auto.LXp end
                ent.LYp = self.Auto.LYp
                ent.LZp = self.Auto.LZp
                ent:SetModel(ent.Model)
                ent:SetAngles(angle)
            end
        else
            if not ent then ent = ents.Create("gmod_track_pa_marker") end
            if IsValid(ent) then
                local angle = (tr.forward):Angle()
                local center = (tr.centerpos - tr.up * 9.5)
                --angle:RotateAroundAxis(tr.up,90)
                ent.PAType = self.Auto.PAType
                ent.PAStationPath = tonumber(self.Auto.PAStationPath)
                ent.PAStationID = tonumber(self.Auto.PAStationID)
                ent.PAStationName = self.Auto.PAStationName
                ent.PALastStation = self.Auto.PALastStation
                ent.PAWrongPath = self.Auto.PAWrongPath
                ent.PADeadlockStart = self.Auto.PADeadlockStart
                ent.PADeadlockEnd = self.Auto.PADeadlockEnd
                ent.PALineChange = self.Auto.PALineChange
                ent.PALineChangeStationPath = self.Auto.PALineChangeStationPath
                ent.PALineChangeStationID = self.Auto.PALineChangeStationID
                ent.PALastStationName = self.Auto.PALastStationName
                ent.PAStationRightDoors = self.Auto.PAStationRightDoors
                ent.PAStationHorlift = self.Auto.PAStationHorlift
                ent.PAStationHasSwtiches = self.Auto.PAStationHasSwtiches
                ent:UpdateTrackPos(center,angle)
            end
        end
        if not found then
            ent:Spawn()
            -- Add to undo
            undo.Create("signalling")
                undo.AddEntity(ent)
                undo.SetPlayer(ply)
            undo.Finish()
        end
        return ent
    end
end

function TOOL:LeftClick(trace)
    if CLIENT then
        return true
    end

    --self.Signal = util.JSONToTable(self:GetClientInfo("signaldata"):replace("''","\""))
    --if not self.Signal then return end
    local ply = self:GetOwner()
    if (ply:IsValid()) and (not ply:IsAdmin()) then return false end
    if not trace then return false end
    if trace.Entity and trace.Entity:IsPlayer() then return false end

    local ent
    if self.Type == 1 then
        ent = self:SpawnSignal(ply,trace)
    elseif self.Type == 2 then
        ent = self:SpawnSign(ply,trace)
    elseif self.Type == 3 then
        ent = self:SpawnAutoPlate(ply,trace)
    end

    return true
end


function TOOL:RightClick(trace)
    if CLIENT then
        return true
    end

    local ply = self:GetOwner()
    if (ply:IsValid()) and (not ply:IsAdmin()) then return false end
    if not trace then return false end
    if trace.Entity and trace.Entity:IsPlayer() then return false end

    local entlist = ents.FindInSphere(trace.HitPos,(self.Type == 3 and self.Auto.Type == 5) and 192 or 64)
    for k,v in pairs(entlist) do
        if v:GetClass() == "gmod_track_signal" and self.Type == 1 then
            if IsValid(v) then SafeRemoveEntity(v) end
        end
        if v:GetClass() == "gmod_track_switch" then
            if IsValid(v) then SafeRemoveEntity(v) end
        end
        if v:GetClass() == "gmod_track_signs" and self.Type == 2 then
            if IsValid(v) then SafeRemoveEntity(v) end
        end
        if v:GetClass() == "gmod_track_autodrive_plate" and self.Type == 3 and self.Auto.Type == v.PlateType then
            if IsValid(v) then SafeRemoveEntity(v) end
        end
        if v:GetClass() == "gmod_track_pa_marker" and self.Type == 3 and self.Auto.Type == 5 then
            if IsValid(v) then SafeRemoveEntity(v) end
        end
    end
    return true
end

function TOOL:Reload(trace)
    if CLIENT then return true end
    --self.Signal = util.JSONToTable(self:GetClientInfo("signaldata"):replace("''","\""))

    local ply = self:GetOwner()
    --if not (ply:IsValid()) and (not ply:IsAdmin()) then return false end
    if not trace then return false end
    if trace.Entity and trace.Entity:IsPlayer() then return false end
    local ent
    if self.Type == 1 then
        ent = self:SpawnSignal(ply,trace,2)
    elseif self.Type == 2 then
        ent = self:SpawnSign(ply,trace,2)
    elseif self.Type == 3 then
        ent = self:SpawnAutoPlate(ply,trace,2)
    end
    return true
end

function TOOL:SendSettings()
    if self.Type == 1 then
        if not self.Signal then return end
        RunConsoleCommand("signalling_signaldata",util.TableToJSON(self.Signal))
        net.Start "metrostroi-stool-signalling"
            net.WriteUInt(0,8)
            --net.WriteEntity(self)
            net.WriteTable(self.Signal)
        net.SendToServer()

    elseif self.Type == 2 then
        if not self.Sign then return end
        RunConsoleCommand("signalling_signdata",util.TableToJSON(self.Sign))
        net.Start "metrostroi-stool-signalling"
            net.WriteUInt(1,8)
            --net.WriteEntity(self)
            net.WriteTable(self.Sign)
        net.SendToServer()
    elseif self.Type == 3 then
        if not self.Auto then return end
        RunConsoleCommand("signalling_autodata",util.TableToJSON(self.aUTO))
        net.Start "metrostroi-stool-signalling"
            net.WriteUInt(2,8)
            --net.WriteEntity(self)
            net.WriteTable(self.Auto)
        net.SendToServer()
    end
end

net.Receive("metrostroi-stool-signalling", function(_, ply)
    local TOOL = LocalPlayer and LocalPlayer():GetTool("signalling") or ply:GetTool("signalling")
    local typ = net.ReadUInt(8)
    if typ == 2 then
        TOOL.Auto = net.ReadTable()
        if CLIENT then
            RunConsoleCommand("signalling_signdata",util.TableToJSON(TOOL.Auto))
            NeedUpdate = true
        end
    elseif typ == 1 then
        TOOL.Sign = net.ReadTable()
        if CLIENT then
            RunConsoleCommand("signalling_signdata",util.TableToJSON(TOOL.Sign))
            NeedUpdate = true
        end
    elseif typ == 0 then
        TOOL.Signal = net.ReadTable()
        if CLIENT then
            RunConsoleCommand("signalling_signaldata",util.TableToJSON(TOOL.Signal))
            NeedUpdate = true
        end
    end
    TOOL.Type = typ+1
end)

function TOOL:BuildCPanelCustom()
    local tool = self
    local CPanel = controlpanel.Get("signalling")
    if not CPanel then return end
    --("signalling_signaldata",util.TableToJSON(tool.Signal))
    --tool.Type = GetConVarNumber("signalling_type") or 1
    tool.RouteType = GetConVarNumber("signalling_routetype") or 1
    CPanel:ClearControls()
    CPanel:SetPadding(0)
    CPanel:SetSpacing(0)
    CPanel:Dock( FILL )
    local VType = vgui.Create("DComboBox")
        VType:ChooseOption(Types[tool.Type],tool.Type)
        VType:SetColor(color_black)
        for i = 1,#Types do
            VType:AddChoice(Types[i])
        end
        VType.OnSelect = function(_, index, name)
            VType:SetValue(name)
            tool.Type = index
            tool:SendSettings()
            tool:BuildCPanelCustom()
        end
    CPanel:AddItem(VType)
    if tool.Type == 1 then
        local VSType = vgui.Create("DComboBox")
			print(tool.Signal.Type)
            VSType:ChooseOption(TypesOfSignal[tool.Signal.Type or 1],tool.Signal.Type or 1)
            VSType:SetColor(color_black)
            for i = 1,#TypesOfSignal do
                VSType:AddChoice(TypesOfSignal[i])
            end
            VSType.OnSelect = function(_, index, name)
				print('select')
				print(index)
                VSType:SetValue(name)
                tool.Signal.Type = index
                tool:SendSettings()
            end
        CPanel:AddItem(VSType)
        local VNameT,VNameN = CPanel:TextEntry("Name:")
                VNameT:SetTooltip("Name. Letters or digits!\nFor example:IND2")
                VNameT:SetValue(tool.Signal.Name or "")
                VNameT:SetEnterAllowed(false)
                function VNameT:OnChange()
                    local oldval = self:GetValue()
                    local pos = self:GetCaretPos()
                    local NewValue = ""
                    for i = 1,10 do
                        NewValue = NewValue..((oldval[i] or ""):upper():match("^[%u%d%s/]+") or "")
                    end
                    self:SetText(NewValue)
                    self:SetCaretPos(pos < #NewValue and pos or #NewValue)
                end
                function VNameT:OnLoseFocus()
                    tool.Signal.Name = self:GetValue()
                    tool:SendSettings()
                end
        if not tool.Signal.ARSOnly then
            local VLensT,VLensN = CPanel:TextEntry("Lenses:")
                VLensT:SetTooltip("G - Green, Y - Yellow, R - Red,  B - Blue, W - White, M - Routing Pointer\nExample: GYG-RW-M")
                VLensT:SetValue(tool.Signal.Lenses or "")
                VLensT:SetEnterAllowed(false)
                function VLensT:OnChange()
                    local NewValue = ""
                    for i = 1,#self:GetValue() do
                        NewValue = NewValue..((self:GetValue()[i] or ""):upper():match("[RYGWBM-]") or "")
                    end
                    local NewValueT = string.Explode("-",NewValue)
                    local maxval = tool.Signal.Type == 3 and 4 or 3
                    for id,text in ipairs(NewValueT) do
                        if id > 4 then
                            for i = 5,#NewValueT do
                                table.remove(NewValueT,i)
                            end
                            break
                        end
                        if text:find("M") then
                            if text[1] == "M" then
                                NewValueT[id] = "M"
                            else
                                NewValueT[id] = text:gsub("M","")
                                id = id + 1
                                NewValueT[id] = "M"
                            end
                            for i = id+1,#NewValueT do
                                table.remove(NewValueT, i)
                            end
                            break
                        end
                        text = text:match("[RYGWB]+") or ""
                        --[[local WFind = id==3 and text:find("W") or nil
                        --print(MFind,id)
                        if WFind then
                            if text:find("M") then
                                NewValueT[#NewValueT+1] = "M"
                            end

                            NewValueT[id] = "W"
                        else]]
                            NewValueT[id] = text:sub(1,maxval)
                            if #text > maxval then
                                NewValueT[#NewValueT+1] = text:sub(maxval+1,#text)
                            end
                        --end
                        --[[
                        if MID > 0 then
                            for i = MID,#NewValueT do
                                table.remove(NewValueT,i)
                            end
                            break
                        end]]
                    end
                    local NewValue = table.concat(NewValueT,"-")
                    self:SetText(NewValue)
                    self:SetCaretPos(#NewValue)
                end
                function VLensT:OnLoseFocus()
                    tool.Signal.Lenses = self:GetValue()
                    tool:SendSettings()
                end
        end
        if tool.Signal.Type == 1 then
            local VRoutT,VRoutN = CPanel:TextEntry("Custom route number:")
                VRoutT:SetTooltip("Custom routte number. Can be empty. For example:12WK")
                VRoutT:SetValue(tool.Signal.RouteNumberSetup or "")
                VRoutT:SetEnterAllowed(false)
                function VRoutT:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[1-4DWKFLRX]+") or "")
                    end
                    local oldpos = self:GetCaretPos()
                    self:SetText(NewValue:sub(1,5))
                    self:SetCaretPos(math.min(5,oldpos))
                end
                function VRoutT:OnLoseFocus()
                    tool.Signal.RouteNumberSetup = self:GetValue()
                    tool:SendSettings()
                end
        end
        local VLeftC = CPanel:CheckBox("Left side")
                VLeftC:SetTooltip("Left side")
                VLeftC:SetValue(tool.Signal.Left or false)
                function VLeftC:OnChange()
                    tool.Signal.Left = self:GetChecked()
                    tool:SendSettings()
                end
        local VDoubleC = CPanel:CheckBox("Double side")
        if tool.Signal.Double then
            local VDoubleLC = CPanel:CheckBox("Double light")
                VDoubleLC:SetTooltip("DoubleL light")
                VDoubleLC:SetValue(tool.Signal.DoubleL or false)
                function VDoubleLC:OnChange()
                    tool.Signal.DoubleL = self:GetChecked() and tool.Signal.Double
                    self:SetChecked(tool.Signal.DoubleL)
                    tool:SendSettings()
                end
        end
        VDoubleC:SetTooltip("Double side")
        VDoubleC:SetValue(tool.Signal.Double or false)
        function VDoubleC:OnChange()
            tool.Signal.Double = self:GetChecked()
            tool.Signal.DoubleL = tool.Signal.DoubleL and self:GetChecked()
            tool:BuildCPanelCustom()
            --if tool.Signal.Double then VDoubleLC:SetChecked(tool.Signal.DoubleL and tool.Signal.Double) end
            tool:SendSettings()
        end
        local VRouT,VRouN = CPanel:TextEntry("Route number:")
                VRouT:SetTooltip("Route number. Can be empty. One digit or D.\nFor example:D")
                VRouT:SetValue(tool.Signal.RouteNumber or "")
                VRouT:SetEnterAllowed(false)
                function VRouT:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        if #NewValue > 0 then break end
                        NewValue = NewValue..((oldval[i] or ""):upper():match(tool.Signal.Type == 1 and "[%dDFLR]" or "[%dD]") or "")
                    end
                    self:SetText(NewValue)
                    self:SetCaretPos(0)
                end
                function VRouT:OnLoseFocus()
                    tool.Signal.RouteNumber = self:GetValue()
                    tool:SendSettings()
                end
        local VIsoSC = CPanel:CheckBox("Isolating switches")
                VIsoSC:SetTooltip("Is tool.Signal isolate switch signals")
                VIsoSC:SetValue(tool.Signal.IsolateSwitches or false)
                function VIsoSC:OnChange()
                    tool.Signal.IsolateSwitches = self:GetChecked()
                    tool:SendSettings()
                end
        local VAppC = CPanel:CheckBox("325Hz on 0")
                VAppC:SetTooltip("Is tool.Signal will be issuse 325Hz(for PA-KSD) on zero?")
                VAppC:SetValue(tool.Signal.Approve0 or false)
                function VAppC:OnChange()
                    tool.Signal.Approve0 = self:GetChecked()
                    tool:SendSettings()
                end
        local VAuStC = CPanel:CheckBox("Autostop")
                VAuStC:SetTooltip("Is autostop present or no?")
                if tool.Signal.NonAutoStop ~= nil then
                    VAuStC:SetValue(not tool.Signal.NonAutoStop)
                else
                    VAuStC:SetValue(true)
                end
                function VAuStC:OnChange()
                    tool.Signal.NonAutoStop = not self:GetChecked()
                    tool:SendSettings()
                end
        local VDepC = CPanel:CheckBox("2/6")
                VDepC:SetTooltip("Is Signal produces 2 freqencies or not?")
                VDepC:SetValue(tool.Signal.TwoToSix or false)
                function VDepC:OnChange()
                    tool.Signal.TwoToSix = self:GetChecked()
                    tool:SendSettings()
                end
        local VARSOC = CPanel:CheckBox("ARS Only")
                VARSOC:SetTooltip("ARS Box")
                VARSOC:SetValue(tool.Signal.ARSOnly or false)
                function VARSOC:OnChange()
                    tool.Signal.ARSOnly = self:GetChecked()
                    tool:SendSettings()
                    tool:BuildCPanelCustom()
                end
        local VPassOccC = CPanel:CheckBox("Pass occupation singal")
                VPassOccC:SetTooltip("Pass occupation singal")
                VPassOccC:SetValue(tool.Signal.PassOcc or false)
                function VPassOccC:OnChange()
                    tool.Signal.PassOcc = self:GetChecked()
                    tool:SendSettings()
                    --tool:BuildCPanelCustom()
                end

        for i = 1,(tool.Signal.Routes and #tool.Signal.Routes or 0) do
            local CollCat = vgui.Create("DForm")
            local rou = tool.Signal.Routes[i].Manual and 2 or tool.Signal.Routes[i].Repeater and 3 or tool.Signal.Routes[i].Emer and 4 or 1
            CollCat:SetLabel(RouteTypes[rou])
            CollCat:SetExpanded(1)
                local VTypeOfRouteI = vgui.Create("DComboBox")
                    --VType:SetValue("Choose tool.Type")
                    VTypeOfRouteI:ChooseOption(RouteTypes[rou],rou)
                    for i1 = 1,#RouteTypes do
                        VTypeOfRouteI:AddChoice(RouteTypes[i1])
                    end
                    VTypeOfRouteI.OnSelect = function(_, index, name)
                        VTypeOfRouteI:SetValue(name)
                        tool.Signal.Routes[i].Manual = index == 2
                        tool.Signal.Routes[i].Repeater = index == 3
                        tool.Signal.Routes[i].Emer = index == 4
                        tool:SendSettings()
                        self:BuildCPanelCustom()
                    end
                CollCat:AddItem(VTypeOfRouteI)
                local VRNT,VRNN = CollCat:TextEntry("Route name:")
                    VRNT:SetText(tool.Signal.Routes[i].RouteName or "")
                    VRNT:SetTooltip("Route name.\nIt uses for !sopen or !sclose")
                    function VRNT:OnLoseFocus()
                        tool.Signal.Routes[i].RouteName = self:GetValue()
                        tool:SendSettings()
                    end
                local VNexT,VNexN = CollCat:TextEntry("Next Signal:")
                    VNexT:SetText(tool.Signal.Routes[i].NextSignal or "")
                    VNexT:SetTooltip("Next Signal. Name of the next Signal.\nFor example:[113]IND2")
                    function VNexT:OnChange()
                        local oldval = self:GetValue()
                        local pos = self:GetCaretPos()
                        local NewValue = ""
                        for i = 1,10 do
                            NewValue = NewValue..((oldval[i] or ""):upper():match("[%u%d%s%*/]") or "")
                        end
                        self:SetText(NewValue)
                        self:SetCaretPos(pos < #NewValue and pos or #NewValue)
                    end
                    function VNexT:OnLoseFocus()
                        tool.Signal.Routes[i].NextSignal = self:GetValue()
                        tool:SendSettings()
                    end
                if not tool.Signal.ARSOnly then
                    local VLighT,VLighN = CollCat:TextEntry("Lights:")
                        VLighT:SetText(tool.Signal.Routes[i].Lights or "")
                        VLighT:SetTooltip("Numbers of lenses.\nFor example: for RGY:1-13-3-32-2 (R-RY-Y-YG-G)")
                        function VLighT:OnLoseFocus()
                            tool.Signal.Routes[i].Lights = self:GetValue()
                            tool:SendSettings()
                        end
                end
                if not tool.Signal.Routes[i].Repeater then
                    local VARST,VARSN = CollCat:TextEntry("ARSCodes:")
                        VARST:SetText(tool.Signal.Routes[i].ARSCodes or "")
                        VARST:SetTooltip("ARS Codes:0 - 0, 1 - No frequency, 2 - Absolute stop, 4 - 40, 6 - 60, 7 - 70, 8 - 80\nFor example: 004678(0-0-40-60-70-80)")
                        function VARST:OnLoseFocus()
                            tool.Signal.Routes[i].ARSCodes = self:GetValue()
                            tool:SendSettings()
                        end
                end
                local VSwiT,VSwiN = CollCat:TextEntry("Switches:")
                    VSwiT:SetText(tool.Signal.Routes[i].Switches or "")
                    VSwiT:SetTooltip("Switches. Next Switches + State. Can be empty(if no switches to next tool.Signal).\nFor example: 112+,114-,116+")
                    function VSwiT:OnLoseFocus()
                        tool.Signal.Routes[i].Switches = self:GetValue()
                        tool:SendSettings()
                    end
                local VEnRouC = CollCat:CheckBox("Enable route number")
                        VEnRouC:SetTooltip("Enable route number(when disabled route number enables only with invation signal)")
                        VEnRouC:SetValue(tool.Signal.Routes[i].EnRou or false)
                        function VEnRouC:OnChange()
                            tool.Signal.Routes[i].EnRou = self:GetChecked()
                            tool:SendSettings()
                            --tool:BuildCPanelCustom()
                        end
                local VRemoveR = CollCat:Button("Remove route")
                VRemoveR.DoClick = function()
                    table.remove(tool.Signal.Routes,i)
                    tool:SendSettings()
                    self:BuildCPanelCustom()
                end
            CPanel:AddItem(CollCat)
        end
        CPanel:AddItem(VAddPanel)
        local VTypeOfRoute = vgui.Create("DComboBox")
            --VType:SetValue("Choose tool.Type")
            VTypeOfRoute:ChooseOption(RouteTypes[tool.RouteType],tool.RouteType)
            VTypeOfRoute:SetColor(color_black)
            for i = 1,#RouteTypes do
                VTypeOfRoute:AddChoice(RouteTypes[i])
            end
            VTypeOfRoute.OnSelect = function(_, index, name)
                VTypeOfRoute:SetValue(name)
                tool.RouteType = index
            end
        CPanel:AddItem(VTypeOfRoute)
        local VAddR = CPanel:Button("Add route")
        VAddR.DoClick = function()
            if not tool.Signal.Routes then tool.Signal.Routes = {} end
            table.insert(tool.Signal.Routes,{Manual = tool.RouteType==2, Repeater = tool.RouteType == 3, Emer = tool.RouteType == 4, RouteName = ""})
            tool:SendSettings()
            self:BuildCPanelCustom()
        end
    elseif tool.Type == 2 then
        --local VNotF = vgui.Create("DLabel") VNotF:SetText("Not Finished yet!!")
        local VSType = vgui.Create("DComboBox")
            VSType:ChooseOption(TypesOfSign[tool.Sign.Type or 1],tool.Sign.Type or 1)
            VSType:SetColor(color_black)
            for i = 1,#TypesOfSign do
                VSType:AddChoice(TypesOfSign[i])
            end
            VSType.OnSelect = function(_, index, name)
                VSType:SetValue(name)
                tool.Sign.Type = index
                tool:SendSettings()
            end
        CPanel:AddItem(VSType)
        local VYOffT = CPanel:NumSlider("Y Offset:",nil,-100,100,0)
            VYOffT:SetValue(tool.Sign.YOffset or 0)
            VYOffT.OnValueChanged = function(num)
                tool.Sign.YOffset = VYOffT:GetValue()
                tool:SendSettings()
            end
        local VZOffT = CPanel:NumSlider("Z Offset:",nil,-50,50,0)
            VZOffT:SetValue(tool.Sign.ZOffset or 0)
            VZOffT.OnValueChanged = function(num)
                tool.Sign.ZOffset = VZOffT:GetValue()
                tool:SendSettings()
            end
        local VLeftOC = CPanel:CheckBox("Left side(if can be left-side)")
                VLeftOC:SetTooltip("Left side")
                VLeftOC:SetValue(tool.Sign.Left or false)
                function VLeftOC:OnChange()
                    tool.Sign.Left = self:GetChecked()
                    tool:SendSettings()
                end
    elseif tool.Type == 3 then
        --local VNotF = vgui.Create("DLabel") VNotF:SetText("Not Finished yet!!")
        local VAType = vgui.Create("DComboBox")
        CPanel:AddItem(VAType)
        VAType:SetColor(color_black)
        for i = 1,#TypesOfAuto do
            VAType:AddChoice(TypesOfAuto[i])
        end
        VAType:ChooseOptionID(tool.Auto.Type or 1)
        VAType.OnSelect = function(_, index, name)
            VAType:SetValue(name)
            tool.Auto.Type = index
            tool:SendSettings()
            tool:BuildCPanelCustom()
        end
        if tool.Auto.Type == METROSTROI_ACOIL_DOOR then
            local VRightOC = CPanel:CheckBox("Right doors")
            VRightOC:SetTooltip("Right doors")
            VRightOC:SetValue(tool.Auto.Right or false)
            function VRightOC:OnChange()
                tool.Auto.Right = self:GetChecked()
                tool:SendSettings()
            end
        end
        if tool.Auto.Type == METROSTROI_LSENSOR or tool.Auto.Type == METROSTROI_UPPSSENSOR or tool.Auto.Type == METROSTROI_SBPPSENSOR then
            local VLXpT = CPanel:NumSlider("X:",nil,0,200,2)
            VLXpT:SetValue(tool.Auto.LXp or 0)
            VLXpT.OnValueChanged = function(num)
                tool.Auto.LXp = VLXpT:GetValue()
                tool:SendSettings()
            end
        end
        if tool.Auto.Type ~= 5 then
            local VLYpT = CPanel:NumSlider("Y:",nil,-10,10,2)
            VLYpT:SetValue(tool.Auto.LYp or 0)
            VLYpT.OnValueChanged = function(num)
                tool.Auto.LYp = VLYpT:GetValue()
                tool:SendSettings()
            end
            local VLZpT = CPanel:NumSlider("Z:",nil,-10,10,2)
            VLZpT:SetValue(tool.Auto.LZp or 0)
            VLZpT.OnValueChanged = function(num)
                tool.Auto.LZp = VLZpT:GetValue()
                tool:SendSettings()
            end
        end
        if tool.Auto.Type == 5 then
            local VAPAType = vgui.Create("DComboBox")
            CPanel:AddItem(VAPAType)
            VAPAType:SetColor(color_black)
            VAPAType:AddChoice("OPV")
            VAPAType:ChooseOptionID(tool.Auto.PAType or 1)
            VAPAType.OnSelect = function(_, index, name)
                VAPAType:SetValue(name)
                tool.Auto.PAType = index
                tool:SendSettings()
                tool:BuildCPanelCustom()
            end
            if tool.Auto.PAType == 1 then
                local SPath = CPanel:TextEntry("Station path:")
                SPath:SetTooltip("Station path")
                SPath:SetValue(tool.Auto.PAStationPath or "")
                SPath:SetEnterAllowed(false)
                function SPath:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        if #NewValue > 0 then break end
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
                    end
                    self:SetText(NewValue)
                    self:SetCaretPos(0)
                end
                function SPath:OnLoseFocus()
                    tool.Auto.PAStationPath = self:GetValue()
                    tool:SendSettings()
                end
                local SID = CPanel:TextEntry("Station ID:")
                SID:SetTooltip("Station index")
                SID:SetValue(tool.Auto.PAStationID or "")
                SID:SetEnterAllowed(false)
                function SID:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
                    end
                    local oldpos = self:GetCaretPos()
                    self:SetText(NewValue)
                    self:SetCaretPos(math.min(#NewValue,oldpos))
                end
                function SID:OnLoseFocus()
                    tool.Auto.PAStationID = self:GetValue()
                    tool:SendSettings()
                end
                local SLast = CPanel:CheckBox("Last station")
                SLast:SetTooltip("Last station")
                SLast:SetValue(tool.Auto.PALastStation or false)
                function SLast:OnChange()
                    tool.Auto.PALastStation = self:GetChecked()
                    tool:SendSettings()
                    tool:BuildCPanelCustom()
                end
                if tool.Auto.PALastStation then
                    local SLWrongPath = CPanel:CheckBox("In wrong path")
                    SLWrongPath:SetValue(tool.Auto.PAWrongPath or false)
                    function SLWrongPath:OnChange()
                        tool.Auto.PAWrongPath = self:GetChecked()
                        tool:SendSettings()
                    end
                    local SLDStart = CPanel:NumSlider("Distance to\ndeadlock start:",nil,0,1024,0)
                    SLDStart:SetValue(tool.Auto.PADeadlockStart or 128)
                    SLDStart.OnValueChanged = function(num)
                        tool.Auto.PADeadlockStart = SLDStart:GetValue()
                        tool:SendSettings()
                    end
                    local SLDEnd = CPanel:NumSlider("Distance to\ndeadlock end:",nil,0,1024,0)
                    SLDEnd:SetValue(tool.Auto.PADeadlockEnd or 512)
                    SLDEnd.OnValueChanged = function(num)
                        tool.Auto.PADeadlockEnd = SLDEnd:GetValue()
                        tool:SendSettings()
                    end
                    local SLLChange = CPanel:CheckBox("Line change")
                    SLLChange:SetValue(tool.Auto.PALineChange or false)
                    function SLLChange:OnChange()
                        tool.Auto.PALineChange = self:GetChecked()
                        tool:SendSettings()
                        tool:BuildCPanelCustom()
                    end
                    if tool.Auto.PALineChange then
                        local SLLCLine = CPanel:TextEntry("Line change\nstation path:")
                        SLLCLine:SetValue(tool.Auto.PALineChangeStationPath or "")
                        SLLCLine:SetEnterAllowed(false)
                        function SLLCLine:OnChange()
                            local oldval = self:GetValue()
                            local NewValue = ""
                            for i = 1,#oldval do
                                if #NewValue > 0 then break end
                                NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
                            end
                            self:SetText(NewValue)
                            self:SetCaretPos(0)
                        end
                        function SLLCLine:OnLoseFocus()
                            tool.Auto.PALineChangeStationPath = self:GetValue()
                            tool:SendSettings()
                        end
                        local SLLCID = CPanel:TextEntry("Line change\nstation ID:")
                        SLLCID:SetTooltip("Station index")
                        SLLCID:SetValue(tool.Auto.PALineChangeStationID or "")
                        SLLCID:SetEnterAllowed(false)
                        function SLLCID:OnChange()
                            local oldval = self:GetValue()
                            local NewValue = ""
                            for i = 1,#oldval do
                                NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
                            end
                            local oldpos = self:GetCaretPos()
                            self:SetText(NewValue)
                            self:SetCaretPos(math.min(#NewValue,oldpos))
                        end
                        function SLLCID:OnLoseFocus()
                            tool.Auto.PALineChangeStationID = self:GetValue()
                            tool:SendSettings()
                        end
                    end
                end
                local SName = CPanel:TextEntry("Station name:")
                SName:SetTooltip("Station name")
                SName:SetValue(tool.Auto.PAStationName or "")
                SName:SetEnterAllowed(false)
                function SName:OnLoseFocus()
                    tool.Auto.PAStationName = self:GetValue()
                    tool:SendSettings()
                end
                if tool.Auto.PALastStation then
                    local SLName = CPanel:TextEntry("Last station name:")
                    SLName:SetTooltip("Last station name")
                    SLName:SetValue(tool.Auto.PALastStationName or "")
                    SLName:SetEnterAllowed(false)
                    function SLName:OnLoseFocus()
                        tool.Auto.PALastStationName = self:GetValue()
                        tool:SendSettings()
                    end
                end
                local SHorlift = CPanel:CheckBox("Has switches:")
                SHorlift:SetTooltip("Has switches")
                SHorlift:SetValue(tool.Auto.PAStationHasSwtiches or false)
                function SHorlift:OnChange()
                    tool.Auto.PAStationHasSwtiches = self:GetChecked()
                    tool:SendSettings()
                end
                local SRDoors = CPanel:CheckBox("Rights doors")
                SRDoors:SetTooltip("Rights doors")
                SRDoors:SetValue(tool.Auto.PAStationRightDoors or false)
                function SRDoors:OnChange()
                    tool.Auto.PAStationRightDoors = self:GetChecked()
                    tool:SendSettings()
                end
                local SHorlift = CPanel:CheckBox("Horlift")
                SHorlift:SetTooltip("Horlift")
                SHorlift:SetValue(tool.Auto.PAStationHorlift or false)
                function SHorlift:OnChange()
                    tool.Auto.PAStationHorlift = self:GetChecked()
                    tool:SendSettings()
                end
            end
        end
        if tool.Auto.Type == METROSTROI_SBPPSENSOR then
            local VASBPPType = vgui.Create("DComboBox")
            CPanel:AddItem(VASBPPType)
            VASBPPType:SetColor(color_black)
            VASBPPType:AddChoice("ST1")
            VASBPPType:AddChoice("ST2")
            VASBPPType:AddChoice("OPV")
            VASBPPType:AddChoice("OD")
            VASBPPType:AddChoice("X2")
            VASBPPType:AddChoice("X3")
            VASBPPType:AddChoice("TP")
            VASBPPType:ChooseOptionID(tool.Auto.SBPPType or 1)
            VASBPPType.OnSelect = function(_, index, name)
                VASBPPType:SetValue(name)
                tool.Auto.SBPPType = index
                tool:SendSettings()
                tool:BuildCPanelCustom()
            end
            local SBPPType = tool.Auto.SBPPType or 1
            if SBPPType <= 3 then
                local SDeadlock = CPanel:CheckBox("Deadlock")
                SDeadlock:SetTooltip("Deadlock")
                SDeadlock:SetValue(tool.Auto.SBPPDeadlock or false)
                function SDeadlock:OnChange()
                    tool.Auto.SBPPDeadlock = self:GetChecked()
                    tool:SendSettings()
                    tool:BuildCPanelCustom()
                end
            end
            if SBPPType == 1 then
                local SRPos = CPanel:CheckBox("Rights pos")
                SRPos:SetTooltip("Rights pos")
                SRPos:SetValue(tool.Auto.LRightP or false)
                function SRPos:OnChange()
                    tool.Auto.LRightP = self:GetChecked()
                    tool:SendSettings()
                end
                local SRInvX = CPanel:CheckBox("Invert X")
                SRInvX:SetTooltip("Invert X")
                SRInvX:SetValue(tool.Auto.LInvX or false)
                function SRInvX:OnChange()
                    tool.Auto.LInvX = self:GetChecked()
                    tool:SendSettings()
                end
            end
            if 2<= SBPPType and SBPPType <= 3 and not tool.Auto.SBPPDeadlock then
                local SPath = CPanel:TextEntry("Station path:")
                SPath:SetTooltip("Station path")
                SPath:SetValue(tool.Auto.SBPPStationPath or "")
                SPath:SetEnterAllowed(false)
                function SPath:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        if #NewValue > 0 then break end
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
                    end
                    self:SetText(NewValue)
                    self:SetCaretPos(0)
                end
                function SPath:OnLoseFocus()
                    tool.Auto.SBPPStationPath = self:GetValue()
                    tool:SendSettings()
                end
                local SID = CPanel:TextEntry("Station ID:")
                SID:SetTooltip("Station index")
                SID:SetValue(tool.Auto.SBPPStationID or "")
                SID:SetEnterAllowed(false)
                function SID:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
                    end
                    local oldpos = self:GetCaretPos()
                    self:SetText(NewValue)
                    self:SetCaretPos(math.min(#NewValue,oldpos))
                end
                function SID:OnLoseFocus()
                    tool.Auto.SBPPStationID = self:GetValue()
                    tool:SendSettings()
                end
            end
            if SBPPType == 3 then
                local SRDoors = CPanel:CheckBox("Rights doors")
                SRDoors:SetTooltip("Rights doors")
                SRDoors:SetValue(tool.Auto.SBPPRightDoors or false)
                function SRDoors:OnChange()
                    tool.Auto.SBPPRightDoors = self:GetChecked()
                    tool:SendSettings()
                end
                local SDriveMode = vgui.Create("DComboBox")
                CPanel:AddItem(SDriveMode)
                SDriveMode:SetColor(color_black)
                SDriveMode:AddChoice("None")
                SDriveMode:AddChoice("X2")
                SDriveMode:AddChoice("X3")
                SDriveMode:ChooseOptionID(tool.Auto.SBPPDriveMode or 1)
                SDriveMode.OnSelect = function(_, index, name)
                    SDriveMode:SetValue(name)
                    tool.Auto.SBPPDriveMode = index
                    tool:SendSettings()
                end
            end
            if SBPPType==7  then
                local SRK = CPanel:NumSlider("RK Pos:",nil,1,18,0)
                SRK:SetValue(tool.Auto.SBPPRK or 0)
                SRK.OnValueChanged = function(num)
                    tool.Auto.SBPPRK = SRK:GetValue()
                    tool:SendSettings()
                end
            end
            if SBPPType == 3 or SBPPType>=5 then
                local STime = CPanel:NumSlider("Work time:",nil,0,120,2)
                STime:SetValue(tool.Auto.SBPPWTime or 0)
                STime.OnValueChanged = function(num)
                    tool.Auto.SBPPWTime = STime:GetValue()
                    tool:SendSettings()
                end
            end
            --[[    local SPath = CPanel:TextEntry("Station path:")
                SPath:SetTooltip("Station path")
                SPath:SetValue(tool.Auto.PAStationPath or "")
                SPath:SetEnterAllowed(false)
                function SPath:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        if #NewValue > 0 then break end
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
                    end
                    self:SetText(NewValue)
                    self:SetCaretPos(0)
                end
                function SPath:OnLoseFocus()
                    tool.Auto.PAStationPath = self:GetValue()
                    tool:SendSettings()
                end
                local SID = CPanel:TextEntry("Station ID:")
                SID:SetTooltip("Station index")
                SID:SetValue(tool.Auto.PAStationID or "")
                SID:SetEnterAllowed(false)
                function SID:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
                    end
                    local oldpos = self:GetCaretPos()
                    self:SetText(NewValue)
                    self:SetCaretPos(math.min(#NewValue,oldpos))
                end
                function SID:OnLoseFocus()
                    tool.Auto.PAStationID = self:GetValue()
                    tool:SendSettings()
                end
                local SLast = CPanel:CheckBox("Last station")
                SLast:SetTooltip("Last station")
                SLast:SetValue(tool.Auto.PALastStation or false)
                function SLast:OnChange()
                    tool.Auto.PALastStation = self:GetChecked()
                    tool:SendSettings()
                    tool:BuildCPanelCustom()
                end
                if tool.Auto.PALastStation then
                    local SLWrongPath = CPanel:CheckBox("In wrong path")
                    SLWrongPath:SetValue(tool.Auto.PAWrongPath or false)
                    function SLWrongPath:OnChange()
                        tool.Auto.PAWrongPath = self:GetChecked()
                        tool:SendSettings()
                    end
                    local SLDStart = CPanel:NumSlider("Distance to\ndeadlock start:",nil,0,1024,0)
                    SLDStart:SetValue(tool.Auto.PADeadlockStart or 128)
                    SLDStart.OnValueChanged = function(num)
                        tool.Auto.PADeadlockStart = SLDStart:GetValue()
                        tool:SendSettings()
                    end
                    local SLDEnd = CPanel:NumSlider("Distance to\ndeadlock end:",nil,0,1024,0)
                    SLDEnd:SetValue(tool.Auto.PADeadlockEnd or 512)
                    SLDEnd.OnValueChanged = function(num)
                        tool.Auto.PADeadlockEnd = SLDEnd:GetValue()
                        tool:SendSettings()
                    end
                    local SLLChange = CPanel:CheckBox("Line change")
                    SLLChange:SetValue(tool.Auto.PALineChange or false)
                    function SLLChange:OnChange()
                        tool.Auto.PALineChange = self:GetChecked()
                        tool:SendSettings()
                        tool:BuildCPanelCustom()
                    end
                    if tool.Auto.PALineChange then
                        local SLLCLine = CPanel:TextEntry("Line change\nstation path:")
                        SLLCLine:SetValue(tool.Auto.PALineChangeStationPath or "")
                        SLLCLine:SetEnterAllowed(false)
                        function SLLCLine:OnChange()
                            local oldval = self:GetValue()
                            local NewValue = ""
                            for i = 1,#oldval do
                                if #NewValue > 0 then break end
                                NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
                            end
                            self:SetText(NewValue)
                            self:SetCaretPos(0)
                        end
                        function SLLCLine:OnLoseFocus()
                            tool.Auto.PALineChangeStationPath = self:GetValue()
                            tool:SendSettings()
                        end
                        local SLLCID = CPanel:TextEntry("Line change\nstation ID:")
                        SLLCID:SetTooltip("Station index")
                        SLLCID:SetValue(tool.Auto.PALineChangeStationID or "")
                        SLLCID:SetEnterAllowed(false)
                        function SLLCID:OnChange()
                            local oldval = self:GetValue()
                            local NewValue = ""
                            for i = 1,#oldval do
                                NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
                            end
                            local oldpos = self:GetCaretPos()
                            self:SetText(NewValue)
                            self:SetCaretPos(math.min(#NewValue,oldpos))
                        end
                        function SLLCID:OnLoseFocus()
                            tool.Auto.PALineChangeStationID = self:GetValue()
                            tool:SendSettings()
                        end
                    end
                end
                local SName = CPanel:TextEntry("Station name:")
                SName:SetTooltip("Station name")
                SName:SetValue(tool.Auto.PAStationName or "")
                SName:SetEnterAllowed(false)
                function SName:OnLoseFocus()
                    tool.Auto.PAStationName = self:GetValue()
                    tool:SendSettings()
                end
                if tool.Auto.PALastStation then
                    local SLName = CPanel:TextEntry("Last station name:")
                    SLName:SetTooltip("Last station name")
                    SLName:SetValue(tool.Auto.PALastStationName or "")
                    SLName:SetEnterAllowed(false)
                    function SLName:OnLoseFocus()
                        tool.Auto.PALastStationName = self:GetValue()
                        tool:SendSettings()
                    end
                end
                local SHorlift = CPanel:CheckBox("Has switches:")
                SHorlift:SetTooltip("Has switches")
                SHorlift:SetValue(tool.Auto.PAStationHasSwtiches or false)
                function SHorlift:OnChange()
                    tool.Auto.PAStationHasSwtiches = self:GetChecked()
                    tool:SendSettings()
                end
                local SRDoors = CPanel:CheckBox("Rights doors")
                SRDoors:SetTooltip("Rights doors")
                SRDoors:SetValue(tool.Auto.PAStationRightDoors or false)
                function SRDoors:OnChange()
                    tool.Auto.PAStationRightDoors = self:GetChecked()
                    tool:SendSettings()
                end
                local SHorlift = CPanel:CheckBox("Horlift")
                SHorlift:SetTooltip("Horlift")
                SHorlift:SetValue(tool.Auto.PAStationHorlift or false)
                function SHorlift:OnChange()
                    tool.Auto.PAStationHorlift = self:GetChecked()
                    tool:SendSettings()
                end
            end--]]
        end
        if  tool.Auto.Type == METROSTROI_ACOIL_DRIVE then
            local VRightOC = CPanel:CheckBox("Right")
            VRightOC:SetTooltip("Right")
            VRightOC:SetValue(tool.Auto.Right or false)
            function VRightOC:OnChange()
                tool.Auto.Right = self:GetChecked()
                tool:SendSettings()
            end
            local VADist = vgui.Create("DComboBox")
            CPanel:AddItem(VADist)
            VADist:SetColor(color_black)
            VADist:AddChoice("5 m")
            VADist:AddChoice("20 m")
            VADist:AddChoice("50 m")
            VADist:ChooseOptionID(tool.Auto.Dist or 1)
            VADist.OnSelect = function(_, index, name)
                VADist:SetValue(name)
                tool.Auto.Dist = index
                tool:SendSettings()
            end
            local VAMode = vgui.Create("DComboBox")
            CPanel:AddItem(VAMode)
            VAMode:SetColor(color_black)
            VAMode:AddChoice("X-2")
            VAMode:AddChoice("X-3")
            VAMode:AddChoice("X-2 Station")
            VAMode:AddChoice("X-3 Station")
            VAMode:AddChoice("0")
            VAMode:AddChoice("0 Regulated")
            VAMode:AddChoice("T")
            --VAMode:AddChoice("T-1a")
            VAMode:ChooseOptionID(tool.Auto.Mode or 1)
            VAMode.OnSelect = function(_, index, name)
                VAMode:SetValue(name)
                tool.Auto.Mode = index
                tool:SendSettings()
                tool:BuildCPanelCustom()
            end
            if tool.Auto.Mode == 3 or tool.Auto.Mode == 4 then
                local SID,VSIDN = CPanel:TextEntry("Station ID:")
                SID:SetTooltip("Station index")
                SID:SetValue(tool.Auto.StationID or "")
                SID:SetEnterAllowed(false)
                function SID:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]+") or "")
                    end
                    local oldpos = self:GetCaretPos()
                    self:SetText(NewValue)
                    self:SetCaretPos(math.min(#NewValue,oldpos))
                end
                function SID:OnLoseFocus()
                    tool.Auto.StationID = self:GetValue()
                    tool:SendSettings()
                end
                local SPath,VSPathN = CPanel:TextEntry("Station path:")
                SPath:SetTooltip("Station path")
                SPath:SetValue(tool.Auto.StationPath or "")
                SPath:SetEnterAllowed(false)
                function SPath:OnChange()
                    local oldval = self:GetValue()
                    local NewValue = ""
                    for i = 1,#oldval do
                        if #NewValue > 0 then break end
                        NewValue = NewValue..((oldval[i] or ""):upper():match("[%d]") or "")
                    end
                    self:SetText(NewValue)
                    self:SetCaretPos(0)
                end
                function SPath:OnLoseFocus()
                    tool.Auto.StationPath = self:GetValue()
                    tool:SendSettings()
                end
            end
        end
        if tool.Auto.Type == METROSTROI_UPPSSENSOR then
            local VRollT = CPanel:NumSlider("Roll:",nil,-180,180,0)
            VRollT:SetValue(tool.Auto.Roll or 0)
            VRollT.OnValueChanged = function(num)
                tool.Auto.Roll = VRollT:GetValue()
                tool:SendSettings()
            end
        end
    end
end

TOOL.NotBuilt = true
function TOOL:Think()
    if CLIENT and (self.NotBuilt or NeedUpdate) then
        self.Signal = self.Signal or util.JSONToTable(string.Replace(GetConVarString("signalling_signaldata"),"'","\"")) or {}
        self.Sign = self.Sign or util.JSONToTable(string.Replace(GetConVarString("signalling_signdata"),"'","\"")) or {}
        self.Auto = self.Auto or util.JSONToTable(string.Replace(GetConVarString("signalling_autodata"),"'","\"")) or {}
        self:SendSettings()
        self:BuildCPanelCustom()
        self.NotBuilt = nil
        NeedUpdate = nil
    end
end
function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Text = "#Tool.signalling.name", Description = "#Tool.signalling.desc" })
    if not self then return end
    self:BuildCPanelCustom()
end
