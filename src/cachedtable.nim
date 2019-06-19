import tables, times, os, options, locks

type Expiration* = enum NeverExpires, DefaultExpiration

type Entry*[V] = object
  value*: V
  ttl*: int64

type CachedTable*[K,V] =  ref object
  cache: Table[K, Entry[V]]
  lock*: locks.Lock
  defaultExpiration*: Duration

proc newCachedTable*[K,V](defaultExpiration = initDuration(seconds=5)): CachedTable[K,V] =
  ## Create new CachedTable
  result =  CachedTable[K,V]()
  result.cache = initTable[K, Entry[V]]()
  result.defaultExpiration = defaultExpiration

proc setKey*[K, V](t: CachedTable[K,V], key: K, value: V, d:Duration) = 
  ## Set ``Key`` of type ``K`` (needs to be hashable) to ``value`` of type ``V`` with duration ``d``
  let rightnow = times.getTime()
  let rightNowDur = times.initDuration(seconds=rightnow.toUnix(), nanoseconds=rightnow.nanosecond)

  let ttl = d.inNanoseconds + rightNowDur.inNanoseconds
  let entry = Entry[V](value:value, ttl:ttl) 
  t.cache.add(key, entry)

proc getCache*[K,V](t: CachedTable[K,V]): Table[K,Entry[V]] = 
  result = t.cache

proc setKey*[K, V](t: CachedTable[K,V], key: K, value: V, expiration:Expiration=NeverExpires) = 
  ## Sets key with `Expiration` strategy
  var entry: Entry[V]
  case expiration:
  of NeverExpires: 
    entry = Entry[V](value:value, ttl:0)
    t.cache.add(key, entry)
  of DefaultExpiration: 
    t.setKey(key, value, d=t.defaultExpiration)

proc setKeyWithDefaultTtl*[K, V](t: CachedTable[K,V], key: K, value: V) =
  ## Sets a key with default Ttl duration.
  t.setKey(key, value, DefaultExpiration)

proc hasKey*[K,V](t: CachedTable[K,V], key:K): bool =
  ## Checks if `key` exists in cache
  result = t.cache.hasKey(key)

proc isExpired(ttl: int64): bool =
  if ttl == 0:
    # echo "duration 0 never expires."
    result = false
  else:
    let rightnow = times.getTime()
    let rightNowDur = times.initDuration(seconds=rightnow.toUnix(), nanoseconds=rightnow.nanosecond)
    # echo "Now is : " & $rightnow
    result = rightnowDur.inNanoseconds > ttl  
  
proc get*[K,V](t: CachedTable[K,V], key: K): Option[V] = 
  ## Get value of `key` from cache
  var entry: Entry[V]
  try:
    withLock t.lock:
      entry = t.cache[key]
  except:
    return none(V)

  # echo "getting entry for key: " & key  & $entry
  if not isExpired(entry.ttl):
    # echo "k: " & key & " didn't expire"
    return some(entry.value)
  else:
    # echo "k: " & key & " expired"
    del(t.cache, key)
    return none(V)


when isMainModule:
  var c = newCachedTable[string, string](initDuration(seconds=2))
  c.setKey("name", "ahmed", initDuration(seconds = 10))
  c.setKey("color", "blue", initDuration(seconds = 5))
  c.setKey("akey", "a value", DefaultExpiration)
  c.setKey("akey2", "a value2", DefaultExpiration)

  c.setKey("lang", "nim", NeverExpires)

  for i in countup(0, 20):
    echo "has key name? " & $c.hasKey("name")
    echo $c.getCache
    echo $c.get("name")
    echo $c.get("color")
    echo $c.get("lang")
    echo $c.get("akey")
    echo $c.get("akey2")

    os.sleep(1*1000)
