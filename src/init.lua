local Option = require(script.Parent.Option)

type Event = {[string]: string | () -> string?}
type FlowMap = {[string]: Event}
type LockLayers = {[string]: number}


local function Assert(eval, genMsg: () -> string, level: number?)
    if not eval then
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


--[=[
    @method lock
    @param eventName string
    @return StateMachine
    @within StateMachine

    Returns a new StateMachine where the event can no longer be triggered.

    :::note
    Locking and unlocking is layer-based, which means that locking twice results in 2 layers, thus, to actually
    unlock the event, you now have to unlock it 2 times.
    :::
]=]
function StateMachine:lock(eventName: string)
    local newLockLayers = table.clone(self._LockLayers)
    newLockLayers[eventName] += 1

    return StateMachine.new(self._FlowMap, self._State, self._Trigger, newLockLayers)
end


--[=[
    @method unlock
    @param eventName string
    @return StateMachine
    @within StateMachine

    Returns a new StateMachine where the event can be triggered, but only if no lock layer remains.
]=]
function StateMachine:unlock(eventName: string)
    if self._LockLayers[eventName] == 0 then return end

    local newLockLayers = table.clone(self._LockLayers)
    newLockLayers[eventName] -= 1

    return StateMachine.new(self._FlowMap, self._State, self._Trigger, newLockLayers)
end


--[=[
    @method IsLocked
    @param eventName string
    @return boolean
    @within StateMachine

    Returns true if there are 1 or more layers of lock for the event.
]=]
function StateMachine:IsLocked(eventName: string): boolean
    return self._LockLayers[eventName] ~= 0
end


--[=[
    @method State
    @return string
    @within StateMachine

    Returns the state of the machine.
]=]
function StateMachine:State(): string
    return self._State
end


--[=[
    @method Trigger
    @return Option<string>
    @within StateMachine

    Returns the last triggered event wrapped in an option or option.None if no event has been triggerd yet.

    Option's API: https://sleitnick.github.io/RbxUtil/api/Option/
]=]
function StateMachine:Trigger()
    return Option.Wrap(self._Trigger)
end


--[=[
    @method Can
    @param eventName string
    @return boolean
    @within StateMachine

    Returns true if the event can be triggered based on the machine's current state.
]=]
function StateMachine:Can(eventName: string): boolean
    local event: Event = self._FlowMap[eventName]

    return event[self._State] ~= nil and not self:IsLocked(eventName)
end


return function(flowMap: FlowMap)
    return function(initialState: string)
        return StateMachine.new(flowMap, initialState)
    end
end
