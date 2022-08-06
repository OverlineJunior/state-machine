local Option = require(script.Parent.Option)

type Event = {[string]: string | () -> string?}
type FlowMap = {[string]: Event}
type LockLayers = {[string]: number}


local function Assert(eval, genMsg: () -> string, level: number?)
    if eval then
        error(genMsg(), level)
    end

    return eval
end


local function FreshLockLayers(flowMap: FlowMap): LockLayers
    local lockLayers = {}

    for eventName in flowMap do
        lockLayers[eventName] = 0
    end

    return lockLayers
end


--[=[
    @class StateMachine

    An immutable class for handling the state of things, where the design is a copy of Rust's sm crate, but with a few additions and changes.

    ```lua
    local Lock = StateMachine {
        TurnKey = {
            Locked = 'Unlocked',
            Unlocked = 'Locked',
        },

        Break = {
            Locked = 'Broken',
            Unlocked = 'Broken',
        },
    }

    -- Calling the Lock state machine template constructs the actual state machine explained here.
    local lock = Lock('Locked')
    lock = lock:transition('TurnKey')

    assert(lock:State(), 'Unlocked')
    assert(lock:Trigger():Unwrap(), 'TurnKey')
    ```
]=]
local StateMachine = {}
StateMachine.__index = StateMachine


function StateMachine.new(flowMap: FlowMap, initialState: string, _trigger: string?, _lockLayers: LockLayers?)
    local self = setmetatable({}, StateMachine)
    self._FlowMap = flowMap
    self._State = initialState
    self._Trigger = _trigger
    self._LockLayers = _lockLayers or FreshLockLayers(flowMap)

    return table.freeze(self)
end

--[=[
    @method transition
    @param eventName string
    @return StateMachine
    @within StateMachine

    Returns a new StateMachine with the post-transition state.
]=]
function StateMachine:transition(eventName: string)
    local event: Event = self._FlowMap[eventName]
    local newState = Assert(event[self._State], function()
        return ('The %q event cannot be triggered when on the %q state'):format(eventName, self._State)
    end, 3)

    Assert(not self:IsLocked(eventName), function()
        return ('The %q event is locked'):format(eventName)
    end, 3)

    return if newState == self._State then
        self
    else
        StateMachine.new(self._FlowMap, newState, eventName, self._LockLayers)
end


function StateMachine:lock(eventName: string)
    local newLockLayers = table.clone(self._LockLayers)
    newLockLayers[eventName] += 1

    return StateMachine.new(self._FlowMap, self._State, self._Trigger, newLockLayers)
end


function StateMachine:unlock(eventName: string)
    if self._LockLayers[eventName] == 0 then return end

    local newLockLayers = table.clone(self._LockLayers)
    newLockLayers[eventName] -= 1

    return StateMachine.new(self._FlowMap, self._State, self._Trigger, newLockLayers)
end


function StateMachine:State(): string
    return self._State
end


function StateMachine:Trigger()
    return Option.Wrap(self._Trigger)
end


function StateMachine:Can(eventName: string): boolean
    local event: Event = self._FlowMap[eventName]

    return event[self._State] ~= nil
end


function StateMachine:IsLocked(eventName: string): boolean
    return self._LockLayers[eventName] ~= 0
end


return function(flowMap: FlowMap)
    return function(initialState: string)
        return StateMachine.new(flowMap, initialState)
    end
end
