#!/bin/bash
export PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

echo -e "\e[1;36mПроверка снаряжения...\e[0m"
MISSING=0
for cmd in python3 bc curl; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "\e[1;31m✗ $cmd не найден. Установи: sudo pacman -S $cmd (или аналог)\e[0m"
        MISSING=1
    fi
done
if [ $MISSING -eq 1 ]; then
    echo -e "\e[1;31mДоустанови недостающие программы и возвращайся!\e[0m"
    exit 1
fi
echo -e "\e[1;32m✓ Всё на месте! Погнали на рыбалку\e[0m\n"

CACHE_DIR="/tmp/fish_hub_cache"
mkdir -p "$CACHE_DIR"

echo -e "\e[1;36mВыбирай точку заброса:\e[0m"
echo "1) Астрахань    2) Уфа          3) Салават      4) Стерлитамак"
echo "5) Бирск        6) Екб          7) Янган-Тау    8) Челябинск"
echo "9) Казань       10) Самара      11) Питер       12) Мурманск"
echo "13) Тюмень      14) Сургут      15) Новосибирск 16) Красноярск"
echo -ne "\e[1;36mНомер: \e[0m"
read CITY_NUM < /dev/tty

case $CITY_NUM in
    1) NAME="Астрахань"; LAT="46.34"; LON="48.04" ;;
    2) NAME="Уфа"; LAT="54.74"; LON="55.96" ;;
    3) NAME="Салават"; LAT="53.36"; LON="55.92" ;;
    4) NAME="Стерлитамак"; LAT="53.63"; LON="55.94" ;;
    5) NAME="Бирск"; LAT="55.42"; LON="55.53" ;;
    6) NAME="Екатеринбург"; LAT="56.85"; LON="60.61" ;;
    7) NAME="Янган-Тау"; LAT="55.30"; LON="58.13" ;;
    8) NAME="Челябинск"; LAT="55.15"; LON="61.43" ;;
    9) NAME="Казань"; LAT="55.79"; LON="49.12" ;;
    10) NAME="Самара"; LAT="53.20"; LON="50.15" ;;
    11) NAME="Санкт-Петербург"; LAT="59.93"; LON="30.33" ;;
    12) NAME="Мурманск"; LAT="68.97"; LON="33.08" ;;
    13) NAME="Тюмень"; LAT="57.15"; LON="65.52" ;;
    14) NAME="Сургут"; LAT="61.25"; LON="73.41" ;;
    15) NAME="Новосибирск"; LAT="55.00"; LON="82.93" ;;
    16) NAME="Красноярск"; LAT="56.01"; LON="92.86" ;;
    *) NAME="Стерлитамак"; LAT="53.63"; LON="55.94" ;;
esac

P1="https://api.open-meteo.com/v1/forecast?latitude=${LAT}"
P2="&longitude=${LON}&current=temperature_2m,surface_pressure,wind_speed_10m,wind_direction_10m,is_day,cloud_cover&wind_speed_unit=kmh"
URL="${P1}${P2}"

DATA=$(curl -s "$URL")

TEMP=$(python3 -c "import sys, json; d=json.loads(sys.stdin.read()); print(d['current']['temperature_2m'])" <<< "$DATA" | xargs)
PRES_NOW=$(python3 -c "import sys, json; d=json.loads(sys.stdin.read()); print(d['current']['surface_pressure'])" <<< "$DATA" | xargs)
WIND_SPD=$(python3 -c "import sys, json; d=json.loads(sys.stdin.read()); print(d['current']['wind_speed_10m'])" <<< "$DATA" | xargs)
WIND_DEG=$(python3 -c "import sys, json; d=json.loads(sys.stdin.read()); print(d['current']['wind_direction_10m'])" <<< "$DATA" | xargs)
CLOUDS=$(python3 -c "import sys, json; d=json.loads(sys.stdin.read()); print(d['current']['cloud_cover'])" <<< "$DATA" | xargs)
IS_DAY=$(python3 -c "import sys, json; d=json.loads(sys.stdin.read()); print(d['current']['is_day'])" <<< "$DATA" | xargs)

if [ $WIND_DEG -gt 225 ] && [ $WIND_DEG -le 315 ]; then W_DIR="Западный"
elif [ $WIND_DEG -gt 135 ] && [ $WIND_DEG -le 225 ]; then W_DIR="Южный"
elif [ $WIND_DEG -gt 45 ] && [ $WIND_DEG -le 135 ]; then W_DIR="Восточный"
else W_DIR="Северный"
fi

if [ $CLOUDS -gt 70 ]; then SKY="Пасмурно"
elif [ $CLOUDS -gt 30 ]; then SKY="Облачно"
else SKY="Ясно"
fi

H=$(date +%H)
CACHE_FILE="$CACHE_DIR/${LAT}_${LON}.pres"
[ -f "$CACHE_FILE" ] && PRES_OLD=$(cat "$CACHE_FILE" | xargs) || PRES_OLD=$PRES_NOW
echo "$PRES_NOW" > "$CACHE_FILE"

DIFF=$(echo "$PRES_NOW - $PRES_OLD" | bc)
[ -z "$DIFF" ] && DIFF=0

CONTENT="  $NAME | $TEMP°C | $SKY | Ветер: $W_DIR ($WIND_SPD км/ч)"
WIDTH=75
TOP_LINE=$(printf '%.0s═' $(seq 1 $WIDTH))
echo -e "\n\e[1;34m╔${TOP_LINE}╗\e[0m"
echo -ne "\e[1;34m║\e[1;37m$CONTENT\033[77G\e[1;34m║\e[0m\n"
echo -e "\e[1;34m╚${TOP_LINE}╝\e[0m"

#1.Щука
if (( $(echo "$DIFF < 0" | bc -l) )) || [[ "$SKY" == "Пасмурно" ]]; then
    echo -e "\e[1;32m Щука:\e[0m Мамка охотится! Руки в ноги пшел на реку! \e[1;30m> Приманка:\e[0m Воблеры минноу. \e[1;30mТактика:\e[0m Агрессивный твичинг."
else
    echo -e "\e[1;32m Щука:\e[0m Мамка спит... На нее не вариант идти седня. \e[1;30m> Приманка:\e[0m Силикон. \e[1;30mТактика:\e[0m Медленная проводка."
fi
#2.Судак
if (( $(echo "$PRES_NOW > 1014" | bc -l) )) && [ $IS_DAY -eq 0 ]; then
    echo -e "\e[1;36m Судак:\e[0m Этот уже ждет блесны! \e[1;30m> Приманка:\e[0m Тяжелый джиг. \e[1;30mТактика:\e[0m Ступенька."
else
    echo -e "\e[1;36m Судак:\e[0m Он вчера выпил много — спит. \e[1;30m> Приманка:\e[0m Слаги. \e[1;30mТактика:\e[0m Волочение."
fi
#3.Окунь
if (( $(echo "$PRES_NOW > 1012" | bc -l) )) && [[ "$SKY" == "Ясно" ]]; then
    echo -e "\e[1;33m Окунь:\e[0m Полосатый седня дает жару! \e[1;30m> Приманка:\e[0m Попперы. \e[1;30mТактика:\e[0m Быстрая игра."
else
    echo -e "\e[1;33m Окунь:\e[0m Полосатик прикинулся сдохшим. \e[1;30m> Оснастка:\e[0m Отводной поводок. \e[1;30mТактика:\e[0m Деликатная игра."
fi
#4.Сазан
if (( $(echo "$TEMP > 15" | bc -l) )) && [[ "$W_DIR" == "Южный" ]]; then
    echo -e "\e[1;33m Сазан:\e[0m Этот в режиме пылесоса морского! \e[1;30m> Приманка:\e[0m Бойлы. \e[1;30mТактика:\e[0m Обильный закорм."
else
    echo -e "\e[1;33m Сазан:\e[0m Спит красавец во гробу.... \e[1;30m> Приманка:\e[0m Мелкий поп-ап. \e[1;30mТактика:\e[0m Поиск в ямах."
fi
#5.Лещ
if (( $(echo "$DIFF == 0" | bc -l) )); then
    echo -e "\e[1;37m Лещ:\e[0m Ждет прикормки! \e[1;30m> Приманка:\e[0m Червь. \e[1;30mОснастка:\e[0m Объемная насадка."
else
    echo -e "\e[1;37m Лещ:\e[0m Если и будет сегодня лещ — то точно не в виде рыбы. \e[1;30m> Приманка:\e[0m Мотыль. \e[1;30mОснастка:\e[0m Тонкие поводки."
fi
#6.Карась
if (( $(echo "$TEMP > 12" | bc -l) )); then
    echo -e "\e[1;32m Карась:\e[0m Ждет твоих бойлов! \e[1;30m> Приманка:\e[0m Перловка. \e[1;30mТактика:\e[0m Ловля в окнах травы."
else
    echo -e "\e[1;32m Карась:\e[0m Зарылся в ил и грустит. \e[1;30m> Приманка:\e[0m Мотыль. \e[1;30mОснастка:\e[0m Легкий поплавок."
fi
#7.Сом
if [ $IS_DAY -eq 0 ]; then
    echo -e "\e[1;35m Сом:\e[0m Этот седня просто зверь! \e[1;30m> Приманка:\e[0m Выползок. \e[1;30mТактика:\e[0m Выходы из ям."
else
    echo -e "\e[1;35m Сом:\e[0m Спят усталые сомики, сомик спит..."
fi
echo -e "\e[1;34m--------------------------------------------------------\e[0m"
