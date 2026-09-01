class QFormat:
    def __init__(self, int_bits: int, frac_bits: int):
        if int_bits < 0 or frac_bits < 0:
            raise ValueError("Liczba bitów nie może być ujemna")
        self.int_bits = int_bits
        self.frac_bits = frac_bits
        self.total_bits = int_bits + frac_bits  # 1 bit znaku

        self.scale = 1 << frac_bits
        self.raw_min = -(1 << (self.total_bits - 1))
        self.raw_max = (1 << (self.total_bits - 1)) - 1

    def min_raw(self) -> int:
        return self.raw_min
    
    def max_raw(self) -> int:
        return self.raw_max

    def saturate(self, raw: int) -> int:
        return max(self.raw_min, min(self.raw_max, raw))

    def wrap(self, raw: int) -> int:
        mask = (1 << self.total_bits) - 1
        raw &= mask
        if raw & (1 << (self.total_bits - 1)):
            raw -= (1 << self.total_bits)
        return raw

    def from_float(self, value: float, saturate: bool = True) -> "FixedQ":
        raw = round(value * self.scale)
        if saturate:
            raw = self.saturate(raw)
        else:
            raw = self.wrap(raw)
        return FixedQ(raw, self)

    def from_raw(self, raw: int, saturate: bool = True) -> "FixedQ":
        if saturate:
            raw = self.saturate(raw)
        else:
            raw = self.wrap(raw)
        return FixedQ(raw, self)

    def min_value(self) -> float:
        return self.raw_min / self.scale

    def max_value(self) -> float:
        return self.raw_max / self.scale

    def __repr__(self):
        return f"QFormat(Q{self.int_bits}.{self.frac_bits}, total_bits={self.total_bits})"


class FixedQ:
    def __init__(self, raw: int, qfmt: QFormat):
        self.raw = int(raw)
        self.qfmt = qfmt

    def to_float(self) -> float:
        return self.raw / self.qfmt.scale

    def bin(self) -> str:
        value = self.to_twos_complement()
        return format(value, f"0{self.qfmt.total_bits}b")

    def hex(self) -> str:
        width = (self.qfmt.total_bits + 3) // 4
        value = self.to_twos_complement()
        return format(value, f"0{width}X")

    def uraw(self) -> int:
        uraw = self.bin()
        return int(uraw, 2)

    def to_twos_complement(self) -> int:
        if self.raw < 0:
            return (1 << self.qfmt.total_bits) + self.raw
        return self.raw

    def _check_same_format(self, other: "FixedQ"):
        if not isinstance(other, FixedQ):
            raise TypeError("Operand musi być FixedQ")
        if (self.qfmt.int_bits != other.qfmt.int_bits or
            self.qfmt.frac_bits != other.qfmt.frac_bits):
            raise ValueError("Formaty Q muszą być takie same")

    def __add__(self, other: "FixedQ") -> "FixedQ":
        self._check_same_format(other)
        raw = self.qfmt.saturate(self.raw + other.raw)
        return FixedQ(raw, self.qfmt)

    def __sub__(self, other: "FixedQ") -> "FixedQ":
        self._check_same_format(other)
        raw = self.qfmt.saturate(self.raw - other.raw)
        return FixedQ(raw, self.qfmt)

    def __neg__(self) -> "FixedQ":
        raw = self.qfmt.saturate(-self.raw)
        return FixedQ(raw, self.qfmt)

    def __mul__(self, other: "FixedQ") -> "FixedQ":
        self._check_same_format(other)
        product = self.raw * other.raw
        raw = product >> self.qfmt.frac_bits
        raw = self.qfmt.saturate(raw)
        return FixedQ(raw, self.qfmt)

    def __truediv__(self, other: "FixedQ") -> "FixedQ":
        self._check_same_format(other)
        if other.raw == 0:
            raise ZeroDivisionError("Dzielenie przez zero")
        dividend = self.raw << self.qfmt.frac_bits
        raw = int(dividend / other.raw)
        raw = self.qfmt.saturate(raw)
        return FixedQ(raw, self.qfmt)

    def resize(self, new_qfmt: QFormat, saturate: bool = True) -> "FixedQ":
        shift = new_qfmt.frac_bits - self.qfmt.frac_bits
        raw = self.raw

        if shift > 0:
            raw <<= shift
        elif shift < 0:
            raw >>= -shift

        if saturate:
            raw = new_qfmt.saturate(raw)
        else:
            raw = new_qfmt.wrap(raw)

        return FixedQ(raw, new_qfmt)

    def __repr__(self):
        return (
            f"FixedQ(value={self.to_float():.8f}, raw={self.raw}, "
            f"bin=0b{self.bin()}, format=Q{self.qfmt.int_bits}.{self.qfmt.frac_bits})"
        )