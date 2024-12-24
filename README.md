# Super Mario Ruby

Prosta implementacja gry typu Mario stworzona w Ruby przy użyciu biblioteki Ruby2D.

## Opis
Gra jest prostą implementacją mechaniki platformowej, gdzie gracz może:
- Poruszać się w lewo i prawo
- Skakać na platformy
- Spaść w dziurę i zginąć

### Implementacja wymagań

#### Zrealizowane (3.0/5.0):
- ✅ 3.0  Należy stworzyć jeden poziom z przeszkodami oraz dziurami w które można wpaść i zginąć
- ✅ 3.5 Zbieranie punktów
- ✅ 4.0 Należy dodać przeciwników, których można zabić oraz 3 życia
- ✅ 4.5 Ładowanie poziomów z pliku

#### Niezrealizowane:
- ❌ 5.0 Generator poziomów

## Wymagania
- Ruby (zalecana wersja 2.7+)
- Biblioteka Ruby2D (0.12.1)

### Instalacja wymagań
1. Instalacja Ruby i niezbędnych narzędzi:
```bash
sudo apt-get update
sudo apt install ruby ruby-dev build-essential
```

2. Instalacja SDL (wymagane przez Ruby2D):
```bash
sudo apt install libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev
```

## Uruchomienie gry
```bash
ruby mario.rb
```

## Sterowanie
- Strzałka w lewo - ruch w lewo
- Strzałka w prawo - ruch w prawo
- Spacja - skok

## Dokumentacja techniczna

### Struktura projektu
Gra składa się z trzech głównych klas:
- `Game` - główna klasa zarządzająca grą
- `Player` - klasa odpowiedzialna za gracza i jego mechanikę
- `Platform` - klasa reprezentująca platformy

### Mechanika gry
- Fizyka grawitacji
- System kolizji
- Obsługa wejścia (klawiatura)
- System śmierci (wpadnięcie w dziurę)
