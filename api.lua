
$ifnot testC

  print('\a\n >>> testC nao ativo: pulando testes da API <<<\n\a')

$else

  print('testando API com C')

a,b = testC("pushnum 1; pushnum 2")
assert(a == 1 and b == 2)

testC[[
	pushnum		1
	pushnum		4
	setglobal	a
	setglobal	b
]]
assert(a == 4 and b == 1)

com = "getparam r1 1; pushreg r1"
assert(testC(com) == com)

a = testC[[
	createtable	r1
	pushreg		r1
	pushnum		4
	pushnum		8
	settable
	pushreg		r1
]]
assert(a[4] == 8)

function f (a,b,c,d)
  assert(a==b and d==nil);
  if c == nil then
    -- push(3); push(3); push(1); f(); r1 = result(1); push(r1)
    return testC[[
	pushnum		3
	pushnum		3
	pushnum		1
	call		f
	getresult	r1 1
	pushreg		r1
  ]]
  else return a
  end
end

glob = 2
assert(testC[[
	pushnum		2
	getglobal	r1, glob
	pushreg		r1
	call		f
	getresult	r1, 1
	pushreg		r1
	pushreg		r1
	call		f
	getresult	r1, 1
	pushreg		r1
]] == 3)

a = {x=45}
a,b = testC[[
	pushstring	alo
	getglobal	r0, a
	pushreg		r0
	pushstring	x
	gettable	r1
	pushreg		r1
]]
assert(a == 'alo' and b == 45)

testC[[
	pushstring	a
	createtable	r0
	pushreg		r0
	pushnum		1
	pushnum		2
	rawsettable
	pushstring	a
	pushreg		r0
	setglobal	x
	getglobal	r5, x
	pushreg		r5
	pushnum		1
	gettable	r3
	pushreg		r3
	setglobal	a
	call		f
]]		
assert(a == 2 and x[1] == 2)

a,b = testC('pushnum 1; call sin; pushnum 9; getresult r1, 1; pushreg r1')
assert(a == 9 and b == sin(1))
assert(testC('pushnum 1; call sin') == nil)

-- push(1); r3 = getglobal('x'); r1 = param(2); r5 = pop(); push(r1)
a = call(testC, {[[
	pushnum		1
	getglobal	r3, x
	getparam	r1, 2
	pop		r5
	pushreg		r1
]], "testando"}, "pack")
assert(a.n == 1 and a[1] == "testando")

-- teste de muitos locks
Arr = {}
Lim = 100
i = 1
while i<= Lim do  -- lock many objects
  Arr[i] = testC("getglobal r1, i; pushreg r1; reflock r1; pushreg r1")
  i = i+1
end

i = 1
while i<= Lim do  -- unlock half of them
  testC("getparam r1, 2; unref r1", Arr[i])
  i = i+2
end


a = nil
a,b = testC[[
	getglobal	r0, a
	pushreg		r0
	reflock		r2
	getref		r3, r2
	pushreg		r3
	pushreg		r2
]]
assert(not a and b == -1)      -- (-1 == LUA_REFNIL)

a = testC("createtable r0, pushreg r0; reflock r1; pushreg r1")

collectgarbage()

assert(type(testC("getglobal r5, a; getref r5, r5; pushreg r5")) == 'table')


-- colect in cl the 'val' of all collected tables
tt = newtag()
cl = {n=0}
function f(x)
  local udval = testC('getparam r2, 2; udataval r1, r2; pushreg r1',x)
  cl.n = cl.n+1
  cl[udval] = 1
end
testC([[getparam r1, 2; pushreg r1;
       getparam r2, 3;
       settagmethod r2, gc
]], f, tt)

-- create 3 userdatas with tag `tt' and values 1, 2, and 3
a = testC('getparam r1, 2; getparam r2, 3; pushusertag r1, r2', 1, tt);
b = testC('getparam r1, 2; getparam r2, 3; pushusertag r1, r2', 2, tt);
c = testC('getparam r1, 2; getparam r2, 3; pushusertag r1, r2', 3, tt);

d,e,f = testC[[
	getglobal	r1, a
	pushreg		r1
	reflock		r1
	pushreg		r1
	getglobal	r1, b
	pushreg		r1
	ref		r1
	pushreg		r1
	getglobal	r1, c
	pushreg		r1
	ref		r1
	pushreg		r1
]]
-- return lock[d], lock[e], lock[f]
t = call(testC, {[[
	getglobal	r1, d
	getref		r2, r1
	pushreg		r2
	getglobal	r1, e
	getref		r2, r1
	pushreg		r2
	getglobal	r1, f
	getref		r2, r1
	pushreg		r2
]]}, "pack")
assert(t[1] == a and t[2] == b and t[3] == c)
t=nil a=nil b=nil c=nil

collectgarbage()

x = testC("getparam r1, 2; getref r5, r1; pushreg r5", d)
assert(type(x) == 'userdata' and tag(x) == tt)
-- atempt to get "collected object"; must gives an error
call(testC, {"getparam r1, 2; getref r5, r1; pushreg r5" , e},
                "px", function (s) x=s end)
assert(strfind(x, "NOOBJECT"))

-- check that unlocked objects have been collected
assert(cl.n == 2 and cl[2] and cl[3] and not cl[1])

-- unref(d); unref(e); unref(f)
testC([[
	getparam	r2, 2
	getparam	r3, 3
	getparam	r4, 4
	unref		r2
	unref		r3
	unref		r4
]], d, e, f)
collectgarbage()
assert(cl.n == 3 and cl[1])

i = 2
while i<= Lim do  -- unlock the other half
  testC("getparam r1, 2; unref r1", Arr[i])    -- unref(Arr[i])
  i = i+2
end

print'+'

assert(testC("getparam r2, 2; getparam r3, 3; equal r2, r3",
              print, print) == 1)
assert(testC("getparam r2, 2; getparam r3, 3; equal r2, r3",
             'alo', "alo") == 1)
assert(testC("getparam r2, 2; getparam r3, 2; equal r2, r3", {}) == 1)
assert(testC("getparam r2, 2; getparam r3, 3; equal r2, r3",
             {}, {}) == 0)
assert(testC("getparam r2, 2; getparam r3, 3; equal r2, r3",
             print, 34) == 0)

f = testC("getparam r1, 2; pushreg r1; pushnum 8; closure testC, 2",
          "getparam r2, 2; getparam r3, 3; pushreg r2; pushreg r3")
a,b = f(4)
assert(a == 8 and b == 4)


-- testando lua_nextvar
X = nil
local a,b,c,d,e,f,g = testC[[
	getglobal	r2, X
	pushnum		9
	nextvar		r2
	getresult	r5, 1
	pop		r3
	pushnum		8
	getresult	r7, 2
	nextvar		r3
	pop		r4
	getresult	r6, 1
	pushreg		r3
	pushreg		r5
	pushreg		r4
	pushreg		r6
	getresult	r9, 2
	pushreg		r7
	pushreg		r9
]]

local x,y = nextvar(nil)
assert(a==x and b==x and e==y)
x,y = nextvar(x)
assert(c==x and d==x and f==y)
assert(not g)

foreachvar(function (n) X=n end)   -- get 'last' global var
local a,b = testC[[
	pushnum		7
	pushnum		8
	pushnum		9
	getglobal	r2, X
	nextvar		r2
	pop		r3
	pushreg		r3
	pushreg		r2
]]
assert(not a and b == X)

-- testando lua_next
X = {x="alo"}
local a,b,c,d = testC[[
	pushnum		0
	pop		r1
	rawgetglobal	r0, X
	pushnum		8
	next		r0, r1
	getresult	r5, 1
	getresult	r6, 2
	pop		r1
	pushnum		9
	next		r0, r1
	pop		r1
	pushreg		r1
	pushreg		r5
	pushreg		r6
]]
assert(a==0 and b=='x' and c=='alo' and d == nil)


testC('pushstring OK; call print')




-- function to show all string tables
function showstringtables ()
  local i = 1
  local n, s = querystr(i);
  while n do
    print("\n\t", n, s)
    local j=0
    while j<s do
      j=j+1
      local str = call(querystr, {i,j}, "p")
      tinsert(str, 1, j)
      call(print, str)
    end
    i = i+1
    n, s = querystr(i);
  end
end

--showstringtables()
$end
