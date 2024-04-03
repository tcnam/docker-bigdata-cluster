#%%
import sys
x:list=[1,2]
y:list=x

print(id(x))
print(id(y))

for i in range (0, 1000, 1):
    x.append(i)

print(id(x))
print(id(y))

print(sys.getrefcount(x))
print(sys.getrefcount(y))

a=1000
b=499+501
print(x is y)

s1:str="Real Python!"
s2:str="Real Python!"
print(s1 is s2)