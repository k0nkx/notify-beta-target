local NotificationLib = {}
NotificationLib.__index = NotificationLib

local currentInstance = nil

function NotificationLib.new()
    if currentInstance then
        currentInstance:Destroy()
    end
    
    local self = setmetatable({}, NotificationLib)
    currentInstance = self
    
    self.container = Instance.new("ScreenGui")
    self.container.Name = "NotificationContainer_" .. tostring(math.random(1, 1000000))
    self.container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.container.Parent = game:GetService("CoreGui") or (gethui and gethui()) or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    self.activeNotifications = {}
    self.ready = false
    self.queuedNotifications = {}
    
    task.spawn(function()
        local player = game:GetService("Players").LocalPlayer
        while not player.Character do
            player.CharacterAdded:Wait()
            task.wait(1)
        end
        
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end
        
        task.wait(1)
        
        self.ready = true
        
        for _, notificationData in ipairs(self.queuedNotifications) do
            self:CreateNotification(notificationData.text, notificationData.duration, notificationData.color)
        end
        self.queuedNotifications = {}
    end)
    
    return self
end

function NotificationLib:UpdatePositions()
    for i, notification in ipairs(self.activeNotifications) do
        if notification and notification.outerFrame and notification.outerFrame.Parent then
            local targetY = 50 + ((i - 1) * 30)
            game:GetService("TweenService"):Create(
                notification.outerFrame,
                TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0.5, 0, 0, targetY)}
            ):Play()
        end
    end
end

function NotificationLib:TypeWriter(textLabel, fullText, speed)
    local typedText = ""
    local cursorVisible = true
    local cursorTask = nil
    
    local function ToggleCursor()
        while true do
            textLabel.Text = typedText .. (cursorVisible and "|" or "")
            cursorVisible = not cursorVisible
            task.wait(0.5)
        end
    end
    
    cursorTask = task.spawn(ToggleCursor)
    
    for i = 1, #fullText do
        typedText = string.sub(fullText, 1, i)
        if cursorTask then
            textLabel.Text = typedText .. "|"
        end
        task.wait(speed)
    end
    
    if cursorTask then
        task.cancel(cursorTask)
        textLabel.Text = fullText
    end
end

function NotificationLib:CreateNotification(text, duration, color)
    if not self.ready then
        table.insert(self.queuedNotifications, {
            text = text,
            duration = duration,
            color = color
        })
        return
    end

    local textService = game:GetService("TextService")
    local textWidth = textService:GetTextSize(text, 12, Enum.Font.Ubuntu, Vector2.new(10000, 10000)).X
    local minWidth = math.max(textWidth + 24, 150)

    local outerFrame = Instance.new("Frame")
    outerFrame.Name = "OuterFrame"
    outerFrame.AnchorPoint = Vector2.new(0.5, 0)
    outerFrame.Position = UDim2.new(0.5, 0, 1, 0)
    outerFrame.Size = UDim2.new(0, minWidth + 4, 0, 25)
    outerFrame.BackgroundTransparency = 0
    outerFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    outerFrame.BorderSizePixel = 1
    outerFrame.BorderColor3 = Color3.fromRGB(40, 40, 40)
    outerFrame.ClipsDescendants = true
    outerFrame.Parent = self.container

    local holder = Instance.new("Frame")
    holder.Name = "Holder"
    holder.Position = UDim2.new(0, 1, 0, 1)
    holder.Size = UDim2.new(1, -2, 1, -2)
    holder.BackgroundTransparency = 0
    holder.BackgroundColor3 = Color3.fromRGB(37, 37, 37)
    holder.BorderSizePixel = 0
    holder.ClipsDescendants = true
    holder.Parent = outerFrame

    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, -4, 1, -4)
    background.Position = UDim2.new(0, 2, 0, 2)
    background.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    background.BorderSizePixel = 0
    background.Parent = holder

    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Size = UDim2.new(0, 2, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.Parent = background

    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.Size = UDim2.new(1, 0, 0, 1)
    progressBar.Position = UDim2.new(0, 0, 1, -1)
    progressBar.BackgroundColor3 = color
    progressBar.BorderSizePixel = 0
    progressBar.Parent = background

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "TextLabel"
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.Ubuntu
    textLabel.Text = ""
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextSize = 12
    textLabel.BackgroundTransparency = 1
    textLabel.TextTransparency = 0
    textLabel.Parent = background

    local hoverConn = outerFrame.MouseEnter:Connect(function()
        for _, element in pairs({outerFrame, holder, background, accentBar, progressBar, textLabel}) do
            game:GetService("TweenService"):Create(
                element,
                TweenInfo.new(0.2),
                {
                    BackgroundTransparency = element:IsA("TextLabel") and 0.8 or 0.8,
                    TextTransparency = element:IsA("TextLabel") and 0.2 or nil
                }
            ):Play()
        end
    end)

    outerFrame.MouseLeave:Connect(function()
        for _, element in pairs({outerFrame, holder, background, accentBar, progressBar, textLabel}) do
            game:GetService("TweenService"):Create(
                element,
                TweenInfo.new(0.2),
                {
                    BackgroundTransparency = element:IsA("TextLabel") and 1 or 0,
                    TextTransparency = element:IsA("TextLabel") and 0 or nil
                }
            ):Play()
        end
    end)

    local notification = {
        outerFrame = outerFrame,
        holder = holder,
        background = background,
        accentBar = accentBar,
        progressBar = progressBar,
        textLabel = textLabel,
        remove = nil,
        connections = {hoverConn}
    }
    table.insert(self.activeNotifications, notification)

    self:UpdatePositions()

    local typingSpeed = 0.05
    task.spawn(function()
        self:TypeWriter(textLabel, text, typingSpeed)
    end)

    local typingDuration = #text * typingSpeed

    task.delay(typingDuration, function()
        game:GetService("TweenService"):Create(
            progressBar,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {Size = UDim2.new(0, 0, 0, 1)}
        ):Play()
    end)

    local function Remove()
        for i, notif in ipairs(self.activeNotifications) do
            if notif == notification then
                table.remove(self.activeNotifications, i)
                break
            end
        end

        if notification.connections then
            for _, conn in ipairs(notification.connections) do
                if conn then
                    conn:Disconnect()
                end
            end
        end

        local fadeOutGroup = {}

        table.insert(fadeOutGroup, game:GetService("TweenService"):Create(
            outerFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
            {
                Position = UDim2.new(0, -outerFrame.AbsoluteSize.X, outerFrame.Position.Y.Scale, outerFrame.Position.Y.Offset),
                Size = UDim2.new(0, 0, 0, outerFrame.AbsoluteSize.Y),
                BackgroundTransparency = 1,
                BorderSizePixel = 0
            }
        ))

        for _, element in pairs({holder, background, accentBar, progressBar, textLabel}) do
            table.insert(fadeOutGroup, game:GetService("TweenService"):Create(
                element,
                TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
                element:IsA("TextLabel") and {TextTransparency = 1} or {BackgroundTransparency = 1}
            ))
        end

        for _, tween in ipairs(fadeOutGroup) do
            tween:Play()
        end

        task.delay(0.5, function()
            outerFrame:Destroy()
            self:UpdatePositions()
        end)
    end

    notification.remove = Remove

    task.delay(typingDuration + duration, Remove)
    
    return notification
end

function NotificationLib:Notify(text, duration, color)
    task.spawn(function()
        self:CreateNotification(text, duration or 5, color or Color3.fromRGB(255, 255, 255))
    end)
end

function NotificationLib:WelcomePlayer()
    if not self.ready then
        task.spawn(function()
            while not self.ready do
                task.wait()
            end
            local playerName = game:GetService("Players").LocalPlayer.Name
            local displayName = game:GetService("Players").LocalPlayer.DisplayName
            local welcomeName = displayName ~= playerName and displayName or playerName
            self:Notify("Welcome, "..welcomeName.."!", 5, Color3.fromRGB(255, 215, 0))
        end)
        return
    end
    
    local playerName = game:GetService("Players").LocalPlayer.Name
    local displayName = game:GetService("Players").LocalPlayer.DisplayName
    local welcomeName = displayName ~= playerName and displayName or playerName
    self:Notify("Welcome, "..welcomeName.."!", 5, Color3.fromRGB(255, 215, 0))
end

function NotificationLib:Destroy()
    if currentInstance == self then
        currentInstance = nil
    end
    
    for _, notification in ipairs(self.activeNotifications) do
        if notification.remove then
            notification.remove()
        end
    end
    
    if self.container then
        self.container:Destroy()
    end
    
    self.activeNotifications = nil
    self.container = nil
    self.queuedNotifications = nil
end

return NotificationLib
