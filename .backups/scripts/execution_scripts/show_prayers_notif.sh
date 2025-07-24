#!/usr/bin/env bash                                                                                        

LAT=36.5731                                                                                                
LON=10.6722                                                                                                

RAW=$(prayer-times --latitude "$LAT" --longitude "$LON" list-prayers | tail -n +2)                         

# حذف كلمة "Adhan" و"at" والثواني من الوقت
CLEANED=$(echo "$RAW" | sed -E 's/Adhan //g' | sed -E 's/ at //g' | sed -E 's/([0-9]{2}:[0-9]{2}):[0-9]{2}/\1/g')                                                                                                     

# استبدال أسماء الصلوات بالإنجليزية بالعربية
ARABIC_RAW=$(echo "$CLEANED" | sed -e 's/Fajr/ﺎﻠﻔﺟﺭ/' \
                                 -e 's/Dhuhr/ﺎﻠﻈﻫﺭ/' \
                                 -e 's/Asr/ﺎﻠﻌﺻﺭ/' \
                                 -e 's/Maghrib/ﺎﻠﻤﻏﺮﺑ/' \
                                 -e 's/Isha/ﺎﻠﻌﺷﺍﺀ/')

# تنسيق الأعمدة بعرض ثابت 12 خانة للاسم والوقت بعدها
#ARABIC_TIMES=$(echo "$ARABIC_RAW" | awk '{printf "%-12s %s\n", $1, $2}')
ARABIC_TIMES=$(echo "$ARABIC_RAW" | awk '{printf "%s\u2800\u2800%s\n", $1, $2}')





if [ -z "$ARABIC_TIMES" ]; then                                                                            
  notify-send "⚠️ ﺃﻮﻗﺎﺗ ﺎﻠﺻﻻﺓ" "ﻞﻣ ﻲﺘﻣ ﺎﻠﺤﺻﻮﻟ ﻊﻟﻯ ﺃﻮﻗﺎﺗ ﺎﻠﺻﻻﺓ"                                             
  exit 1                                                                                                   
fi                                                                                                         

notify-send "🕌 ﺃﻮﻗﺎﺗ ﺎﻠﺻﻻﺓ (ﺱﻮﻠﻴﻣﺎﻧ)" "<tt>$ARABIC_TIMES</tt>"

