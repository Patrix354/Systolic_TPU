# MAC Cell dla NPU (VHDL + Cocotb)

Projekt zawiera model RTL pojedynczej komórki MAC (Multiply–Accumulate) przeznaczonej do wykorzystania w jednostce NPU (Neural Processing Unit).  
Docelowo wiele takich komórek ma być połączonych w strukturę opartą o NoC (Network-on-Chip).

Celem projektu jest przygotowanie modelu RTL do symulacji i weryfikacji funkcjonalnej. Stworzony model RTL zostanie wykorzystany do stworzenia implementacji w technologii UMC 28 nm.

---

## Struktura projektu

- **RTL/** – źródła w języku VHDL. Zawiera implementację wszystkich implementowanych modułów i podmodułów wykorzystywanych w projektcie. 
- **tests/** – środowisko testowe oparte na frameworku **cocotb**. Zawiera osobne katalogi testów modułów wraz z plikami `Makefile` i skryptami testowymi w Pythonie.  
- **venv/** – (nie jest wersjonowany) lokalne środowisko Pythona używane do uruchamiania testów.  

---

## Wymagania

- Python 3.8 lub nowszy  
- Cocotb  
- Biblioteka `fixedpoint`  
- Symulator VHDL wspierany przez cocotb (np. GHDL)  
- Make

---

## Przygotowanie środowiska testowego

```bash
# Klonowanie repozytorium
git clone https://github.com/pkorycki/mac-cell.git
cd mac-cell

# Utworzenie i aktywacja wirtualnego środowiska
python3 -m venv .venv
source .venv/bin/activate


# Instalacja zależności
pip install --upgrade pip
pip install cocotb fixedpoint
```

# Uruchomienie testów
Każdy moduł posiada osobny zestaw testów w katalogu tests/. Uruchamiane są poprzez wywołanie pliku makefile w katalogu testowym.