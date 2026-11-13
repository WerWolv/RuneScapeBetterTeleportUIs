local HotkeyBadge = require("impl/ui/hotkey_badge")

local Model3D = {}
Model3D.__index = Model3D

local function create(parent, modelType, modelIDs, animID, options)
    local layer = prettyui.NewComponent(ui.Layer, parent, { categoryID = "auto" })
    layer.clickthrough = true
    local self = setmetatable({ layer = layer, models = {}, options = options }, Model3D)

    local group = prettyui.NewComponent(ui.ModelGroup, layer)
    group:SetSize(0, 0, 1, 1)
    group.clickthrough = true
    self.group = group

    local cameraOptions = options.camera
    assert(cameraOptions.distance > 0, "Model3D camera distance must be positive")
    assert(cameraOptions.pitch > -90 and cameraOptions.pitch < 90, "Model3D camera pitch must be between -90 and 90 degrees")
    local yaw, pitch = math.rad(cameraOptions.yaw), math.rad(cameraOptions.pitch)
    local target = cameraOptions.target
    local horizontal = cameraOptions.distance * math.cos(pitch)
    local position = Vector3.new(
        target.x + horizontal * math.sin(yaw),
        target.y + cameraOptions.distance * math.sin(pitch),
        target.z + horizontal * math.cos(yaw)
    )

    local camera = ui.ModelCameraInfo.new()
    camera.clearColour = Vector4.new(0, 0, 0, 0)
    camera.useLookAt = true
    camera.sortModelsUsingComponentOrder = false
    camera:SetPosition(position, 0)
    camera:SetLookAt(Vector3.new(target.x, target.y, target.z), 0)
    camera:SetYawPitchRoll(Vector3.new(0, 0, 0), 0)
    camera:SetFOV(cameraOptions.fov, 0)
    camera:SetClipPlanes(cameraOptions.nearPlane, cameraOptions.farPlane)
    local cameraID = group:AddCamera(camera)
    group:SwitchCamera(cameraID, ui.ModelCameraTransition.NONE, -1, 0)

    for _, modelID in ipairs(modelIDs) do
        local model = prettyui.NewComponent(ui.Model, group)
        model:SetSize(0, 0, 1, 1)
        model.clickthrough = true
        model:SetModel(modelType, modelID)
        model:SetTransform(Vector3.new(0, 0, 0), Vector3.new(0, 0, 0), Vector3.new(1, 1, 1), 0)
        model.animID = animID
        self.models[#self.models + 1] = model
    end

    if options.hotkey ~= nil then
        self.hotkey = HotkeyBadge.New(layer, options.hotkey)
    end

    return self
end

function Model3D.FromLoc(parent, loc, options)
    local modelIDs = loc:GetModelIDs(LocShapeType.CENTREPIECE_STRAIGHT)
    assert(#modelIDs > 0, "Model3D requires centrepiece models: " .. loc.configName)
    local animation = assert(loc.defaultAnimation, "Model3D requires an animation: " .. loc.configName)

    return create(parent, ui.ModelType.MODEL, modelIDs, animation.id, options)
end

function Model3D.FromNPC(parent, npcID, animID, options)
    return create(parent, ui.ModelType.NPC_MODEL, { npcID }, animID, options)
end

function Model3D:SetSize(width, height)
    self.layer:SetSize(width, height)
    -- ModelGroup children can retain zero dimensions with parent-relative sizing.
    self.group:SetSize(width, height)
    for _, model in ipairs(self.models) do
        model:SetSize(width, height)
    end
end

function Model3D:Layout(layout)
    local options = self.options
    local scale = math.min(1, layout.width / 500, layout.height / 400)
    local width = math.max(1, math.floor(options.width * scale))
    local height = math.max(1, math.floor(options.height * scale))
    self.layer:SetPos(
        math.floor(options.left * scale),
        layout.height - height - math.floor(options.bottom * scale)
    )
    self:SetSize(width, height)

    self.layer:MoveToFront()

    local origin = self.layer.xyGlobal
    return origin.x, origin.y, width, height
end

function Model3D:Update(disabled, hovered)
    if self.hotkey ~= nil then
        self.hotkey:Update(self.layer, { disabled = disabled, inset = 4 })
    end
end

return Model3D
