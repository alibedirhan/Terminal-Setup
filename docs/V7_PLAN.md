# Terminal Setup 7 — Uyumlu terminal

Son güncelleme: 31 Ekim 2026

## Amaç

Terminal Setup 6 terminali güvenle kurup iz bırakmadan kaldırıyor. 7'nin amacı, kurduğu her şeyin **aynı tasarım dilini** konuşması: tema seçildiğinde terminal, prompt, karşılama kartı ve araçlar birlikte değişir. Temalar yalnızca renkle değil, **kişilikleriyle** de birbirinden ayrılır.

Kararlar, gerçek bir Ubuntu 24.04 GNOME masaüstünde yapılan üç prototipe dayanır (31 Ekim). Prototipler sisteme dokunmadan, geçici bir `ZDOTDIR` ve yalnızca o pencerenin renklerini değiştiren terminal kodlarıyla (OSC 4/10/11) çalıştırıldı.

## Kapsam

### 7.0 — Çekirdek

| # | İş | Durum |
|---|---|---|
| 1 | **Renk rolleri ve okunabilirlik garantisi** | [#11](https://github.com/alibedirhan/Terminal-Setup/pull/11) |
| 2 | **Tema kişilikleri**: `STYLE=` anahtarı; modern, arctic, vivid, retro, soft, neon | [#12](https://github.com/alibedirhan/Terminal-Setup/pull/12) |
| 3 | **Starship varsayılan prompt**: ayar dosyası palet ve kişilikten üretilir; Powerlevel10k seçenek | [#13](https://github.com/alibedirhan/Terminal-Setup/pull/13) |
| 4 | **Oh My Zsh'siz zsh temeli**: eklentiler doğrudan yüklenir | [#14](https://github.com/alibedirhan/Terminal-Setup/pull/14) |
| 5 | **Araçlar kişiliğe uyar**: eza, bat, fzf, btop, tmux, lazygit | [#15](https://github.com/alibedirhan/Terminal-Setup/pull/15) |
| 6 | **Sistem dili**: bütün metinler sistemin diliyle | bu dal |

### 7.1 — Günlük kullanım

| # | İş |
|---|---|
| 7 | **Akıllı karşılama kartı**: yalnızca dikkat isteyenler; son proje ve `resume` |
| 8 | **Komut paleti** (Ctrl+Space): projenin betikleri, testleri, venv, git, son kullanılanlar |
| 9 | **Alt+H yardımı**: yazılan komutun tldr sayfası, sistem dilinde |

### Sonraya kalanlar

Son komutu düzeltme, yapıştırma güvenliği, `share` ve kurulum kodu, şeffaflık ve logo (GNOME Terminal arka plan resmi desteklemiyor; WezTerm ve Kitty destekliyor), gece/gündüz teması, duvar kâğıdından tema, değişiklik geçmişi.

### Bırakılanlar

- **Kendi prompt'umuz:** 5 ms ile Starship'ten (15 ms) hızlıydı ama projeyi tanımıyor (Node sürümü, Python sanal ortamı); bakımı da bize kalırdı.
- **Açılış animasyonu:** Sakin bir terminal hedefiyle uyuşmuyor.

## Tasarım

### Renk rolleri (1)

Temanın 16 rengi terminale olduğu gibi gider. Terminal Setup'ın kendi çizdiği her şey ise rolleri kullanır: `fg accent accent2 info ok warn err muted sel sel_fg border`. Ayrıntı: [mimari belgesi](ARCHITECTURE.md#renk-rolleri).

Neden gerekli: araçların "soluk" yazı için kullandığı `COLOR8`, 12 temanın 9'unda 3:1'in altında kalıyor (Solarized'da 1,0:1, yani arka planla aynı). Sabit bir karışım oranı da çözüm değil: %55 karışım One Dark'ta 3,1:1, Nord'da 4,0:1 veriyor.

### Kişilikler (2, 5)

Bir tema = palet + kişilik. Kişilik; prompt'un biçimini, simgeleri, kart kenarlarını, büyük/küçük harfi, ayırıcıları, `ls` simgelerini ve tarih biçimini, `bat` çerçevesini ve lazygit kenar stilini belirler. Kişilikler kod değil, küçük veri dosyalarıdır.

| Kişilik | Temalar | Prompt | Kenar | lazygit |
|---|---|---|---|---|
| modern | One Dark, Kanagawa | `❯`, iki satır | yuvarlak, renk geçişli | rounded |
| arctic | Nord, Everforest | `›`, tek satır, küçük harf | yok (ince sol çizgi) | hidden |
| vivid | Dracula, Rosé Pine | `λ`, dolgu etiketler | kalın | single |
| retro | Gruvbox, Gruvbox Light, Solarized | `$`, `[köşeli]`, BÜYÜK HARF | köşeli | single |
| soft | Catppuccin Mocha/Latte | `❯`, hap etiketler | yuvarlak, iç boşluklu | rounded |
| neon | Tokyo Night | `▶`, `▸` ayırıcı | çift çizgi | double |

### Oh My Zsh'siz temel (4)

Ölçüm: Oh My Zsh ve 4 eklenti 55 ms, aynı eklentiler doğrudan yüklenince 38 ms. Asıl gerekçe hız değil, çakışmalar: 6.2.2'de düzeltilen iki hata (`plugins=(...)` fzf-tab'i düşürüyordu, `key-bindings.zsh` Ctrl+R'yi eziyordu) Oh My Zsh'ten geliyordu.

Oh My Zsh'in sessizce yaptıkları korunur:
- **OSC 7:** Kabuk bulunduğu dizini terminale bildirir; GNOME Terminal'de yeni sekme aynı dizinde açılır. Ubuntu bunu yalnızca bash için yapar.
- **Pencere başlığı, geçmiş ayarları, tamamlama stilleri, tuş atamaları.**

Kendi Oh My Zsh'i olan kullanıcıya dokunulmaz.

### Geçiş

v6 kullanıcısının prompt'u ve Oh My Zsh'i güncellemeyle kendiliğinden değişmez. Yeni görünüm bir seçimdir ve geri alınabilir.

## Çalışma kuralları

- **Dal ve PR:** Her iş ayrı bir dal ve PR; CI'daki 8 kontrol yeşil olmadan birleşmez.
- **Gerçek sistem testi:** Her aşamanın sonunda bu masaüstünde yalıtılmış durum klasörüyle gerçek kurulum–kaldırma yapılır; sistem bağımsız bir fotoğrafla karşılaştırılır.
- **Prototipler yalnızca referans:** Kod proje kurallarıyla yeniden yazılır: yan etkiler `lib/actions/` içinde, dosyalar 600 satırın altında, her davranışa test.

### Prototiplerden çıkan tuzaklar (test olarak girecek)

- **`local` aynı satırda:** zsh'te `local a=x b=$a`, `b` için `a`'nın eski değerini görür.
- **Kısa süreler:** Kayan noktalı kısa süreler `5.7e-05` diye yazılır; süreler tam sayıyla hesaplanmalı.
- **Nerd Font karakterleri:** Özel kullanım alanı karakterleri (U+E0B0 gibi) kaynakta kaçış dizisiyle (`\ue0b0`) tutulmalı.
- **Kart genişliği:** Kart satırları genişlik sınırına göre kısaltılmalı; uzun dal adları kartı taşırıyordu.
- **`$commands` tablosu:** PATH'e sonradan eklenen bir komutu görmeyebilir; `whence -p` kullanılmalı.
- **Şeffaflık:** Arkadaki açık renkli bir pencere ana yazıyı %80 opaklıkta 3,6:1'e düşürüyor; şeffaflık en fazla %10 önerilir.
