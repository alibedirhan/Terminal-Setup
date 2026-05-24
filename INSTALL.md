# Terminal Setup Kurulum Rehberi

Bu rehber Terminal Setup'ı güvenli şekilde denemek, kurmak, kontrol etmek ve kaldırmak için hazırlanmıştır.

## En güvenli deneme yöntemi

İlk denemeyi mümkünse sanal makinede, test kullanıcısında veya yeni kurulmuş Ubuntu oturumunda yapın. Script `.zshrc`, `.tmux.conf`, GNOME Terminal renk ayarları ve bazı CLI araçlarını değiştirebilir.

## Gereksinimler

```bash
sudo apt update
sudo apt install -y git curl wget
```

## Repo üzerinden kurulum

```bash
git clone https://github.com/alibedirhan/Terminal-Setup.git
cd Terminal-Setup
chmod +x terminal-setup.sh
./terminal-setup.sh
```

## Hızlı installer ile kurulum

```bash
wget https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main/install.sh
chmod +x install.sh
./install.sh
```

`curl` kullanmak isterseniz:

```bash
curl -fsSL https://raw.githubusercontent.com/alibedirhan/Terminal-Setup/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

## Video/demodan önce kontrol

```bash
bash scripts/check_static.sh
bash scripts/check_repo_links.sh
```

## Kurulum sonrası öneriler

Terminali kapatıp açın. Zsh aktif değilse oturumu yeniden açmanız gerekebilir.

```bash
echo $SHELL
zsh --version
```

Powerlevel10k ayarını tekrar açmak için:

```bash
p10k configure
```

## Sorun giderme

Log dosyası:

```text
~/.terminal-setup/logs/terminal-setup.log
```

Log paketi toplamak için:

```bash
bash scripts/collect_logs.sh
```

Sağlık kontrolü:

```bash
./terminal-setup.sh --health
```

## Yedekten geri yükleme

Kurulumdan önce ve geri yükleme öncesinde yedek alınır. Yedekleri menüden yönetebilirsiniz:

```bash
./terminal-setup.sh
# Menü 7: Yedekler
# 1: En son yedeği geri yükle
# 2: Numara seçerek geri yükle
# 3: Yedek klasörünü aç / göster
```

Yedek klasörü:

```text
~/.terminal-setup/backups
```

## Kaldırma

```bash
./terminal-setup.sh
# Menü 9: Kaldır
```

Yedek klasörü:

```text
~/.terminal-setup/backups
```

## Destek

Sorun bildirirken şunları ekleyin:

```bash
lsb_release -a
bash --version
zsh --version
bash scripts/check_static.sh
bash scripts/collect_logs.sh
```

GitHub Issues: https://github.com/alibedirhan/Terminal-Setup/issues
