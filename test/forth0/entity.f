require: lib/core.f
require: lib/entity.f

# 16 entities: foo
# foo components: bar

16 ENTITY foo
  COMPONENT bar
END


10 [ foo entity:new! drop ] times

foo [ 42 swap >bar ] entity:each

foo [
  bar 42 = [ "failed" panic ] unless
] entity:each

0 bye
