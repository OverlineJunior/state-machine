type Event = {[string]: string | () -> string?}
type FlowMap = {[string]: Event}
type LockLayers = {[string]: number}


local function FreshLockLayers(flowMap: FlowMap): LockLayers
    local lockLayers = {}

    for eventName in flowMap do
        lockLayers[eventName] = 0
    end

    return lockLayers
end


local StateMachine = {}
StateMachine.__index = StateMachine


function StateMachine.new(flowMap: FlowMap, initialState: string, _lockLayers: LockLayers?)
    local self = setmetatable({}, StateMachine)
    self._FlowMap = flowMap
    self._State = initialState
    self._LockLayers = _lockLayers or FreshLockLayers(flowMap)

    return table.freeze(self)
end


function StateMachine:transition(eventName: string)
    local event: Event = self._FlowMap[eventName]
    local newState = assert(
        event[self._State],
        ('The %q event cannot be triggered when on the %q state'):format(eventName, self._State)
    )

    assert(not self:IsLocked(eventName), ('The %q event is locked'):format(eventName))

    return StateMachine.new(self._FlowMap, newState)
end


function StateMachine:lock(eventName: string)
    local newLockLayers = table.clone(self._LockLayers)
    newLockLayers[eventName] += 1

    return StateMachine.new(self._FlowMap, self._State, newLockLayers)
end


function StateMachine:unlock(eventName: string)
    if self._LockLayers[eventName] == 0 then return end

    local newLockLayers = table.clone(self._LockLayers)
    newLockLayers[eventName] -= 1

    return StateMachine.new(self._FlowMap, self._State, newLockLayers)
end


function StateMachine:IsLocked(eventName: string): boolean
    return self._LockLayers[eventName] ~= 0
end


function StateMachine:Can(eventName: string): boolean
    local event: Event = self._FlowMap[eventName]

    return event[self._State] ~= nil
end


return function(flowMap: FlowMap)
    return function(initialState: string)
        return StateMachine.new(flowMap, initialState)
    end
end
