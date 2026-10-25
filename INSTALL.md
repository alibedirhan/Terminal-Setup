# Kurulum Rehberi

## Gereksinimler

- Ubuntu 22.04, 24.04 veya 26.04 (x86_64 ya da ARM64)
- Normal kullanıcı hesabı (root olarak çalıştırmayın) ve `sudo` yetkisi
- İnternet bağlantısı (paketler apt'den, araçlar GitHub release'lerinden indirilir)

## Yöntem 1: Depoyu klonlayarak

```bash
sudo apt install git        # git yoksa
git clone https://github.com/alibedirhan/Terminal-Setup.git
cd Terminal-Setup
./terminal-setup.sh
```

## Yöntem 2: Hızlı başlatıcı (klonlamadan)

`install.sh`, yayınlanmış son sürümü indirir, SHA-256 sağlamasını doğrular ve programı geçici bir dizinden çalıştırır. Programın kendisi diske kurulmaz.

```bash
wget https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main/install.sh
less install.sh             # çalıştırmadan önce okuyun
bash install.sh             # menüyü aç
bash install.sh uninstall   # sonradan her şeyi geri al
```

Belirli bir sürüm için: `TS_RELEASE=v6.2.0 bash install.sh`

Güvenlik nedeniyle `curl ... | bash` biçimi önerilmez; betiği önce indirip okuyun.

## İlk kurulum

1. Menüden **Kurulum sihirbazı**'nı seçin.
2. Profil seçin: `minimal`, `developer` (önerilen) ya da `full`. "özel" ile bileşenleri tek tek seçebilirsiniz.
3. Tema seçin (sonradan "Tema dene" ile değiştirilebilir).
4. Özeti onaylayın. İlk kurulumdan önce başlangıç fotoğrafı alınır.
5. Kurulum bitince Powerlevel10k görünüm sihirbazını şimdi açmayı seçebilirsiniz.
6. Terminali kapatıp yeniden açın.

Etkileşimsiz kurulum:

```bash
./terminal-setup.sh --yes install --profile developer --theme tokyo-night
./terminal-setup.sh --yes install --components zsh,p10k,fzf,bat
```

Ne yapılacağını önceden görmek için başına `--dry-run` ekleyin.

## Kurulumdan sonra

| Sorun | Çözüm |
|---|---|
| İkonlar kare görünüyor | Terminal tercihlerinden yazı tipini **MesloLGS NF** yapın (GNOME Terminal ve Ptyxis'te otomatik ayarlanır) |
| Hâlâ bash açılıyor | Oturumu kapatıp açın; ya da `./terminal-setup.sh doctor` |
| Renkler değişmedi | Yeni bir terminal penceresi açın; Ptyxis'te bir kez açıp temayı yeniden uygulayın |
| Prompt görünümünü değiştirmek | zsh içinde `p10k configure` |
| Bir araç çalışmıyor | `./terminal-setup.sh doctor --fix` |

Sorun devam ederse: `bash scripts/collect_logs.sh` ile log paketi oluşturup [issue açın](https://github.com/alibedirhan/Terminal-Setup/issues).

## Kaldırma

```bash
./terminal-setup.sh --dry-run uninstall   # önce planı görün
./terminal-setup.sh uninstall             # geri al
./terminal-setup.sh theme reset           # yalnızca renkleri geri al
```

Ayrıntılar için [README.md](README.md#kaldırma).

## v5'ten geçiş

v5 değişiklik defteri tutmuyordu. v6 ile kurulum yapmadan önce v5'in bıraktıklarını temizlemek isterseniz menüde **Kaldır > v5 kurulumunu temizle** seçeneğini kullanın. Her kategori (dosyalar, `/usr/local/bin` araçları, git ayarları, giriş kabuğu, paketler) ayrıca sorulur; paketler varsayılan olarak kaldırılmaz çünkü v5'ten önce sizin kurmuş olabileceğiniz bilinemez.
