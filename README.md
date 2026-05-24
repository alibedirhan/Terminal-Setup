# Terminal Setup

Terminal Setup, Ubuntu terminalini hızlıca daha kullanışlı hale getirmek için hazırlanmış modüler bir Bash araç setidir. Zsh, Oh My Zsh, Powerlevel10k, renk temaları, tmux ayarı ve modern CLI araçlarını tek menüden kurmayı amaçlar.

Bu proje özellikle Linux'a yeni geçen kullanıcılar ve terminalini daha modern hale getirmek isteyenler için tasarlandı. Script sistem ayarlarına ve kullanıcı shell dosyalarına dokunduğu için kurmadan önce ne yaptığını bilerek ilerlemek en doğru yaklaşımdır.

![Version](https://img.shields.io/badge/version-5.0.2-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Ubuntu-orange.svg)

## Neler yapar?

- Zsh ve Oh My Zsh kurulumu
- Powerlevel10k kurulumu
- 7 terminal teması: Dracula, Nord, Gruvbox, Tokyo Night, Catppuccin, One Dark, Solarized
- Zsh plugin kurulumu
- Modern terminal araçları: fzf, zoxide, eza, bat, ripgrep, fd, delta, lazygit, btop, dust, duf, procs, atuin, tldr
- Tmux kurulumu ve tema ayarı
- Mevcut `.aliases` veya `.bash_aliases` dosyalarını Zsh tarafına bağlama
- Yedek alma, sağlık kontrolü, teşhis ve kaldırma menüleri

## Kullanmadan önce

Bu script terminal görünümünü, `.zshrc`, `.tmux.conf`, GNOME Terminal renk ayarları ve bazı CLI araçlarını değiştirebilir. Script işlem öncesinde yedek almaya çalışır; yine de ana sistemde kullanmadan önce dosyaları incelemeniz önerilir.

Özellikle YouTube demosu veya ilk deneme için en güvenli yol: sanal makine, test kullanıcısı veya yeni kurulmuş Ubuntu oturumu.

## Gereksinimler

- Ubuntu 20.04 veya üzeri
- Bash
- İnternet bağlantısı
- `sudo` yetkisi
- `git`, `curl` veya `wget`

## Kurulum

### 1. Repo üzerinden çalıştırma

```bash
git clone https://github.com/alibedirhan/Terminal-Setup.git
cd Terminal-Setup
chmod +x terminal-setup.sh
./terminal-setup.sh
```

### 2. Hızlı installer

```bash
wget https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main/install.sh
chmod +x install.sh
./install.sh
```

## Menüden önerilen kullanım

Ana menü 71x45 terminal boyutuna göre sadeleştirildi. İlk defa kullanıyorsanız en güvenli akış:

```text
1  Tam Kurulum          Zsh + Oh My Zsh + Powerlevel10k + tema + pluginler
3  Tema Değiştir        Kurulumdan sonra 7 tema arasında geçiş
4  Terminal Araçları    fzf, zoxide, eza, bat, ripgrep ve diğer araçlar
6  Sağlık & Teşhis      Sistem durumunu ve yaygın sorunları kontrol et
7  Yedekler             Yedekleri göster veya seçili yedeği geri yükle
9  Kaldır               Terminal Setup değişikliklerini temizle
```

Yedek menüsü sadece listeleme yapmaz; v5.0.2 ile en son yedeği veya seçtiğiniz yedeği geri yükleyebilir.

## Proje yapısı

```text
Terminal-Setup/
├── terminal-setup.sh        # Ana menü ve akış
├── install.sh               # Hızlı indirici/başlatıcı
├── terminal-ui.sh           # Menü ve görsel terminal çıktıları
├── terminal-router.sh       # Menü numaraları ve aksiyon yönlendirme
├── terminal-assistant.sh    # Sağlık kontrolü ve teşhis
├── core/
│   ├── terminal-base.sh     # Zsh, Oh My Zsh, Powerlevel10k
│   ├── terminal-tools.sh    # CLI araçları
│   └── terminal-config.sh   # Tema, tmux, kaldırma
├── utils/
│   ├── helpers.sh           # Log, retry, güvenli indirme
│   ├── system.sh            # Sistem/internet/terminal kontrolleri
│   └── config.sh            # Config, tema, backup/snapshot
├── themes/                  # Tema dosyaları
├── aliases/                 # Örnek alias dosyası
└── scripts/                 # Test ve release yardımcıları
```

## Kontrol komutları

Geliştirme veya video öncesi şu komutları çalıştırın:

```bash
bash scripts/check_static.sh
bash scripts/check_repo_links.sh
```

Release paketi almak için:

```bash
bash scripts/package_release.sh
```

Log toplamak için:

```bash
bash scripts/collect_logs.sh
```

## Kaldırma

Menüden kaldırma:

```bash
./terminal-setup.sh
# Menü 9: Kaldır
```

Yedekler ve geri yükleme kayıtları varsayılan olarak şu dizinde tutulur:

```text
~/.terminal-setup/backups
```

## Bilinen sınırlar

- Ana hedef Ubuntu ve GNOME Terminal'dir.
- Kitty ve Alacritty için tema desteği vardır, ancak her terminalde aynı görünüm garanti edilmez.
- Bazı araçlar internetten kendi kurulum scriptleriyle gelir; bu yüzden güvenlik için kaynakları incelemek önemlidir.
- Shell değişikliklerinin tam görünmesi için terminali kapatıp açmak veya oturumu yenilemek gerekebilir.

## Güvenlik notu

Bu proje telemetry, kullanıcı hesabı veya bulut senkronu kullanmaz. Kurulum sırasında bazı açık kaynak projelerden dosya indirir. Riskli işlemlerden önce yedek alma hedeflenir; yine de sistem ayarlarını değiştiren her scriptte olduğu gibi sorumluluk kullanıcıdadır.

## Dokümantasyon

- [Kurulum Rehberi](INSTALL.md)
- [Değişiklik Günlüğü](CHANGELOG.md)
- [Katkı Rehberi](CONTRIBUTING.md)
- [Güvenlik](SECURITY.md)
- [Destek](SUPPORT.md)

## Lisans

MIT License. Ayrıntılar için [LICENSE](LICENSE) dosyasına bakabilirsiniz.

## İletişim

- GitHub: [@alibedirhan](https://github.com/alibedirhan)
- Repository: [Terminal-Setup](https://github.com/alibedirhan/Terminal-Setup)
- Issues: [Sorun bildir](https://github.com/alibedirhan/Terminal-Setup/issues)
