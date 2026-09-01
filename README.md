# MAC Cell dla NPU (VHDL + Cocotb)

Projekt zawiera model RTL pojedynczej bloku IP implementującego jednostkę TPU m.in. ułatwiającą obliczenia w sieciach neuronowych.

Celem projektu jest przygotowanie modelu RTL do symulacji i weryfikacji funkcjonalnej. Stworzony model RTL zostanie wykorzystany do stworzenia implementacji w technologii UMC 28 nm.

---

## Struktura projektu

- **RTL/** – źródła w języku VHDL. Zawiera implementację wszystkich implementowanych modułów i podmodułów wykorzystywanych w projektcie. 
- **tests/** – środowisko testowe oparte na frameworku **cocotb**. Zawiera osobne katalogi testów modułów wraz z plikami `Makefile` i skryptami testowymi w Pythonie.  
- **wrappers/** – wrapper'y do wymulowanych modułów.  
- **.venv/** – (nie jest wersjonowany) lokalne środowisko Pythona używane do uruchamiania testów. 
---

## Wymagania

- Python 3.8 lub nowszy  
- Cocotb  
- Pytest
- Biblioteka `fixedpoint`  
- Symulator VHDL wspierany przez cocotb (np. NVC. GHDL nie wspiera w pełni VHDL-2008, który jest używany w tym projekcie)  
- Make

---

## Przygotowanie środowiska testowego (wersja dla Arch Linux, w prypadku innych dystrybucji należy skompilować symulator NVC ze źródeł)

```bash
# Instalacja Symulatora
yay -S nvc

# Klonowanie repozytorium
git clone https://github.com/pkorycki/mac-cell.git
cd mac-cell

# Utworzenie i aktywacja wirtualnego środowiska
python3 -m venv .venv
source .venv/bin/activate

# Instalacja zależności
pip install --upgrade pip
pip install cocotb pytest fixedpoint
```

# Uruchomienie testów
Każdy moduł posiada osobny zestaw testów w katalogu tests/. Uruchamiane są poprzez wywołanie pliku makefile w katalogu testowym.
Teści testów są zdefiniowane w plikach **tests.py**. Przykładowe uruchomienie testu:
```bash
cd tests/npu_mul_tests
make
```
