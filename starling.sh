#!/bin/sh
# Starling (Horizon Rust client) — native launcher.
# Must run from the repo root: the client reads its prepared resources
# from .local/horizon-client/26.3 relative to the working directory.

ROOT="$(cd "$(dirname "$0")" && pwd)"
BIN="$ROOT/target/release/horizon-client"
BACKUPS="${STARLING_BACKUPS:-$HOME/starling-backups}"

cd "$ROOT" || { echo "خطأ: مجلد اللعبة $ROOT غير موجود" >&2; exit 1; }

# الثنائي يجب أن يكون موجودًا وقابلًا للتنفيذ قبل أي شيء.
if [ ! -x "$BIN" ]; then
    echo "خطأ: البرنامج $BIN غير موجود." >&2
    echo "أعد بناءه بـ: cd $ROOT && cargo build --release -p horizon-client" >&2
    exit 1
fi

# لا تفتح نسختين من اللعبة — ارفع النافذة الموجودة واخرج.
if pgrep -x horizon-client >/dev/null 2>&1; then
    echo "اللعبة شغّالة بالفعل — أرفع نافذتها بدل فتح نسخة ثانية."
    DISPLAY="${DISPLAY:-:0}" wmctrl -x -a horizon.horizon 2>/dev/null
    exit 0
fi

# نسخة احتياطية قبل كل تشغيل (نحتفظ بآخر 8) + نسخة يومية واحدة (آخر 14 يومًا).
if [ -d saves ] && [ -n "$(ls -A saves 2>/dev/null)" ]; then
    mkdir -p "$BACKUPS"
    tar -czf "$BACKUPS/worlds-launch-$(date +%Y%m%d-%H%M%S).tar.gz" -C "$ROOT" saves 2>/dev/null
    ls -1t "$BACKUPS"/worlds-launch-*.tar.gz 2>/dev/null | tail -n +9 | xargs -r rm -f
    DAILY="$BACKUPS/worlds-daily-$(date +%Y%m%d).tar.gz"
    [ -f "$DAILY" ] || tar -czf "$DAILY" -C "$ROOT" saves 2>/dev/null
    ls -1t "$BACKUPS"/worlds-daily-*.tar.gz 2>/dev/null | tail -n +15 | xargs -r rm -f
fi

# الصوت: PipeWire + عميل ALSA مباشر — latency أكبر يمنع التشويش (underruns).
PIPEWIRE_LATENCY=256/48000
export PIPEWIRE_LATENCY

# سجل إطلاق العميل (stdout/stderr) — يُسجل كل تشغيل ويُحتفظ بآخر 5 سجلات.
LOGDIR="$ROOT/.local/starling-launch-logs"
mkdir -p "$LOGDIR"
LOG="$LOGDIR/launch-$(date +%Y%m%d-%H%M%S).log"
ls -1t "$LOGDIR"/launch-*.log 2>/dev/null | tail -n +6 | xargs -r rm -f

# اللعبة يجب أن تشتغل من هذا المجلد — exec يحافظ على المسار والوسائط.
exec "$BIN" "$@" >>"$LOG" 2>&1
