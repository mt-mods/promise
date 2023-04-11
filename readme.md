promise library for minetest

![](https://github.com/mt-mods/promise/workflows/luacheck/badge.svg)
![](https://github.com/mt-mods/promise/workflows/test/badge.svg)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](license.txt)
[![Download](https://img.shields.io/badge/Download-ContentDB-blue.svg)](https://content.minetest.net/packages/mt-mods/promise)
[![Coverage Status](https://coveralls.io/repos/github/mt-mods/promise/badge.svg?branch=master)](https://coveralls.io/github/mt-mods/promise?branch=master)

# Overview

TODO

```lua
Promise.formspec(player, "size[2,2]button[0,0;2,2;mybutton;label]")
:then(function(data)
    assert(data.player:get_player_name())
    assert(data.fields.mybutton == true)
end)
```

# License

* Code: MIT
