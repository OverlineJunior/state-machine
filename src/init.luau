local Option = require(script.Parent.Option)
local Result = require(script.Parent.Result)

type Event = {[string]: string | () -> string?}
type FlowMap = {
    InitialState: string,
    [string]: Event,
}

local EVENT_NOT_FOUND_ERR = 'Event %q not found'
local INVALID_TRANSITION_ERR = 'The %q event cannot be triggered when on the %q state'
local EVENT_LOCKED_ERR = 'The %q event is locked'
local FN_FAIL_ERR = 'The %s.%s function failed'
local FN_INVALID_RETURN_TYPE_ERR = 'Expected the %s.%s function to return string or nil, got %s'

local StateMachine = {}
StateMachine.__index = StateMachine


function StateMachine.new(flowMap: FlowMap)
    local self = setmetatable({}, StateMachine)
    self._FlowMap = flowMap
    self._State = flowMap.InitialState
    self._Trigger = nil

    self._LockLayers = {}
    for k in flowMap do
        if k == 'InitialState' then continue end

        self._LockLayers[k] = 0
    end

    return self
end


function StateMachine:Transition(eventName: string)
    local event = assert(self._FlowMap[eventName], EVENT_NOT_FOUND_ERR:format(eventName))
    local newState = event[self._State]

    if type(newState) == 'function' then
        newState = newState()
    end

    self:Can(eventName):Expect()

    self._State = newState
    self._Trigger = eventName
end


function StateMachine:TryTransition(...: string)
    for _, eventName in {...} do
        if self:Can(eventName):IsOk() then
            self:Transition(eventName)
            return Option.Some(eventName)
        end
    end

    return Option.None
end


function StateMachine:Can(eventName: string)
    local event = assert(self._FlowMap[eventName], EVENT_NOT_FOUND_ERR:format(eventName))
    local newState = event[self._State]

    if newState == nil then
        return Result.Err((INVALID_TRANSITION_ERR):format(eventName, self._State))
    elseif self:IsLocked(eventName) then
        return Result.Err((EVENT_LOCKED_ERR):format(eventName))
    end

    if type(newState) == 'function' then
        newState = newState()

        if newState == nil then
            return Result.Err((FN_FAIL_ERR):format(eventName, self._State))
        elseif type(newState) ~= 'string' then
            return Result.Err((FN_INVALID_RETURN_TYPE_ERR):format(eventName, self._State, typeof(newState)))
        end
    end


    return Result.Ok()
end


function StateMachine:State(): string
    return self._State
end


function StateMachine:Trigger()
    return Option.Wrap(self._Trigger)
end


function StateMachine:Lock(eventName: string)
    assert(self._FlowMap[eventName], EVENT_NOT_FOUND_ERR:format(eventName))

    self._LockLayers[eventName] += 1
end


function StateMachine:Unlock(eventName: string)
    assert(self._FlowMap[eventName], EVENT_NOT_FOUND_ERR:format(eventName))

    if self._LockLayers[eventName] == 0 then return end

    self._LockLayers[eventName] -= 1
end


function StateMachine:IsLocked(eventName: string): (boolean, number)
    assert(self._FlowMap[eventName], EVENT_NOT_FOUND_ERR:format(eventName))

    return self._LockLayers[eventName] ~= 0, self._LockLayers[eventName]
end


return StateMachine
