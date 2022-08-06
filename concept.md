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

    local lock = Lock.new('Locked')
    lock = lock:transition('TurnKey')
    lock = lock:transition('Break')
    lock = lock:transition('TurnKey') -- Error!

    print(lock:State())
```

If returning a constructor removes the autocompleting.
```lua
    local lock = StateMachine.new({
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
    }, 'Locked')

    lock = lock:transition('TurnKey')
```