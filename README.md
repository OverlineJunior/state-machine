<h2><center>🤖 StateMachine</center></h2>

---

An immutable class for handling the state of things, where the design is a copy of Rust's sm crate, but with a few additions and changes.

API: https://overlinejunior.github.io/state-machine  
Wally: https://wally.run/package/overlinejunior/state-machine

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

local lock = Lock('Locked')
lock = lock:transition('TurnKey')

assert(lock:State(), 'Unlocked')
assert(lock:Trigger():Unwrap(), 'TurnKey')
```