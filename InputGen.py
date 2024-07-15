import numpy as np

# params
np.random.seed(1023)
sparsity = 0.35

# convert a signed INT8 number to hexidemical string
def number_to_hex(number):
    if number < 0:
        # convert to two's complement
        number = 256 + number
    return hex(number)[2:].zfill(2)

# create a signed INT8 numpy array with sparsity of 15% and shape of (1000, 1000)
shape = (1024, 512)
array = np.random.randint(0, 256, size=shape).astype(np.int8)
# set values to 0 with 10% probability
array[np.random.rand(*shape) < sparsity] = 0
print(array)

with open("input_mem.csv", "w") as f:
    for i in range(1024):
        for j in range(64):# 512/8
            for k in range(8):
                f.write(f"{number_to_hex(array[i][8*j+k])}")
            f.write("\n")
