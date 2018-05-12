local byte = string.byte
local char = string.char
local dump = string.dump
local find = string.find
local format = string.format
local len = string.len
local lower = string.lower
local rep = string.rep
local sub = string.sub
local upper = string.upper
local utf8charbytes = function(s, i)
  i = i or 1
  if type(s) ~= "string" then
    error("bad argument #1 to 'utf8charbytes' (string expected, got " .. type(s) .. ")")
  end
  if type(i) ~= "number" then
    error("bad argument #2 to 'utf8charbytes' (number expected, got " .. type(i) .. ")")
  end
  local c = byte(s, i)
  if c > 0 and c <= 127 then
    return 1
  elseif c >= 194 and c <= 223 then
    local c2 = byte(s, i + 1)
    if not c2 then
      error("UTF-8 string terminated early")
    end
    if c2 < 128 or c2 > 191 then
      error("Invalid UTF-8 character")
    end
    return 2
  elseif c >= 224 and c <= 239 then
    local c2 = byte(s, i + 1)
    local c3 = byte(s, i + 2)
    if not c2 or not c3 then
      error("UTF-8 string terminated early")
    end
    if c == 224 and (c2 < 160 or c2 > 191) then
      error("Invalid UTF-8 character")
    elseif c == 237 and (c2 < 128 or c2 > 159) then
      error("Invalid UTF-8 character")
    elseif c2 < 128 or c2 > 191 then
      error("Invalid UTF-8 character")
    end
    if c3 < 128 or c3 > 191 then
      error("Invalid UTF-8 character")
    end
    return 3
  elseif c >= 240 and c <= 244 then
    local c2 = byte(s, i + 1)
    local c3 = byte(s, i + 2)
    local c4 = byte(s, i + 3)
    if not c2 or not c3 or not c4 then
      error("UTF-8 string terminated early")
    end
    if c == 240 and (c2 < 144 or c2 > 191) then
      error("Invalid UTF-8 character")
    elseif c == 244 and (c2 < 128 or c2 > 143) then
      error("Invalid UTF-8 character")
    elseif c2 < 128 or c2 > 191 then
      error("Invalid UTF-8 character")
    end
    if c3 < 128 or c3 > 191 then
      error("Invalid UTF-8 character")
    end
    if c4 < 128 or c4 > 191 then
      error("Invalid UTF-8 character")
    end
    return 4
  else
    error("Invalid UTF-8 character")
  end
end
local utf8len = function(s)
  if type(s) ~= "string" then
    for k, v in pairs(s) do
      print("\"", tostring(k), "\"", tostring(v), "\"")
    end
    error("bad argument #1 to 'utf8len' (string expected, got " .. type(s) .. ")")
  end
  local pos = 1
  local bytes = len(s)
  local length = 0
  while pos <= bytes do
    length = length + 1
    pos = pos + utf8charbytes(s, pos)
  end
  return length
end
local utf8sub = function(s, i, j)
  j = j or -1
  local pos = 1
  local bytes = len(s)
  local length = 0
  local l = i >= 0 and j >= 0 or utf8len(s)
  local startChar = i >= 0 and i or l + i + 1
  local endChar = j >= 0 and j or l + j + 1
  if startChar > endChar then
    return ""
  end
  local startByte, endByte = 1, bytes
  while pos <= bytes do
    length = length + 1
    if length == startChar then
      startByte = pos
    end
    pos = pos + utf8charbytes(s, pos)
    if length == endChar then
      endByte = pos - 1
      break
    end
  end
  if startChar > length then
    startByte = bytes + 1
  end
  if endChar < 1 then
    endByte = 0
  end
  return sub(s, startByte, endByte)
end
local utf8reverse = function(s)
  if type(s) ~= "string" then
    error("bad argument #1 to 'utf8reverse' (string expected, got " .. type(s) .. ")")
  end
  local bytes = len(s)
  local pos = bytes
  local charbytes
  local newstr = ""
  while pos > 0 do
    local c = byte(s, pos)
    while c >= 128 and c <= 191 do
      pos = pos - 1
      c = byte(s, pos)
    end
    charbytes = utf8charbytes(s, pos)
    newstr = newstr .. sub(s, pos, pos + charbytes - 1)
    pos = pos - 1
  end
  return newstr
end
local utf8char = function(unicode)
  if unicode <= 127 then
    return char(unicode)
  end
  if unicode <= 2047 then
    local Byte0 = 192 + math.floor(unicode / 64)
    local Byte1 = 128 + unicode % 64
    return char(Byte0, Byte1)
  end
  if unicode <= 65535 then
    local Byte0 = 224 + math.floor(unicode / 4096)
    local Byte1 = 128 + math.floor(unicode / 64) % 64
    local Byte2 = 128 + unicode % 64
    return char(Byte0, Byte1, Byte2)
  end
  if unicode <= 1114111 then
    local code = unicode
    local Byte3 = 128 + code % 64
    code = math.floor(code / 64)
    local Byte2 = 128 + code % 64
    code = math.floor(code / 64)
    local Byte1 = 128 + code % 64
    code = math.floor(code / 64)
    local Byte0 = 240 + code
    return char(Byte0, Byte1, Byte2, Byte3)
  end
  error("Unicode cannot be greater than U+10FFFF!")
end
local shift_6 = 64
local shift_12 = 4096
local shift_18 = 262144
local utf8unicode
function utf8unicode(str, i, j, byte_pos)
  i = i or 1
  j = j or i
  if i > j then
    return
  end
  local ch, bytes
  if byte_pos then
    bytes = utf8charbytes(str, byte_pos)
    ch = sub(str, byte_pos, byte_pos - 1 + bytes)
  else
    ch, byte_pos = utf8sub(str, i, i), 0
    bytes = #ch
  end
  local unicode
  if bytes == 1 then
    unicode = byte(ch)
  end
  if bytes == 2 then
    local byte0, byte1 = byte(ch, 1, 2)
    local code0, code1 = byte0 - 192, byte1 - 128
    unicode = code0 * shift_6 + code1
  end
  if bytes == 3 then
    local byte0, byte1, byte2 = byte(ch, 1, 3)
    local code0, code1, code2 = byte0 - 224, byte1 - 128, byte2 - 128
    unicode = code0 * shift_12 + code1 * shift_6 + code2
  end
  if bytes == 4 then
    local byte0, byte1, byte2, byte3 = byte(ch, 1, 4)
    local code0, code1, code2, code3 = byte0 - 240, byte1 - 128, byte2 - 128, byte3 - 128
    unicode = code0 * shift_18 + code1 * shift_12 + code2 * shift_6 + code3
  end
  return unicode, utf8unicode(str, i + 1, j, byte_pos + bytes)
end
local utf8gensub = function(str, sub_len)
  sub_len = sub_len or 1
  local byte_pos = 1
  local length = #str
  return function(skip)
    if skip then
      byte_pos = byte_pos + skip
    end
    local char_count = 0
    local start = byte_pos
    repeat
      if byte_pos > length then
        return
      end
      char_count = char_count + 1
      local bytes = utf8charbytes(str, byte_pos)
      byte_pos = byte_pos + bytes
    until char_count == sub_len
    local last = byte_pos - 1
    local slice = sub(str, start, last)
    return slice, start, last
  end
end
local binsearch = function(sortedTable, item, comp)
  local head, tail = 1, #sortedTable
  local mid = math.floor((head + tail) / 2)
  if not comp then
    while tail - head > 1 do
      if item < sortedTable[tonumber(mid)] then
        tail = mid
      else
        head = mid
      end
      mid = math.floor((head + tail) / 2)
    end
  end
  if sortedTable[tonumber(head)] == item then
    return true, tonumber(head)
  elseif sortedTable[tonumber(tail)] == item then
    return true, tonumber(tail)
  else
    return false
  end
end
local classMatchGenerator = function(class, plain)
  local codes = {}
  local ranges = {}
  local ignore = false
  local range = false
  local firstletter = true
  local unmatch = false
  local it = utf8gensub(class)
  local skip
  for c, _, be in it, nil, nil do
    skip = be
    if not ignore and not plain then
      if c == "%" then
        ignore = true
      elseif c == "-" then
        table.insert(codes, utf8unicode(c))
        range = true
      elseif c == "^" then
        if not firstletter then
          error("!!!")
        else
          unmatch = true
        end
      elseif c ~= "]" then
        if not range then
          table.insert(codes, utf8unicode(c))
        else
          table.remove(codes)
          table.insert(ranges, {
            table.remove(codes),
            utf8unicode(c)
          })
          range = false
        end
        elseif ignore and not plain then
          if c == "a" then
            table.insert(ranges, {65, 90})
            table.insert(ranges, {97, 122})
          elseif c == "c" then
            table.insert(ranges, {0, 31})
            table.insert(codes, 127)
          elseif c == "d" then
            table.insert(ranges, {48, 57})
          elseif c == "g" then
            table.insert(ranges, {1, 8})
            table.insert(ranges, {14, 31})
            table.insert(ranges, {33, 132})
            table.insert(ranges, {134, 159})
            table.insert(ranges, {161, 5759})
            table.insert(ranges, {5761, 8191})
            table.insert(ranges, {8203, 8231})
            table.insert(ranges, {8234, 8238})
            table.insert(ranges, {8240, 8286})
            table.insert(ranges, {8288, 12287})
          elseif c == "l" then
            table.insert(ranges, {97, 122})
          elseif c == "p" then
            table.insert(ranges, {33, 47})
            table.insert(ranges, {58, 64})
            table.insert(ranges, {91, 96})
            table.insert(ranges, {123, 126})
          elseif c == "s" then
            table.insert(ranges, {9, 13})
            table.insert(codes, 32)
            table.insert(codes, 133)
            table.insert(codes, 160)
            table.insert(codes, 5760)
            table.insert(ranges, {8192, 8202})
            table.insert(codes, 8232)
            table.insert(codes, 8233)
            table.insert(codes, 8239)
            table.insert(codes, 8287)
            table.insert(codes, 12288)
          elseif c == "u" then
            table.insert(ranges, {65, 90})
          elseif c == "w" then
            table.insert(ranges, {48, 57})
            table.insert(ranges, {65, 90})
            table.insert(ranges, {97, 122})
          elseif c == "x" then
            table.insert(ranges, {48, 57})
            table.insert(ranges, {65, 70})
            table.insert(ranges, {97, 102})
          elseif not range then
            table.insert(codes, utf8unicode(c))
          else
            table.remove(codes)
            table.insert(ranges, {
              table.remove(codes),
              utf8unicode(c)
            })
            range = false
          end
          ignore = false
        else
          if not range then
            table.insert(codes, utf8unicode(c))
          else
            table.remove(codes)
            table.insert(ranges, {
              table.remove(codes),
              utf8unicode(c)
            })
            range = false
          end
          ignore = false
        end
        firstletter = false
      end
  end
  table.sort(codes)
  local inRanges = function(charCode)
    for _, r in ipairs(ranges) do
      if charCode >= r[1] and charCode <= r[2] then
        return true
      end
    end
    return false
  end
  if not unmatch then
    return function(charCode)
      return binsearch(codes, charCode) or inRanges(charCode)
    end, skip
  else
    return function(charCode)
      return charCode ~= -1 and not binsearch(codes, charCode) and not inRanges(charCode)
    end, skip
  end
end

local cache = setmetatable({}, {__mode = "kv"})
local cachePlain = setmetatable({}, {__mode = "kv"})
local matcherGenerator = function(regex, plain)
  local matcher = {
    functions = {},
    captures = {}
  }
  if not plain then
    cache[regex] = matcher
  else
    cachePlain[regex] = matcher
  end
  local simple = function(func)
    return function(cC)
      if func(cC) then
        matcher:nextFunc()
        matcher:nextStr()
      else
        matcher:reset()
      end
    end
  end
  local star = function(func)
    return function(cC)
      if func(cC) then
        matcher:fullResetOnNextFunc()
        matcher:nextStr()
      else
        matcher:nextFunc()
      end
    end
  end
  local minus = function(func)
    return function(cC)
      if func(cC) then
        matcher:fullResetOnNextStr()
      end
      matcher:nextFunc()
    end
  end
  local question = function(func)
    return function(cC)
      if func(cC) then
        matcher:fullResetOnNextFunc()
        matcher:nextStr()
      end
      matcher:nextFunc()
    end
  end
  local capture = function(id)
    return function(_)
      local l = matcher.captures[id][2] - matcher.captures[id][1]
      local captured = utf8sub(matcher.string, matcher.captures[id][1], matcher.captures[id][2])
      local check = utf8sub(matcher.string, matcher.str, matcher.str + l)
      if captured == check then
        for _ = 0, l do
          matcher:nextStr()
        end
        matcher:nextFunc()
      else
        matcher:reset()
      end
    end
  end
  local captureStart = function(id)
    return function(_)
      matcher.captures[id][1] = matcher.str
      matcher:nextFunc()
    end
  end
  local captureStop = function(id)
    return function(_)
      matcher.captures[id][2] = matcher.str - 1
      matcher:nextFunc()
    end
  end
  local balancer = function(str)
    local sum = 0
    local bc, ec = utf8sub(str, 1, 1), utf8sub(str, 2, 2)
    local skip = len(bc) + len(ec)
    bc, ec = utf8unicode(bc), utf8unicode(ec)
    return function(cC)
      if cC == ec and sum > 0 then
        sum = sum - 1
        if sum == 0 then
          matcher:nextFunc()
        end
        matcher:nextStr()
      elseif cC == bc then
        sum = sum + 1
        matcher:nextStr()
      elseif sum == 0 or cC == -1 then
        sum = 0
        matcher:reset()
      else
        matcher:nextStr()
      end
    end, skip
  end
  matcher.functions[1] = function(_)
    matcher:fullResetOnNextStr()
    matcher.seqStart = matcher.str
    matcher:nextFunc()
    if matcher.str > matcher.startStr and matcher.fromStart or matcher.str >= matcher.stringLen then
      matcher.stop = true
      matcher.seqStart = nil
    end
  end
  local lastFunc
  local ignore = false
  local skip
  local it = (function()
    local gen = utf8gensub(regex)
    return function()
      return gen(skip)
    end
  end)()
  local cs = {}
  for c, bs, be in it, nil, nil do
    skip = nil
    if plain then
      table.insert(matcher.functions, simple(classMatchGenerator(c, plain)))
    elseif ignore then
      if find("123456789", c, 1, true) then
        if lastFunc then
          table.insert(matcher.functions, simple(lastFunc))
          lastFunc = nil
        end
        table.insert(matcher.functions, capture(tonumber(c)))
      elseif c == "b" then
        if lastFunc then
          table.insert(matcher.functions, simple(lastFunc))
          lastFunc = nil
        end
        local b
        b, skip = balancer(sub(regex, be + 1, be + 9))
        table.insert(matcher.functions, b)
      else
        lastFunc = classMatchGenerator("%" .. c)
      end
      ignore = false
    elseif c == "*" then
      if lastFunc then
        table.insert(matcher.functions, star(lastFunc))
        lastFunc = nil
      else
        error("invalid regex after " .. sub(regex, 1, bs))
      end
    elseif c == "+" then
      if lastFunc then
        table.insert(matcher.functions, simple(lastFunc))
        table.insert(matcher.functions, star(lastFunc))
        lastFunc = nil
      else
        error("invalid regex after " .. sub(regex, 1, bs))
      end
    elseif c == "-" then
      if lastFunc then
        table.insert(matcher.functions, minus(lastFunc))
        lastFunc = nil
      else
        error("invalid regex after " .. sub(regex, 1, bs))
      end
    elseif c == "?" then
      if lastFunc then
        table.insert(matcher.functions, question(lastFunc))
        lastFunc = nil
      else
        error("invalid regex after " .. sub(regex, 1, bs))
      end
    elseif c == "^" then
      if bs == 1 then
        matcher.fromStart = true
      else
        error("invalid regex after " .. sub(regex, 1, bs))
      end
    elseif c == "$" then
      if be == len(regex) then
        matcher.toEnd = true
      else
        error("invalid regex after " .. sub(regex, 1, bs))
      end
    elseif c == "[" then
      if lastFunc then
        table.insert(matcher.functions, simple(lastFunc))
      end
      lastFunc, skip = classMatchGenerator(sub(regex, be + 1))
    elseif c == "(" then
      if lastFunc then
        table.insert(matcher.functions, simple(lastFunc))
        lastFunc = nil
      end
      table.insert(matcher.captures, {})
      table.insert(cs, #matcher.captures)
      table.insert(matcher.functions, captureStart(cs[#cs]))
      if sub(regex, be + 1, be + 1) == ")" then
        matcher.captures[#matcher.captures].empty = true
      end
    elseif c == ")" then
      if lastFunc then
        table.insert(matcher.functions, simple(lastFunc))
        lastFunc = nil
      end
      local cap = table.remove(cs)
      if not cap then
        error("invalid capture: \"(\" missing")
      end
      table.insert(matcher.functions, captureStop(cap))
    elseif c == "." then
      if lastFunc then
        table.insert(matcher.functions, simple(lastFunc))
      end
      function lastFunc(cC)
        return cC ~= -1
      end
    elseif c == "%" then
      ignore = true
    else
      if lastFunc then
        table.insert(matcher.functions, simple(lastFunc))
      end
      lastFunc = classMatchGenerator(c)
    end
  end
  if #cs > 0 then
    error("invalid capture: \")\" missing")
  end
  if lastFunc then
    table.insert(matcher.functions, simple(lastFunc))
  end
  table.insert(matcher.functions, function()
    if matcher.toEnd and matcher.str ~= matcher.stringLen then
      matcher:reset()
    else
      matcher.stop = true
    end
  end)
  function matcher:nextFunc()
    self.func = self.func + 1
  end
  function matcher:nextStr()
    self.str = self.str + 1
  end
  function matcher:strReset()
    local oldReset = self.reset
    local str = self.str
    function self.reset(s)
      s.str = str
      s.reset = oldReset
    end
  end
  function matcher:fullResetOnNextFunc()
    local oldReset = self.reset
    local func = self.func + 1
    local str = self.str
    function self.reset(s)
      s.func = func
      s.str = str
      s.reset = oldReset
    end
  end
  function matcher:fullResetOnNextStr()
    local oldReset = self.reset
    local str = self.str + 1
    local func = self.func
    function self.reset(s)
      s.func = func
      s.str = str
      s.reset = oldReset
    end
  end
  function matcher:process(str, start)
    self.func = 1
    start = start or 1
    self.startStr = start >= 0 and start or utf8len(str) + start + 1
    self.seqStart = self.startStr
    self.str = self.startStr
    self.stringLen = utf8len(str) + 1
    self.string = str
    self.stop = false
    function self.reset(s)
      s.func = 1
    end
    local ch
    while not self.stop do
      if self.str < self.stringLen then
        ch = utf8sub(str, self.str, self.str)
        self.functions[self.func](utf8unicode(ch))
      else
        self.functions[self.func](-1)
      end
    end
    if self.seqStart then
      local captures = {}
      for _, pair in pairs(self.captures) do
        if pair.empty then
          table.insert(captures, pair[1])
        else
          table.insert(captures, utf8sub(str, pair[1], pair[2]))
        end
      end
      return self.seqStart, self.str - 1, unpack(captures)
    end
  end
  return matcher
end
local utf8find = function(str, regex, init, plain)
  local matcher = cache[regex] or matcherGenerator(regex, plain)
  return matcher:process(str, init)
end
local utf8match = function(str, regex, init)
  init = init or 1
  local found = {
    utf8find(str, regex, init)
  }
  if found[1] then
    if found[3] then
      return unpack(found, 3)
    end
    return utf8sub(str, found[1], found[2])
  end
end
local utf8gmatch = function(str, regex, all)
  if utf8sub(regex, 1, 1) == "^" or not regex then
    regex = "%" .. regex
  end
  local lastChar = 1
  return function()
    local found = {
      utf8find(str, regex, lastChar)
    }
    if found[1] then
      lastChar = found[2] + 1
      if found[all and 1 or 3] then
        return unpack(found, all and 1 or 3)
      end
      return utf8sub(str, found[1], found[2])
    end
  end
end
local replace = function(repl, args)
  local ret = ""
  if type(repl) == "string" then
    local ignore = false
    local num
    for c in utf8gensub(repl) do
      if not ignore then
        if c == "%" then
          ignore = true
        else
          ret = ret .. c
        end
      else
        num = tonumber(c)
        if num then
          ret = ret .. args[num]
        else
          ret = ret .. c
        end
        ignore = false
      end
    end
  elseif type(repl) == "table" then
    ret = repl[args[1] or args[0]] or ""
  elseif type(repl) == "function" then
    if #args > 0 then
      ret = repl(unpack(args, 1)) or ""
    else
      ret = repl(args[0]) or ""
    end
  end
  return ret
end
local utf8gsub = function(str, regex, repl, limit)
  limit = limit or -1
  local ret = ""
  local prevEnd = 1
  local it = utf8gmatch(str, regex, true)
  local found = {
    it()
  }
  local n = 0
  while #found > 0 and limit ~= n do
    local args = {
      [0] = utf8sub(str, found[1], found[2]),
      unpack(found, 3)
    }
    ret = ret .. utf8sub(str, prevEnd, found[1] - 1) .. replace(repl, args)
    prevEnd = found[2] + 1
    n = n + 1
    found = {
      it()
    }
  end
  return ret .. utf8sub(str, prevEnd), n
end
local utf8 = {}
utf8.len = utf8len
utf8.sub = utf8sub
utf8.reverse = utf8reverse
utf8.char = utf8char
utf8.unicode = utf8unicode
utf8.gensub = utf8gensub
utf8.byte = utf8unicode
utf8.find = utf8find
utf8.match = utf8match
utf8.gmatch = utf8gmatch
utf8.gsub = utf8gsub
utf8.dump = dump
utf8.format = format
utf8.lower = lower
utf8.upper = upper
utf8.rep = rep
return utf8
