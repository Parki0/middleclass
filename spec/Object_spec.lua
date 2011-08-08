require 'middleclass'

context('Object', function()

  context('name', function()
    test('is correctly set', function()
      assert_equal(Object.name, 'Object')
    end)
  end)

  context('tostring', function()
    test('returns "class Object"', function()
      assert_equal(tostring(Object), 'class Object')
    end)
  end)

  context('instance creation', function()

    local MyClass

    before(function()
      MyClass = Object:subclass('MyClass')
      function MyClass:initialize() self.mark=true end
    end)

    context('allocate', function()

      test('allocates instances properly', function()
        local instance = MyClass:allocate()
        assert_equal(instance.class, MyClass)
      end)

      test('throws an error when used without the :', function()
        assert_error(Object.allocate)
      end)

      test('does not call the initializer', function()
        local allocated = MyClass:allocate()
        assert_nil(allocated.mark)
      end)

      test('can be overriden', function()
        function MyClass.static:allocate()
          local instance = Object:allocate()
          instance.mark = true
          return instance
        end

        local allocated = MyClass:allocate()
        assert_true(allocated.mark)
      end)

    end)

    context('new', function()

      test('initializes instances properly', function()
        local instance = MyClass:new()
        assert_equal(instance.class, MyClass)
      end)

      test('throws an error when used without the :', function()
        assert_error(MyClass.new)
      end)

      test('calls the initializer', function()
        local allocated = MyClass:new()
        assert_true(allocated.mark)
      end)

    end)

  end)

  context('subclass', function()

    test('throws an error when used without the :', function()
      assert_error(function() Object.subclass() end)
    end)

    context('when given a class name', function()

      local MyClass = Object:subclass('MyClass')

      test('it returns a class with the correct name', function()
        assert_equal(MyClass.name, 'MyClass')
      end)

      test('it returns a class with the correct superclass', function()
        assert_equal(MyClass.superclass, Object)
      end)
    end)

    context('when no name is given', function()
      test('it throws an error', function()
        assert_error( function() Object:subclass() end)
      end)
    end)

  end)

end)

context('An instance attribute', function()

  local Person

  before(function()
    Person = class('Person')
    function Person:initialize(name)
      self.name = name
    end
  end)

  test('is available in the instance after being initialized', function()
    local bob = Person:new('bob')
    assert_equal(bob.name, 'bob')
  end)
  
  test('is available in the instance after being initialized by a superclass', function()
    local AgedPerson = class('AgedPerson', Person)
    function AgedPerson:initialize(name, age)
      Person.initialize(self, name)
      self.age = age
    end

    local pete = AgedPerson:new('pete', 31)
    assert_equal(pete.name, 'pete')
    assert_equal(pete.age, 31)
  end)

end)

context('An instance method', function()

  local A, B, a, b

  before(function()
    A = class('A')
    function A:overridden() return 'foo' end
    function A:regular() return 'regular' end
    
    B = class('B', A)
    function B:overridden() return 'bar' end
    
    a = A:new()
    b = B:new()
  end)

  test('should be available for any instance', function()
    assert_equal(a:overridden(), 'foo')
  end)
  
  test('should be inheritable', function()
    assert_equal(b:regular(), 'regular')
  end)
  
  test('should be overridable', function()
    assert_equal(b:overridden(), 'bar')
  end)

end)

context('A class attribute', function()

  local A, B

  before(function()
    A = class('A')
    A.static.foo = 'foo'

    B = class('B', A)
  end)

  test('should be available after being initialized', function()
    assert_equal(A.foo, 'foo')
  end)

  test('should be available for subclasses', function()
    assert_equal(B.foo, 'foo')
  end)
  
  test('should be overridable by subclasses, without affecting the superclasses', function()
    B.foo = 'chunky bacon'
    assert_equal(B.foo, 'chunky bacon')
    assert_equal(A.foo, 'foo')
  end)

end)

context('A class method', function()

  local A, B

  before(function()
    A = class('A')
    function A.foo(theClass) return 'foo' end

    B = class('B', A)
  end)

  test('should be available after being initialized', function()
    assert_equal(A:foo(), 'foo')
  end)

  test('should be available for subclasses', function()
    assert_equal(B:foo(), 'foo')
  end)
  
  test('should be overridable by subclasses, without affecting the superclasses', function()
    function B.foo(theClass) return 'chunky bacon' end
    assert_equal(B:foo(), 'chunky bacon')
    assert_equal(A:foo(), 'foo')
  end)

end)

--[[
  context('A Mixin', function()

    local Class1 = class('Class1')
    local Mixin = {}
    function Mixin:included(theClass) theClass.includesMixin = true end
    function Mixin:foo() return 'foo' end
    function Mixin:bar() return 'bar' end
    Class1:include(Mixin)

    Class2 = class('Class2', Class1)
    function Class2:foo() return 'baz' end

    test('should invoke the "included" method when included', function()
      assert_true(Class1.includesMixin)
    end)
    
    test('should have all its functions (except "included") copied to its target class', function()
      assert_equal(Class1:foo(), 'foo')
      assert_equal(Class1.included, nil)
    end)
    
    test('should make its functions available to subclasses', function()
      assert_equal(Class2:bar(), 'bar')
    end)
    
    test('should allow overriding of methods on subclasses', function()
      assert_equal(Class2:foo(), 'baz')
    end)

  end)
  
  context('Metamethods', function()
    
    test('__index should throw an error', function()
      local NonIndexable = class('NonIndexable')
      
      assert_error(function() function NonIndexable:__index(name) end end)
    end)

    context('Custom Metamethods', function()
      -- Tests all metamethods. Note that __len is missing (lua makes table length unoverridable)
      -- I'll use a() to note the length of vector "a" (I would have preferred to use #a, but it's not possible)
      -- I'll be using 'a' instead of 'self' on this example since it is shorter
      local Vector= class('Vector')
      function Vector.initialize(a,x,y,z) a.x, a.y, a.z = x,y,z end
      function Vector.__tostring(a) return a.class.name .. '[' .. a.x .. ',' .. a.y .. ',' .. a.z .. ']' end
      function Vector.__eq(a,b)     return a.x==b.x and a.y==b.y and a.z==b.z end
      function Vector.__lt(a,b)     return a() < b() end
      function Vector.__le(a,b)     return a() <= b() end
      function Vector.__add(a,b)    return Vector:new(a.x+b.x, a.y+b.y ,a.z+b.z) end
      function Vector.__sub(a,b)    return Vector:new(a.x-b.x, a.y-b.y, a.z-b.z) end
      function Vector.__div(a,s)    return Vector:new(a.x/s, a.y/s, a.z/s) end
      function Vector.__unm(a)      return Vector:new(-a.x, -a.y, -a.z) end
      function Vector.__concat(a,b) return a.x*b.x+a.y*b.y+a.z*b.z end
      function Vector.__call(a)     return math.sqrt(a.x*a.x+a.y*a.y+a.z*a.z) end
      function Vector.__pow(a,b)
        return Vector:new(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)
      end
      function Vector.__mul(a,b)
        if type(b)=="number" then return Vector:new(a.x*b, a.y*b, a.z*b) end
        if type(a)=="number" then return Vector:new(a*b.x, a*b.y, a*b.z) end
      end

      local a = Vector:new(1,2,3)
      local b = Vector:new(2,4,6)

      for metamethod,values in pairs({
        __tostring = { tostring(a), "Vector[1,2,3]" },
        __eq =       { a,    a},
        __lt =       { a<b,  true },
        __le =       { a<=b, true },
        __add =      { a+b,  Vector(3,6,9) },
        __sub =      { b-a,  Vector(1,2,3) },
        __div =      { b/2,  Vector(1,2,3) },
        __unm =      { -a,   Vector(-1,-2,-3) },
        __concat =   { a..b, 28 },
        __call =     { a(), math.sqrt(14) },
        __pow =      { a^b,  Vector(0,0,0) },
        __mul =      { 4*a,  Vector(4,8,12) }--,
        --__index =    { b[1], 3 }
      }) do
        test(metamethod .. ' should work', function()
          assert_equal(values[1], values[2])
        end)
      end
      
      context('Inherited Metamethods', function()
        local Vector2= class('Vector2', Vector)
        function Vector2:initialize(x,y,z) Vector.initialize(self,x,y,z) end
        
        local c = Vector2:new(1,2,3)
        local d = Vector2:new(2,4,6)
        for metamethod,values in pairs({
          __tostring = { tostring(c), "Vector2[1,2,3]" },
          __eq =       { c, c },
          __lt =       { c<d,  true },
          __le =       { c<=d, true },
          __add =      { c+d,  Vector(3,6,9) },
          __sub =      { d-c,  Vector(1,2,3) },
          __div =      { d/2,  Vector(1,2,3) },
          __unm =      { -c,   Vector(-1,-2,-3) },
          __concat =   { c..d, 28 },
          __call =     { c(), math.sqrt(14) },
          __pow =      { c^d,  Vector(0,0,0) },
          __mul =      { 4*c,  Vector(4,8,12) }
        }) do
          test(metamethod .. ' should work', function()
            assert_equal(values[1], values[2])
          end)
        end
      end)
      
    end)

    context('Default Metamethods', function() 
      local Peter = class('Peter')
      local peter = Peter()
      
      context('A Class', function()
        test('should have a tostring metamethod', function()
          assert_equal(tostring(Peter), 'class Peter')
        end)
        test('should have a call metamethod', function()
          assert_true(instanceOf(Peter, peter))
        end)
      end)

      context('An instance', function()
        test('should have a tostring metamethod, different from Object.__tostring', function()
          assert_not_equal(Peter.__tostring, Object.__tostring)
          assert_equal(tostring(peter), 'instance of Peter')
        end)
      end)
    end)
 
  end)

end)




context('includes', function()

  context('Primitives', function()
    local o = Object:new()
    local primitives = {nil, 1, 'hello', {}, function() end}
    
    for _,primitive in pairs(primitives) do
      local theType = type(primitive)
      context('A ' .. theType, function()
        
        local f1 = function() return includes(Object, primitive) end
        local f2 = function() return includes(primitive, o) end
        local f3 = function() return includes(primitive, primitive) end
        
        context('should not throw errors', function()
          test('includes(Object, '.. theType ..')', function()
            assert_not_error(f1)
          end)
          test('includes(' .. theType .. ', Object:new())', function()
            assert_not_error(f2)
          end)
          test('includes(' .. theType .. ',' .. theType ..')', function()
            assert_not_error(f3)
          end)
        end)
        
        test('should make includes return false', function()
          assert_false(f1())
          assert_false(f2())
          assert_false(f3())
        end)

      end)
    end -- for

  end)

  context('A class', function()

    local Class1 = class('Class1')
    local Class2 = class('Class2', Class1)
    local Class3 = class('Class3', Class2)
    local UnrelatedClass = class('Unrelated')
    
    local hasFoo = { foo=function() return 'foo' end }
    Class1:include(hasFoo)
    
    test('should return true if it includes a mixin', function()
      assert_true(includes(hasFoo, Class1))
    end)
    
    test('should return true if its superclass includes a mixin', function()
      assert_true(includes(hasFoo, Class2))
      assert_true(includes(hasFoo, Class3))
    end)
    
    test('should return false otherwise', function()
      assert_false(includes(hasFoo, UnrelatedClass))
    end)

  end)

end)

context('instanceOf', function()

  context('Primitives', function()
    local o = Object:new()
    local primitives = {nil, 1, 'hello', {}, function() end}
    
    for _,primitive in pairs(primitives) do
      local theType = type(primitive)
      context('A ' .. theType, function()
        
        local f1 = function() return instanceOf(Object, primitive) end
        local f2 = function() return instanceOf(primitive, o) end
        local f3 = function() return instanceOf(primitive, primitive) end
        
        context('should not throw errors', function()
          test('instanceOf(Object, '.. theType ..')', function()
            assert_not_error(f1)
          end)
          test('instanceOf(' .. theType .. ', Object:new())', function()
            assert_not_error(f2)
          end)
          test('instanceOf(' .. theType .. ',' .. theType ..')', function()
            assert_not_error(f3)
          end)
        end)
        
        test('should make instanceOf return false', function()
          assert_false(f1())
          assert_false(f2())
          assert_false(f3())
        end)

      end)
    end -- for

  end)

  context('An instance', function()
    local Class1 = class('Class1')
    local Class2 = class('Class2', Class1)
    local Class3 = class('Class3', Class2)
    local UnrelatedClass = class('Unrelated')
    
    local o1, o2, o3 = Class1:new(), Class2:new(), Class3:new()
    
    test('should be instanceOf(Object)', function()
      assert_true(instanceOf(Object, o1))
      assert_true(instanceOf(Object, o2))
      assert_true(instanceOf(Object, o3))
    end)
    
    test('should be instanceOf its class', function()
      assert_true(instanceOf(Class1, o1))
      assert_true(instanceOf(Class2, o2))
      assert_true(instanceOf(Class3, o3))
    end)
    
    test('should be instanceOf its class\' superclasses', function()
      assert_true(instanceOf(Class1, o2))
      assert_true(instanceOf(Class1, o3))
      assert_true(instanceOf(Class2, o3))
    end)
    
    test('should not be an instanceOf its class\' subclasses', function()
      assert_false(instanceOf(Class2, o1))
      assert_false(instanceOf(Class3, o1))
      assert_false(instanceOf(Class3, o2))
    end)
    
    test('should not be an instanceOf an unrelated class', function()
      assert_false(instanceOf(UnrelatedClass, o1))
      assert_false(instanceOf(UnrelatedClass, o2))
      assert_false(instanceOf(UnrelatedClass, o3))
    end)

  end)


end)


context('subclassOf', function()

  context('Primitives', function()
    local primitives = {nil, 1, 'hello', {}, function() end}
    
    for _,primitive in pairs(primitives) do
      local theType = type(primitive)
      context('A ' .. theType, function()
        
        local f1 = function() return subclassOf(Object, primitive) end
        local f2 = function() return subclassOf(primitive, o) end
        local f3 = function() return subclassOf(primitive, primitive) end
        
        context('should not throw errors', function()
          test('subclassOf(Object, '.. theType ..')', function()
            assert_not_error(f1)
          end)
          test('subclassOf(' .. theType .. ', Object:new())', function()
            assert_not_error(f2)
          end)
          test('subclassOf(' .. theType .. ',' .. theType ..')', function()
            assert_not_error(f3)
          end)
        end)
        
        test('should make subclassOf return false', function()
          assert_false(f1())
          assert_false(f2())
          assert_false(f3())
        end)

      end)
    end

  end)
  
  context('Any class (except Object)', function()
    local Class1 = class('Class1')
    local Class2 = class('Class2', Class1)
    local Class3 = class('Class3', Class2)
    local UnrelatedClass = class('Unrelated')
    
    test('should be subclassOf(Object)', function()
      assert_true(subclassOf(Object, Class1))
      assert_true(subclassOf(Object, Class2))
      assert_true(subclassOf(Object, Class3))
    end)
    
    test('should be subclassOf its direct superclass', function()
      assert_true(subclassOf(Class1, Class2))
      assert_true(subclassOf(Class2, Class3))
    end)
    
    test('should be subclassOf its ancestors', function()
      assert_true(subclassOf(Class1, Class3))
    end)
    
    test('should not be an subclassOf its class\' subclasses', function()
      assert_false(subclassOf(Class2, Class1))
      assert_false(subclassOf(Class3, Class1))
      assert_false(subclassOf(Class3, Class2))
    end)
    
    test('should not be an subclassOf an unrelated class', function()
      assert_false(subclassOf(UnrelatedClass, Class1))
      assert_false(subclassOf(UnrelatedClass, Class2))
      assert_false(subclassOf(UnrelatedClass, Class3))
    end)

  end)

end)
]]


