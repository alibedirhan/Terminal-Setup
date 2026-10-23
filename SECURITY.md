# Güvenlik

Terminal Setup paket kurar, kullanıcı ayar dosyalarına ve terminal profiline dokunur. Bu yüzden şu ilkelerle çalışır:

## İlkeler

- **Root olarak çalışmaz.** Yönetici yetkisi yalnızca apt ve `chsh` için, `sudo` üzerinden istenir.
- **`curl | sh` yok.** Oh My Zsh, Powerlevel10k ve eklentiler `git clone` ile; araçlar GitHub release'lerinden HTTPS ile indirilir. Hiçbir uzak betik doğrudan kabuğa borulanmaz (CI denetler).
- **Ayar dosyaları kod olarak çalıştırılmaz.** Tema paletleri ve ayarlar satır satır ayrıştırılır, `source` edilmez.
- **Önceden var olana dokunmaz.** Kullanıcıya ait bir dosyanın üzerine yazılmaz; değiştirilecek dosyanın orijinali önce kopyalanır.
- **Silme koruması.** `$HOME`, `~/.config`, `/usr`, `/etc` gibi yollar defterde olsa bile silinmez.
- **Doğrulanmış başlatıcı.** `install.sh` belirli bir sürüm etiketini indirir ve SHA-256 sağlamasını doğrular.

## Bilinen sınırlar

- GitHub release ikilileri için yayıncıların imzaları doğrulanmıyor; yalnızca HTTPS'e güveniliyor.
- Oh My Zsh ve Powerlevel10k depolarının en son hali klonlanıyor (belirli bir commit'e sabitlenmiyor).

## Açık bildirme

Güvenlik açığı bulduysanız herkese açık issue yerine GitHub'ın [özel güvenlik bildirimi](https://github.com/alibedirhan/Terminal-Setup/security/advisories/new) özelliğini kullanın. Genel hatalar için [Issues](https://github.com/alibedirhan/Terminal-Setup/issues).
