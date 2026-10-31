# Proje Özeti — Terminal Setup 6.2.2

Son güncelleme: 31 Ekim 2026

## Nerede kaldık?

- **v6.0:** Başlangıç fotoğrafı, değişiklik defteri, geri alınabilir kurulum ve bağımlılıksız menü tamamlandı.
- **v6.1:** İngilizce arayüz, kurulu araçları güncelleme ve üç Ubuntu sürümünde GNOME testleri eklendi.
- **v6.2.0:** Araç temaları, kısayollar, açılış ipuçları, zsh hız ölçümü, fzf-tab, beş yeni tema, Ghostty/WezTerm, Starship ve yazı tipi seçimi eklendi. [Sürüm yayımlandı](https://github.com/alibedirhan/Terminal-Setup/releases/tag/v6.2.0).
- **Tema listesi (25 Ekim):** Tema listesi sıralandı ve hizalandı; açık/koyu eşler yan yana getirildi, README görselleri yenilendi. `main` dalına [#7](https://github.com/alibedirhan/Terminal-Setup/pull/7) ile alındı (`7916aee`); [CI başarılı](https://github.com/alibedirhan/Terminal-Setup/actions/runs/40210461042).
- **v6.2.1 (26 Ekim):** Tema listesi düzeltmesini ve depo düzenini içerir. Eksik komut seçenekleri, başarısız arşiv/yedekleme, paket simülasyonu ve yarım kalan kurulum, sembolik bağlantılar ve kaldırma hataları için korumalar eklendi. Test sayısı 194'e çıktı.
- **v6.2.2 (31 Ekim) — gerçek sistem testi:** Bu Ubuntu 24.04 GNOME masaüstünde yalıtılmış durum klasörüyle tam kurulum, tema değiştirme ve kaldırma yapıldı; sistem bağımsız bir fotoğrafla karşılaştırılarak eski haline döndürüldü. Kullanıcının kendi Oh My Zsh'iyle fzf-tab/Ctrl+R çakışması, `pipefail` + `grep -q` yazı tipi teşhisi, gereksiz sudo isteyen kaldırma ve yanıltıcı zsh hız mesajı düzeltildi; 10 regresyon testi eklendi (204).
- **v7 başladı (31 Ekim):** Üç prototipten sonra "uyumlu terminal" planı onaylandı: renk rolleri, tema kişilikleri, Starship, Oh My Zsh'siz temel. Ayrıntı: [V7_PLAN.md](V7_PLAN.md).
- **Açık işler:** 26 Ekim kontrolünde GitHub'da açık issue veya PR bulunmuyor. Video çekimi için [hazırlık listesi](VIDEO_HAZIRLIK.md) var; çekimin tamamlandığına dair depoda kayıt yok.

Sürüm geçmişi: [CHANGELOG.md](../CHANGELOG.md). Geliştirme ve test komutları: [katkı rehberi](../.github/CONTRIBUTING.md).

## Ne yapar?

Ubuntu'yu formatladıktan sonra terminali tek seferde kurar: Zsh, Starship (isteğe bağlı Oh My Zsh ve Powerlevel10k), Nerd Font yazı tipleri, 14 komut satırı aracı, tmux ve 12 renk teması. Yaptığı her şeyi kaydeder ve tek komutla, kurulumdan önceki haline döner.

## Temel fikir

| Parça | Görevi |
|---|---|
| Başlangıç fotoğrafı | İlk kurulumdan önceki sistem hali (bir kez, rotasyonsuz) |
| Değişiklik defteri | Script'in yaptığı her değişiklik, sahibi olan bileşenle birlikte |
| Yönetilen bloklar | Kullanıcı dosyalarına tek bir işaretli blok; ayarlar `~/.config/terminal-setup/` altında |
| Kanıtlı kaldırma | Defteri tersten geri al, sonra fotoğrafla karşılaştır ve raporla |

## Yapı

| Dizin | İçerik | Dosya |
|---|---|---|
| `lib/` | motor (dil, kısayollar, yazı tipi seçimi dahil) | 17 |
| `locale/` | İngilizce çeviri katalogu | 1 |
| `lib/ui/` | arayüz: renk, ölçü, terminal, çizim, sorular, menü | 6 |
| `lib/actions/` | sisteme dokunan tek katman (yap + geri al + güncelle) | 6 |
| `components/` | kabuk (7), araçlar (14), ekstra (4) | 25 |
| `themes/` | renk paletleri (10 koyu, 2 açık) | 12 |
| `renderers/` | terminaller: GNOME Terminal, Ptyxis, Kitty, Alacritty, Ghostty, WezTerm; araçlar: tmux, bat/delta/fzf, btop | 9 |
| `frontends/` | komut satırı, durum ekranı, menü ekranları | 9 |
| `diagnostics/` | sağlık kontrolleri (zsh açılış süresi dahil) | 9 |
| `profiles/` | minimal, developer, full | 3 |
| `tests/` | 234 bats testi (26 dosya) + Docker gidiş-dönüş ve GNOME betikleri | 22 |

Kurulum ve proje belgeleri `docs/` altında; katkı, destek ve güvenlik belgeleri GitHub'ın tanıdığı `.github/` dizininde tutulur. `release/` yalnızca paket üretildiğinde oluşur ve Git'e eklenmez. Yerel Claude izinleri de Git dışında tutulur.

En büyük dosya 400 satırın altında; kural 600.

## Kalite kapıları

- ShellCheck sıfır uyarı, 600 satır sınırı, "yan etki yalnızca `lib/actions/`" kuralı (`scripts/check_static.sh`)
- Sahte sistem üzerinde bats testleri (`tests/unit`, `tests/integration`)
- Temiz Ubuntu 22.04, 24.04 ve 26.04 konteynerlerinde gerçek gidiş-dönüş testi (`tests/e2e/container.sh`)
- Aynı sürümlerde gerçek dconf ile GNOME Terminal / Ptyxis testi (`tests/e2e/gnome.sh`)
- Hepsi GitHub Actions'ta her push'ta çalışır

## Kararlar

| Konu | Karar | Neden |
|---|---|---|
| Dil | Bash | Formatlanmış makinede hiçbir şey kurmadan çalışır |
| Arayüz | Bağımlılıksız, ok tuşlu menü | gum gibi ek bir ikiliye gerek kalmadı |
| Desteklenen sürümler | Ubuntu 22.04, 24.04, 26.04; x86_64 ve ARM64 | LTS sürümleri |
| GitHub araçları | Release ikilileri, `~/.local/bin` | sudo, rustup, snap gerekmez; kaldırması tek dosya |
| Kullanıcı verisi | Silinmez, arşive taşınır | Geri alınamaz kayıp olmasın |
| Dil (arayüz) | Türkçe ve İngilizce | Sistem diline göre otomatik, menüden değiştirilebilir |

Ayrıntılı mimari: [ARCHITECTURE.md](ARCHITECTURE.md)
