# YouTube Video Öncesi Test Checklist

## Temiz test ortamı

- Ubuntu 24.04 veya 26.04 VM önerilir.
- Test kullanıcısı kullanmak daha güvenlidir.
- Terminal font ve renk değişikliklerinin görünmesi için terminali kapatıp açın.

## Komutlar

```bash
git clone https://github.com/alibedirhan/Terminal-Setup.git
cd Terminal-Setup
bash scripts/check_static.sh
chmod +x terminal-setup.sh
./terminal-setup.sh
```

## Videoda gösterilecek güvenli akış

1. README üzerinden repo tanıtımı
2. Kurulumdan önce güvenlik/yedek notu
3. Menü açılışı
4. Tema seçimi
5. Terminal araçları menüsü
6. Sistem sağlık kontrolü
7. Kaldırma/yedek klasörü bilgisi

## Demo sonrası kontrol

```bash
bash scripts/collect_logs.sh
```
