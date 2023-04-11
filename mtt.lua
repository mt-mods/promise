
mtt.register("smoketest", function(callback)
    Promise.new(function(resolve)
        resolve(5)
    end):next(function(result)
        assert(result == 5)
        callback()
    end)
end)
