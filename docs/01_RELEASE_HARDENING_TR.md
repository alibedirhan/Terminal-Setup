# Terminal Setup v5.0.2 Release Hardening

Bu çalışma yeni özellik eklemekten çok projeyi güvenilir, bakımı kolay ve YouTube videosunda gösterilebilir hale getirmeye odaklanır.

## Ana kararlar

- Repo adı: `Terminal-Setup`
- Ana sürüm kaynağı: `VERSION`
- Ana kullanım hedefi: Ubuntu 20.04+ / GNOME Terminal
- İlk deneme önerisi: VM, test kullanıcısı veya yeni Ubuntu oturumu

## Yapılan sertleştirmeler

- Eski repo linkleri temizlendi.
- Installer doğru raw GitHub adresinden indirir hale getirildi.
- Bash syntax ve repository link kontrol scriptleri eklendi.
- Geçici dosya kullanan daha güvenli install script akışları eklendi.
- Release paketleme scripti eklendi.
- Kişisel isim/özel bilgi sızıntısı için kontrol eklendi.

## Sürüm sonrası kontrol

```bash
bash scripts/check_static.sh
bash scripts/check_repo_links.sh
bash scripts/package_release.sh
```
