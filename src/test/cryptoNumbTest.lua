
print('\n\n')
print('CryptoNumber Test')

local CryptoNumber = require("CryptoNumber")
local n = CryptoNumber(5)
print("getValue:",n:getValue())
n._data = 10 -- Simulate modifying memory data
print("getValue:",n:getValue())
n:setValue(10.1)
print("getValue:",n:getValue())
n:setValue(10123.123)
print("getValue:",n:getValue())

