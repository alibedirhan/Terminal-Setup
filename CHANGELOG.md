# Changelog

## [5.0.2] - 2026-05-25

### Added
- Terminal açılışında 71x45 pencere boyutu için best-effort resize eklendi.
- Ana menü, 71 kolon genişlikte taşma yapmayacak şekilde yeniden dengelendi.
- Statik kontrole 71x45 UI hedefi ve daha kesin ana route eşleşmesi eklendi.

### Fixed
- Banner satır hizaları ve uzun açıklama taşmaları düzeltildi.
- Yedek geri yükleme öncesinde alınan güvenlik yedeğinin eski seçili yedeği silme riski kapatıldı.
- Menü açıklamaları video anlatımı için daha kısa ve tutarlı hale getirildi.

## [5.0.1] - 2026-05-25

### Release Hotfix / Video Ready Polish
- VERSION, README badge ve installer sürümü 5.0.1 olarak eşitlendi.
- `install.sh` hızlı installer listesine `terminal-router.sh` eklendi; hızlı kurulum kırılma riski kapatıldı.
- Ana banner ve açılış animasyonu hizalı, stabil ve VERSION dosyasına bağlı hale getirildi.
- Terminal küçükse best-effort pencere boyutu ayarı ve kullanıcı uyarısı eklendi.
- Menü numaraları ve route kontrolü statik testlere eklendi.
- Yedek sistemi klasör bazlı snapshot yapısına geçirildi.
- Yedek menüsüne en son yedeği geri yükleme, numara seçerek geri yükleme ve yedek klasörünü açma eklendi.
- `cleanup_old_backups`, `create_snapshot` ve `restore_snapshot` fonksiyonları tamamlandı.
- Oh My Zsh kurulumu doğrudan `curl | sh` yerine geçici dosyaya indirme + kontrollü çalıştırma yapısına çekildi.
- `helpers.sh` hata kodu varsayılanları eklendi; transaction akışı daha güvenli hale getirildi.
- `scripts/check_static.sh` release kapısı güçlendirildi.

## [5.0.0] - 2026-05-25

### Mimari Yeniden Tasarım
- **terminal-setup.sh**: 883 → 165 satır. Sadece modül yükleme ve ana döngü
- **terminal-router.sh** (YENİ): Tüm menü yönlendirme ve aksiyon mantığı tek dosyada
- 31 adet tekrarlanan `read -p "Devam etmek için Enter'a basın..."` → `wait_for_enter()` fonksiyonu
- `perform_full_install()` kod tekrarı giderildi (seçenek 5 artık ayrı fonksiyon)
- Tools alt menüsü ana case bloğundan ayrıldı, `do_tools()` fonksiyonuna taşındı

### Menü Yeniden Tasarımı
- 16 seçenek → 9 seçenek + çıkış (daha temiz, daha kolay)
- 4 ayrı tema kurulum satırı → tek "Tam Kurulum" (tema sonra sorulur)
- "Modüler Kurulum" alt menüsü eklendi (Zsh/P10k/Pluginler ayrı ayrı)
- "Sağlık Kontrolü" + "Otomatik Teşhis" → tek "Sağlık & Teşhis" menüsü
- Emoji kaldırıldı (cross-terminal uyumluluk)
- Her seçeneğe dim açıklama satırı eklendi

### Bug Fix
- `load_config()`, `save_config()`, `validate_config()` fonksiyonları implemente edildi (önceden tanımsızdı)
- `show_backups()` fonksiyonu implemente edildi (önceden tanımsızdı)
- `check_for_updates()` fonksiyonu implemente edildi (önceden tanımsızdı)
- Akıllı öneriler doğru menü numaralarına güncellendi

## [4.3.1] - 2026-05-24

### Safe Release Cleanup
- Cleanup guard condition (double call önleme)
- Input validation iyileştirmeleri
- Modüler dosya yapısı temizliği
