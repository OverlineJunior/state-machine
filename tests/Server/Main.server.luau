local ReplicatedStorage = game:GetService('ReplicatedStorage')

local StateMachine = require(ReplicatedStorage.Shared.StateMachine)

local lock = StateMachine.new {
    InitialState = 'Locked',

    TurnKey = {
        Locked = 'Unlocked',
        Unlocked = 'Locked',
    },

    Break = {
        Locked = 'Broken',
        Unlocked = 'Broken',
    },
}

lock:Transition('Break')

lock:TryTransition('TurnKey'):Match {
    Some = function(trigger)
        print(trigger)
    end,
    None = function()
        print('None')
    end,
}
