# Katkıda Bulunma

Önce [mimariyi](../docs/ARCHITECTURE.md) okuyun: katmanlar, defter kayıt türleri ve mimari kurallar orada. Aşağıdaki komutlar depo kökünde çalıştırılır.

## Geliştirme ortamı

```bash
git clone https://github.com/alibedirhan/Terminal-Setup.git
cd Terminal-Setup
sudo apt install shellcheck
git clone --depth 1 --branch v1.11.0 https://github.com/bats-core/bats-core.git ~/bats
```

## Kontroller

```bash
bash scripts/check_static.sh             # sözdizimi, ShellCheck, 600 satır, yan etki kuralı
~/bats/bin/bats tests/unit tests/integration
```

Birim ve entegrasyon testleri sahte bir sistemde çalışır; gerçek sisteminize dokunmaz ve ağa çıkmaz. Gerçek gidiş-dönüş testi (Docker gerekir):

```bash
docker run --rm -v "$PWD:/src:ro" ubuntu:24.04 bash /src/tests/e2e/container.sh
docker run --rm -v "$PWD:/src:ro" ubuntu:24.04 bash /src/tests/e2e/gnome.sh   # gerçek dconf ile tema
```

CI bunların hepsini her push'ta çalıştırır.

Arayüz değiştiyse README görsellerini yeniden üretin (tmux ve Pillow gerekir; sahte sistemde çalışır, gerçek sisteme dokunmaz):

```bash
bash scripts/demo/record.sh    # docs/images/*.png, *.gif
```

## Kurallar

1. Sisteme dokunan her işlem `lib/actions/` içindeki bir `act_*` fonksiyonu üzerinden yapılır ve deftere yazılır. Doğrudan `apt-get`, `sudo`, `gsettings set`, `git config --global` kullanmayın.
2. Script'ten önce var olan bir şey kaydedilmez ve kaldırmada silinmez.
3. Yeni bileşen için kaldırma kodu yazmayın; defter geri almayı yapar. `verify` fonksiyonu doğru olsun.
4. Hiçbir dosya 600 satırı geçmez. Büyüyen dosyayı sorumluluğa göre bölün.
5. Yeni davranış için test ekleyin (`tests/unit` ya da `tests/integration`).
6. `curl | sh` yok: harici betik önce dosyaya indirilir; mümkünse GitHub release'inden doğrudan ikili kullanılır.
7. Kullanıcıya görünen metinler Türkçe, kısa ve somut yazılır ve `locale/en.sh`'ye İngilizce karşılığı eklenir. Değişken içeren metin printf biçimindedir: `log_err "Bilinmeyen bileşen: %s" "$id"` (metnin içine `$id` yazılmaz; anahtar sabit kalmalı). Eksik çeviriyi `tests/integration/english.bats` yakalar.

## Bileşen, tema ve terminal eklemek

[Mimari belgesinde](../docs/ARCHITECTURE.md#bileşen-eklemek) örneklerle anlatılıyor. Kısaca:

- Bileşen: `components/<kategori>/<ad>.sh` — `component_register`, `comp_<ad>_install`, `comp_<ad>_verify`
- Tema: `themes/<ad>.theme` — 16 renk + ön/arka plan
- Terminal: `renderers/<ad>.sh` — `rend_<ad>_available`, `rend_<ad>_apply`

## Akış

```bash
git checkout -b feat/kisa-aciklama
# değişiklik + test
git commit -m "feat: kısa açıklama"
git push origin feat/kisa-aciklama
```

Sonra Pull Request açın. Commit mesajları [Conventional Commits](https://www.conventionalcommits.org/) biçiminde: `feat:`, `fix:`, `docs:`, `test:`, `chore:`.

## Sürüm yayınlama (bakımcılar)

```bash
# CHANGELOG.md'ye "## [X.Y.Z] - TARİH" başlığı ekleyin, sonra:
bash scripts/release.sh X.Y.Z            # taslak release
bash scripts/release.sh X.Y.Z --publish  # doğrudan yayın
```
