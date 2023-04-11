
function Promise.http(http, url, opts)
    assert(http, "http instance is nil")
    assert(url, "no url given")

    -- defaults
    opts = opts or {}

    return Promise.new(function(resolve, reject)
        local extra_headers = {}

        local data = opts.post_data
        if type(data) == "table" then
            -- serialize as json
            data = minetest.write_json(data)
            table.insert(extra_headers, "Content-Type: application/json")
        end

        http.fetch({
            url = url,
            extra_headers = extra_headers,
            timeout = opts.timeout or 10,
            method = opts.method or "GET",
            data = data
        }, function(res)
            if res.succeeded and res.code == 200 then
                if opts.json then
                    resolve(minetest.parse_json(res.data))
                else
                    resolve(res.data)
                end
            else
                reject({
                    code = res.code or 0,
                    data = res.data
                })
            end
        end)
    end)
end
