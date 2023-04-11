local http = ...

mtt.register("Promise.http", function(callback)
    Promise.http(http, "https://api.chucknorris.io/jokes/random", { json = true }):next(function(joke)
        assert(type(joke.value) == "string")
        callback()
    end)
end)