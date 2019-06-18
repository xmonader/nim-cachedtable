# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.

import tables, times, os, options, locks

type Entry[V] = object
  value*: V
  ttl*: int64

type CachedTable*[K,V] =  ref object
  cache*: TableRef[K, Entry[V]]
  lock*: locks.Lock

proc newCachedTable*[K,V](defaultTtl=10): CachedTable[K,V] =
  result =  CachedTable[K,V]()
  result.cache = newTable[K, Entry[V]]()

proc setKey*[K, V](t: CachedTable[K,V], key: K, value: V, d:Duration) = 
  let rightnow = times.getTime()
  let rightNowDur = times.initDuration(seconds=rightnow.toUnix(), nanoseconds=rightnow.nanosecond)

  let ttl = d.inNanoseconds + rightNowDur.inNanoseconds
  let entry = Entry[V](value:value, ttl:ttl) 
  t.cache.add(key, entry)

proc setKey*[K, V](t: CachedTable[K,V], key: K, value: V, forever=true) = 
    let entry = Entry[V](value:value, ttl:0) 
    t.cache.add(key, entry)

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