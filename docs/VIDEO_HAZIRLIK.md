# YouTube Videosu Hazırlık Listesi

## Ortam

- Temiz bir Ubuntu 24.04 ya da 26.04 sanal makinesi (26.04'te varsayılan terminal Ptyxis'tir).
- Kayıttan önce bir anlık görüntü (snapshot) alın; her deneme sonrası ona dönün.
- Terminal penceresini kayıt alanına göre büyütün; menü 80 sütunda düzgün görünür.

## Kayıt öncesi kontrol

```bash
git clone https://github.com/alibedirhan/Terminal-Setup.git
cd Terminal-Setup
./terminal-setup.sh --dry-run install --profile full --theme nord   # ne olacağını gör
./terminal-setup.sh status
```

## Önerilen akış

1. **Sorun:** Format sonrası çıplak terminal; kurulum betiklerinin geri alınamaması.
2. **Menü:** `./terminal-setup.sh` — durum çubuğu, ok tuşlarıyla gezinme.
3. **Kurulum sihirbazı:** developer profili + Tokyo Night. Başlangıç fotoğrafının alındığını gösterin.
4. **Sonuç:** Yeni terminal, Powerlevel10k sihirbazı, `z`, `ll`, `cat`, `lg`, Ctrl+R.
5. **Tema dene:** Ok tuşlarıyla temalar arasında gezinme ve canlı önizleme; birini uygulayın.
6. **Bileşenler:** Bir aracı işaretten kaldırıp kaldırma.
7. **Kaldır > Planı göster:** Neyin silineceği, neye dokunulmayacağı.
8. **Tamamen kaldır:** `kaldır` yazarak onay, rapor: "Sonuç: kalıntı yok."
9. **Kanıt:** Arşiv klasörü ve rapor; `echo $SHELL`; GitHub Actions'taki gidiş-dönüş testi.

## Demo sonrası

```bash
bash scripts/collect_logs.sh   # sorun olursa log paketi
```
