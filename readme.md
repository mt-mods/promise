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
:next(function(data)
    assert(data.player:get_player_name())
    assert(data.fields.mybutton == true)
end)
```

```lua
local http = minetest.request_http_api()

-- call chuck norris api: https://api.chucknorris.io/ and expect json-response
Promise.http(http, "https://api.chucknorris.io/jokes/random", { json = true })
:next(function(joke)
    assert(type(joke.value) == "string")
end)

-- post json-payload with 10 second timeout and expect raw string-response (or error)
Promise.http(http, "http://localhost/stuff", { method = "POST", timeout = 10, data = { x=123 } })
:next(function(result)
    assert(result)
end):catch(function(result)
    assert(result.code == 500)
    assert(result.data == "Server error")
end)
```

# License

* Code: MIT
