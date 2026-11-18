local clock = 0
local jobs = {}
local function enqueue(co, due, ...)
    table.insert(jobs, {co = co, due = due, args = table.pack(...)})
end
local os = {clock = function() return clock end, time = function() return 0 end}
local task = {
    wait = function(seconds) return coroutine.yield(seconds or 0.01) end,
    spawn = function(fn, ...) enqueue(coroutine.create(fn), clock, ...) end,
    delay = function(seconds, fn) enqueue(coroutine.create(fn), clock + seconds) end,
}
local function advance(to)
    while true do
        local earliest
        for i, job in ipairs(jobs) do
            if job.due <= to and (not earliest or job.due < jobs[earliest].due) then earliest = i end
        end
        if not earliest then break end
        local job = table.remove(jobs, earliest)
        clock = job.due
        local ok, wait = coroutine.resume(job.co, table.unpack(job.args, 1, job.args.n))
        assert(ok, tostring(wait))
        if coroutine.status(job.co) ~= "dead" then enqueue(job.co, clock + wait) end
    end
    clock = to
end
local function stallFrames(seconds)
    local deadline = clock + seconds
    for _, job in ipairs(jobs) do
        if job.due < deadline then job.due = deadline end
    end
    advance(deadline)
end
local keyEvents = {}
local rejectInput = false
local Enum = {KeyCode = setmetatable({}, {__index = function(_, key) return key end})}
local encodedDocuments, encodedCount = {}, 0
local workspaceFiles = {}
local failFileWrites = false
local function cloneDocument(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = cloneDocument(item) end
    return copy
end
local function isfile(path) return workspaceFiles[path] ~= nil end
local function writefile(path, contents)
    assert(not failFileWrites, "test write failure")
    workspaceFiles[path] = contents
end
local focusedTextBox, onInputBegan
local function pressHotkey(key, gameProcessed)
    return onInputBegan({KeyCode = key}, gameProcessed == true)
end
local game = {
    GameId = 321,
    PlaceId = 987,
    GetService = function(_, service)
        if service == "UserInputService" then
            return {
                GetFocusedTextBox = function() return focusedTextBox end,
                InputBegan = {Connect = function(_, callback) onInputBegan = callback end},
            }
        end
        if service == "VirtualInputManager" then
            return {SendKeyEvent = function(_, down, key)
                if rejectInput then error("Virtual input unavailable") end
                table.insert(keyEvents, {down, key, clock})
            end}
        end
        return {
            JSONEncode = function(_, document)
                encodedCount += 1
                local key = "document:" .. tostring(encodedCount)
                encodedDocuments[key] = cloneDocument(document)
                return key
            end,
            JSONDecode = function(_, body)
                if body == "nano catalog" then
                    return {{name = "Test Song", artists = {"An Artist"}, midiFilename = "test file.mid"}}
                end
                assert(encodedDocuments[body], "bad JSON fixture")
                return cloneDocument(encodedDocuments[body])
            end,
        }
    end,
    HttpGet = function(_, url)
        assert(url == 'https://sirius.menu/rayfield', 'Unexpected HTTP fallback')
        return ''
    end,
}
local tabs, notifications = {}, {}
local function element(tab, config)
    tab.controls[config.Name] = config
    config.Refresh = function(self, options) self.Options = options end
    config.Set = function(self, value)
        if self.Options then self.CurrentOption = value else self.CurrentValue = value end
        self.Callback(value)
    end
    return config
end
local localMockRayfield = {
    CreateWindow = function()
        return {CreateTab = function(_, name)
            local tab = {controls = {}, labels = {}}
            tabs[name] = tab
            tab.CreateSection = function() end
            tab.CreateLabel = function(self, label)
                local entry = {Value = label, Set = function(self, value) self.Value = value end}
                self.labels[label] = entry
                return entry
            end
            tab.CreateButton, tab.CreateInput, tab.CreateSlider = element, element, element
            tab.CreateDropdown, tab.CreateToggle = element, element
            return tab
        end}
    end,
    Notify = function(_, options) table.insert(notifications, options) end,
}
local function loadstring(_) return function() return localMockRayfield end end
local function warn(...) end
local fixtures = {['https://api.nanomidi.net/api/midiData'] = {body = "nano catalog"}}
local requests = {}
local localMidiData
local function listfiles() return {"fixture.mid"} end
local function readfile(path)
    if path == "fixture.mid" then return localMidiData end
    assert(workspaceFiles[path] ~= nil, "file not found")
    return workspaceFiles[path]
end
local function request(options)
    requests[options.Url] = (requests[options.Url] or 0) + 1
    local fixture = fixtures[options.Url]
    if not fixture then return {StatusCode = 404} end
    if fixture.delay then task.wait(fixture.delay) end
    return {StatusCode = 200, Body = fixture.body}
end
