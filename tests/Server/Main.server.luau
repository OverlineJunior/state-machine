local ReplicatedStorage = game:GetService('ReplicatedStorage')

local StateMachine = require(ReplicatedStorage.Shared.StateMachine)

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

local lock = Lock('Locked')
lock = lock:transition('TurnKey')
