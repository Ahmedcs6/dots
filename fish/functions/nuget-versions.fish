function nuget-versions
    curl -s "https://api.nuget.org/v3-flatcontainer/$argv[1]/index.json"
end
