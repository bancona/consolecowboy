def convertCoordinatesToIndex(x, y):
  x = int(x)
  y = int(y)

  c = 1
  index = 0

  while x != 0 or y != 0:
    if x & 1:
      index |= c
    c <<= 1
    x >>= 1
    if y & 1:
      index |= c
    c <<= 1
    y >>= 1

  return index

def convertIndexToCoordinates(index):
  x = 0
  y = 0

  counter = 1
  while counter <= index:
    y |= (counter & index)
    index >>= 1
    x |= (counter & index)
    counter <<= 1

  return [x, y]

for i in range(20):
  for j in range(5):
    print("(",i,", ",j,")",convertCoordinatesToIndex(i, j))

for i in range(16):
  print(i, convertIndexToCoordinates(i))