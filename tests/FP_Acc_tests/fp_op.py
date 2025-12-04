from fixedpoint import FixedPoint

def fixed_mul(a: FixedPoint, b: FixedPoint) -> FixedPoint:
    """
    Mnoży dwie liczby stałoprzecinkowe o tym samym formacie.
    """
    if a.m != b.m or a.n != b.n:
        raise ValueError("Obie liczby muszą mieć ten sam format (m, n).")
    result = a * b
    return result

def fixed_add(a: FixedPoint, b: FixedPoint) -> FixedPoint:
    """
    Mnoży dwie liczby stałoprzecinkowe o tym samym formacie.
    """
    if a.m != b.m or a.n != b.n:
        raise ValueError("Obie liczby muszą mieć ten sam format (m, n).")
    result = a + b
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