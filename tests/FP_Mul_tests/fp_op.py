from fixedpoint import FixedPoint

def fixed_mul(a: FixedPoint, b: FixedPoint) -> FixedPoint:
    """
    Mnoży dwie liczby stałoprzecinkowe o tym samym formacie.
    """
    if a.m != b.m or a.n != b.n:
        raise ValueError("Obie liczby muszą mieć ten sam format (m, n).")
    result = a * b
    return result

def fixed_to_int(fp: FixedPoint) -> int:
    """
    Zwraca surową reprezentację liczby stałoprzecinkowej jako int (bity).
    """
    raw_int = int(fp.bits)
    return raw_int


def int_to_fixed(value: int, int_bits: int, frac_bits: int, signed=True) -> FixedPoint:
    """
    Tworzy obiekt FixedPoint z surowego integera (bitów).
    """
    fp = FixedPoint(hex(value), m=int_bits, n=frac_bits, signed=signed)
    return fp

# if __name__ == "__main__":
#     # Przykład:  liczby 1.5 i 2.25 w formacie Q4.4 (4 bity całkowite + 4 ułamkowe)
#     a = FixedPoint(1.5, m=4, n=4, signed=True)
#     b = FixedPoint(2.25, m=4, n=4, signed=True)

#     print("a =", float(a), "→ raw int =", fixed_to_int(a))
#     print("b =", float(b), "→ raw int =", fixed_to_int(b))

#     c = fixed_mul(a, b)
#     print("\nWynik mnożenia:")
#     print("c =", float(c), "→ raw int =", fixed_to_int(c))

