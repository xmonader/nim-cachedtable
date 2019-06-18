# nim-cachedtable

Set expiration duration for your keys in `CachedTable`

## Example

```nim
  var c = newCachedTable[string, string](initDuration(seconds=2))
  c.setKey("name", "ahmed", initDuration(seconds = 10))
  c.setKey("color", "blue", initDuration(seconds = 5))
  c.setKey("akey", "a value", DefaultExpiration)
  c.setKey("akey2", "a value2", DefaultExpiration)

  c.setKey("lang", "nim", NeverExpires)

  for i in countup(0, 20):
    echo "has key name? " & $c.hasKey("name")
    echo $c.cache
    echo $c.get("name")
    echo $c.get("color")
    echo $c.get("lang")
    echo $c.get("akey")
    echo $c.get("akey2")

    os.sleep(1*1000)
```

## Docs

API is available [here](https://xmonader.github.io/nim-cachedtable/api/cachedtable.html)