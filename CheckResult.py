import numpy as np
import struct

def hex_to_number(hex):
    number = int(hex, 16)
    if(number>127):
        number = number - 256
    return number

def read_input_mem(fileName = "input_mem.csv", row=1024):
    shape = (row, 512)
    array = np.zeros(shape).astype(np.int8)
    with open(fileName, "r") as f:
        for i in range(row):
            for j in range(64):# 512/8
                for k in range(8):
                    tmpc = f.read(2)
                    array[i][8*j+k] = hex_to_number(tmpc)
                    # print(tmpc)
                    if k==7:
                        if f.read(1) != '\n':
                            print("read error")
    # print('reading matrix:\n',array)
    return array

def hex_to_number_2(hex):
    number = int(hex, 16)
    if(number>2**31-1):
        number = number - 2**32
    return number

def read_result_mem(fileName = "result_mem.csv"):
    arrays = [[np.zeros((16, 16)).astype(np.int64) for _ in range(32)] for _ in range(32)]
    with open(fileName, "r") as fp:
        for i in range(32):
            for j in range(32):
                for k in range(256):
                    hex_value = fp.read(8)
                    arrays[i][j][k//16, k%16] = hex_to_number_2(hex_value)
                    if k%2 == 1:
                        if fp.read(1) != '\n':
                            print("read error")
    array = np.block(arrays)
            
    # print('reading matrix:\n',array)
    return array

# main entry
def main():
    # get original input matrix
    array = read_input_mem(fileName = "input_mem.csv", row=1024)
    a1 = array[0:512,:]
    a2 = array[512:1024,:]

    # get computed results from Verilog
    correct_result = np.matrix(a1).astype(np.int64)*np.matrix(a2).astype(np.int64)
    print(f"a1:\n{a1}\na2:\n{a2}\ncorrect_result:\n{correct_result}")

    # check results is correct
    # result_array = np.zeros((512,512)) #tmp，请换成你的结果(下一行代码)
    result_array = read_result_mem(fileName = "result_mem.csv")
    print(f"my_result:\n{result_array}")
        
    loss = np.sum(np.square(correct_result-result_array)) #mean-square error
    relative_loss = np.sum(np.square(correct_result-result_array))/np.sum(np.square(correct_result)) #relative mean-square error
    print(f">>loss is {loss}\n>>relative_loss is {relative_loss}")

if __name__=="__main__": 
    main()
