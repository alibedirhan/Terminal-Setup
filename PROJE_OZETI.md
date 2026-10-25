# Proje Özeti — Terminal Setup 6.1.0

Son güncelleme: 23 Ekim 2026

## Ne yapar?

Ubuntu'yu formatladıktan sonra terminali tek seferde kurar: Zsh, Oh My Zsh, Powerlevel10k, MesloLGS NF, 14 komut satırı aracı, tmux ve 7 renk teması. Yaptığı her şeyi kaydeder ve tek komutla, kurulumdan önceki haline döner.

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
| `lib/` | motor (dil desteği dahil) | 15 |
| `locale/` | İngilizce çeviri katalogu | 1 |
| `lib/ui/` | arayüz: renk, ölçü, terminal, çizim, sorular, menü | 6 |
| `lib/actions/` | sisteme dokunan tek katman (yap + geri al + güncelle) | 6 |
| `components/` | kabuk (5), araçlar (14), ekstra (2) | 21 |
| `themes/` | renk paletleri | 7 |
| `renderers/` | GNOME Terminal, Ptyxis, Kitty, Alacritty, tmux | 5 |
| `frontends/` | komut satırı, durum ekranı, menü ekranları | 9 |
| `diagnostics/` | sağlık kontrolleri | 8 |
| `profiles/` | minimal, developer, full | 3 |
| `tests/` | 144 bats testi (15 dosya) + Docker gidiş-dönüş ve GNOME betikleri | 17 |

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
| Dil (arayüz) | Türkçe | Hedef kitle |

Ayrıntılı mimari: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
