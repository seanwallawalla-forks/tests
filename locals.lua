print('testando variaveis locais e uns extras')

f = nil

local f
x = 1

assert(type(dostring('local a = {}')) ~= 'table')

function f (a)
  local _1, _2, _3, _4, _5
  local _6, _7, _8, _9, _10
  local x = 3
  local b = a
  local c,d = a,b
  if (d == b) then
    local x = 'q'
    x = b
    assert(x == 2)
  else
    assert(nil)
  end
  assert(x == 3)
  local f = 10
end

local b=10
local a; repeat local b; a,b=1,2; assert(a+1==b); until a+b==11


assert(x == 1)

f(2)
assert(type(f) == 'function')


-- testando limites para instrucoes especiais

local a
local p = 4
for i=2,31 do
  for j=-3,3 do
    assert(dostring(format([[local a=%s;a=a+
                                            %s;
                             assert(a
                                      ==2^%s)]], j, p-j, i)))
    assert(dostring(format([[local a=%s;
                             a=a-%s;
                             assert(a==-2^%s)]], -j, p-j, i)))
    assert(dostring(format([[local a,b=0,%s;
                             a=b-%s;
                             assert(a==-2^%s)]], -j, p-j, i)))
  end
  p =2*p
end

print'+'


if querytab then
  -- testando remocao de elementos mortos dos indices de tabelas
  collectgarbage(1000000)   -- stop GC
  local a = {[{}] = 4, [3] = 0, alo = 1, 
             a1234567890123456789012345678901234567890 = 10}

  local t = querytab(a)

  for k,_ in a do a[k] = nil end
  collectgarbage()   -- restore GC and collect dead fiels in `a'
  for i=0,t-1 do
    local k = querytab(a, i)
    assert(k == nil or type(k) == 'number' or k == 'alo')
  end
end

print('OK')

return 5,f
