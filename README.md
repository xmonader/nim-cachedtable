# nim-cachedtable

Set expiration duration for your keys in `CachedTable`

## Example

```nim
  var c = newCachedTable[string, string]()
  c.setKey("name", "ahmed", initDuration(seconds = 10))
  c.setKey("color", "blue", initDuration(seconds = 5))
  c.setKey("lang", "nim", true)

  for i in countup(0, 20):
    echo $c.cache
    echo $c.get("name")
    echo $c.get("color")
    echo $c.get("lang")

    os.sleep(1*1000)

```