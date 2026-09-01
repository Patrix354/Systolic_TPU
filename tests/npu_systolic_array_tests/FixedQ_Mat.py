import numpy as np
import random
from QFormat import QFormat, FixedQ

class FixedQ_Mat: 
    def __init__(self, arr_size, fmt):
        self.X = []
        self._arr_size = arr_size
        self.fmt = fmt

        for i in range(arr_size):
            self.X.append([self.fmt.from_float(0) for j in range(arr_size)])

    def _check_same_format(self, other: "FixedQ_Mat"):
        if not isinstance(other, FixedQ_Mat):
            raise TypeError("Operand musi być FixedQ_Mat")
        if (self._arr_size != other.size() or self.fmt != other.fmt):
            print(self._arr_size, other.size(), self.fmt, other.fmt)
            raise ValueError("Formaty Q macierzy muszą być takie same")

    def size(self):
        return self._arr_size    

    def disp(self):
        print("[", end="")
        for row in range(self._arr_size):
            print("[", end="")  
            for col in range(self._arr_size):
                if(col == self._arr_size-1):
                    print(self.X[row][col].to_float(), end="")
                else:
                    print(self.X[row][col].to_float(), end=", ")

            if(row == self._arr_size-1):
                print("]", end="")
            else:
                print("]", end=", \n")
        print("]\n")
    
    def fill_random(self, a, b):
        for i in range(self._arr_size):
            for j in range(self._arr_size):
                self.X[i][j] = self.fmt.from_float(random.uniform(a, b))

    def fill_ones(self):
        for i in range(self._arr_size):
            for j in range(self._arr_size):
                self.X[i][j] = self.fmt.from_float(1)

    def fill_zeros(self):
        for i in range(self._arr_size):
            for j in range(self._arr_size):
                self.X[i][j] = self.fmt.from_float(0)      

    def diag(self):
        self.fill_zeros()
        for i in range(self._arr_size):
            self.X[i][i] = self.fmt.from_float(1)

    def anti_diag(self):
        self.fill_zeros()
        for i in range(self._arr_size):
            self.X[i][self._arr_size-1-i] = self.fmt.from_float(1)

    def reverse_col_order(self):
        ret = FixedQ_Mat(self._arr_size, self.fmt)
        for row in range(self._arr_size):
            for col in range(self._arr_size):
                ret.X[row][col] = self.X[row][col]

        for row in range(self._arr_size):
            for col in range(self._arr_size):
                self.X[row][self._arr_size-1-col] = ret.X[row][col]

    def reverse_row_order(self):
        ret = FixedQ_Mat(self._arr_size, self.fmt)
        for row in range(self._arr_size):
            for col in range(self._arr_size):
                ret.X[row][col] = self.X[row][col]

        for row in range(self._arr_size):
            for col in range(self._arr_size):
                self.X[self._arr_size-1-row][col] = ret.X[row][col]

    def test_pattern(self):
        for i in range(self._arr_size):
            for j in range(self._arr_size):
                self.X[i][j] = self.fmt.from_float(i)

    def test_pattern2(self):
        for i in range(self._arr_size):
            for j in range(self._arr_size):
                self.X[i][j] = self.fmt.from_float(i*self._arr_size+j)

    def test_pattern3(self):
        self.fill_zeros()
        for i in range(self._arr_size):
            self.X[0][i] = self.fmt.from_float(1)

    def transpose(self):
        ret = FixedQ_Mat(self._arr_size, self.fmt)
        for row in range(self._arr_size):
            for col in range(self._arr_size):
                ret.X[row][col] = self.X[col][row]
        
        for row in range(self._arr_size):
            for col in range(self._arr_size):
                self.X[row][col] = ret.X[row][col]
                

    def __mul__(self, other):
        ret = FixedQ_Mat(self._arr_size, self.fmt)
        self._check_same_format(other)

        for col in range(self._arr_size):
            for row in range(self._arr_size):
                for i in range(self._arr_size):
                    ret.X[row][col] = ret.X[row][col] + self.X[row][i] * other.X[i][col]
        return ret

    def scale(self, scalar):
        for row in range(self._arr_size):
            for col in range(self._arr_size):
                self.X[row][col] = self.fmt.from_float(float(scalar)) * self.X[row][col]

    def __add__(self, other):
        ret = FixedQ_Mat(self._arr_size, self.fmt)
        self._check_same_format(other)

        for col in range(self._arr_size):
            for row in range(self._arr_size):
                ret.X[row][col] = self.X[row][col] + other.X[row][col]
        return ret

    def __eq__(self, other):
        ret = True
        if self.fmt != other.fmt:
            return False
        
        for col in range(self._arr_size):
            for row in range(self._arr_size):
                if self.X[row][col].uraw() != other.X[row][col].uraw():
                    ret = False
        return ret