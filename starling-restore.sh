#!/bin/sh
# استعادة عوالم Starling من نسخة احتياطية في ~/starling-backups
# الاستخدام:  starling-restore.sh [اسم-النسخة|-f [اسم-النسخة]]
#   بدون وسيط (من طرفية تفاعلية): قائمة مرقمة تختار منها.
#   من طرفية غير تفاعلية: يطبع القائمة ويخرج.
#   ‎-f: تجاهل فحص "اللعبة شغّالة".

ROOT="$(cd "$(dirname "$0")" && pwd)"
BACKUPS="${STARLING_BACKUPS:-$HOME/starling-backups}"

FORCE=0
if [ "$1" = "-f" ]; then FORCE=1; shift; fi

# لا تستبدل العوالم واللعبة شغّالة (قد تكتب فوق ما نستعيد عليه).
if [ "$FORCE" -eq 0 ] && pgrep -x horizon-client >/dev/null 2>&1; then
    echo "اللعبة شغّالة الآن — أغلقها أولًا، أو مرّر ‎-f للتجاهل."
    exit 1
fi

# اختر النسخة: من الوسيط أو من قائمة.
if [ -n "$1" ]; then
    FILE="$1"
    [ -f "$FILE" ] || FILE="$BACKUPS/$1"
else
    if [ ! -t 0 ]; then
        echo "النسخ المتوفرة (الأحدث أولًا):"
        ls -1t "$BACKUPS"/*.tar.gz 2>/dev/null | nl -ba
        echo "الاستعمال: starling-restore.sh <اسم النسخة>"
        exit 0
    fi
    echo "النسخ المتوفرة (الأحدث أولًا):"
    ls -1t "$BACKUPS"/*.tar.gz 2>/dev/null | nl -ba
    printf 'رقم النسخة المراد استعادتها: '
    read -r N
    FILE=$(ls -1t "$BACKUPS"/*.tar.gz 2>/dev/null | sed -n "${N}p")
    [ -n "$FILE" ] || { echo "اختيار غير صالح."; exit 1; }
fi
[ -f "$FILE" ] || { echo "النسخة غير موجودة: $FILE"; exit 1; }

# شبكة أمان: احفظ العوالم الحالية قبل الاستبدال.
tar -czf "$BACKUPS/worlds-pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$ROOT" saves 2>/dev/null

echo "أستعيد من: $FILE"
tar -xzf "$FILE" -C "$ROOT"
echo "تمت الاستعادة ✓ — العوالم الحالية محفوظة في worlds-pre-restore-*.tar.gz"
echo "شغّل اللعبة من starling.sh"
