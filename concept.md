```lua
    local Lock = StateMachine {
        InitialStates = {'Locked', 'Unlocked'},

        TurnKey = {
            Locked = function() -- System passes current state and/or other things?
                if ok then
                    return 'Unlocked'
                end
            end,
            Unlocked = 'Locked',
        }

        Break = {
            Locked = 'Broken',
            Unlocked = 'Broken',
        }
    }

    local lock = Lock('Locked')
    lock = lock:transition('TurnKey')
    lock = lock:transition('Break')
    lock = lock:transition('TurnKey') -- Error!

    print(lock:State())
```

New
```lua
    local lock = StateMachine.new {
        InitialState = 'Locked',

        TurnKey = {
            Locked = function()
                if ok then
                    return 'Unlocked'
                end
            end,
            Unlocked = 'Locked',
        }

        Break = {
            Locked = 'Broken',
            Unlocked = 'Broken',
        }
    }

    lock:Lock('TurnKey')
    lock:Unlock('TurnKey')
    lock:IsLocked('TurnKey')

    lock:Transition('TurnKey')
    lock:Transition('Break')
    lock:Transition('TurnKey') -- Error!

    print(lock:State())
```