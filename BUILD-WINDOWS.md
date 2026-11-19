# بناء نسخة الويندوز (Windows 11 x64) من لينكس

اللعبة تُبنى للويندوز بنفس السورس بدون أي تعديل — cross-compile من لينكس إلى هدف MSVC
بأداة cargo-xwin (تنزّل رؤوس و SDK ويندوز الرسمية من Microsoft لمرة واحدة).

## المتطلبات على جهاز البناء (لينكس)

```bash
rustup target add x86_64-pc-windows-msvc
cargo install cargo-xwin --locked
```

**Clang 19 إلزامي** — رؤوس MSVC STL في أحدث Windows SDK ترفض أقدم (فشل STL1000 مع Clang 18):
```bash
wget -qO /tmp/llvm.sh https://apt.llvm.org/llvm.sh && sudo bash /tmp/llvm.sh 19
```

## البناء (بـ CRT ثابت — exe يعمل على أي ويندوز 10/11 بلا VC++ Redistributable)

```bash
export PATH=/usr/lib/llvm-19/bin:$PATH
CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_RUSTFLAGS="-C target-feature=+crt-static" \
  cargo xwin build --release --target x86_64-pc-windows-msvc -p horizon-client -p horizon-prepare
```

المخرجات: `target/x86_64-pc-windows-msvc/release/horizon-client.exe` و `horizon-prepare.exe`.

> أول تشغيل ينزّل Windows SDK/MSVC CRT (~560MB) إلى `~/.cache/cargo-xwin` — لمرة واحدة.
> بلا CRT ثابت يعمل البناء أيضًا، لكن الـ exe يطلب `VCRUNTIME140.dll`.

## تجميع الحزمة المحمولة

الحزمة الجاهزة تحتاج بجانب الـ exe:

```
horizon-client.exe
horizon-prepare.exe
.local/horizon-client/26.3/    ← الموارد المجهزة (تُنتجها horizon-prepare، منسوخة من جهاز لديه نسخة ماين كرافت)
saves/                          ← العوالم (اختياري)
options.txt                     ← الإعدادات (اختياري)
starling.bat                    ← مشغّل (cd لمجلد الحزمة + منع النسخ المزدوج)
```

- الموارد المجهزة منسجمة بين الأنظمة (بيانات + أنسجة) — نفس مجلد `.local/horizon-client/26.3` يعمل على لينكس والويندوز.
- ملفات Mojang الرسمية (`.official-files/`) لا تُرفع ولا تُوزَّع أبدًا — أداة التجهيز تعيد تنزيلها محليًا عند الحاجة.

## ما تم التحقق منه على هذا البناء

- بناء نظيف لـ `horizon-client.exe` (82MB) و `horizon-prepare.exe` (2.9MB) بهدف MSVC من لينكس.
- الاستيراد كله DLLs نظام مدمجة في ويندوز 10/11 (dxgi، ws2_32، bcrypt، kernel32…) — مع `+crt-static` لا يوجد `VCRUNTIME140.dll` ولا أي حزمة redistributable مطلوبة.
- رسم: Vulkan أولًا ثم DX12 تلقائيًا (wgpu)؛ صوت WASAPI؛ شبكة ws2_32.
