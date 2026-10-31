# Changelog

## [6.2.2] - 2026-10-31

Gerçek bir Ubuntu 24.04 GNOME masaüstünde (Oh My Zsh'i kullanıcının kendisinin kurduğu, 600'den fazla yazı tipli bir sistem) yapılan kurulum–kaldırma testinde bulunan hatalar.

### Düzeltildi
- **Oh My Zsh'i `~/.zshrc` kendisi yüklüyorsa** fzf-tab yüklenmiyor, atuin ve fzf'in Ctrl+R'si Oh My Zsh'in düz geçmiş aramasına geri dönüyordu: kullanıcının `plugins=(...)` satırı bizim eklentilerimizi listeden düşürüyor, `key-bindings.zsh` Ctrl+R'yi yeniden bağlıyordu. Parçalar artık ilk istemde bir kez eksik kalan eklentiyi doğrudan yükler ve düz aramaya dönmüş Ctrl+R'yi geri alır; kullanıcının kendi seçtiği widget'a dokunulmaz. Mevcut kurulumda düzeltmeyi almak için ilgili bileşenleri kaldırıp yeniden kurun (`remove fzf-tab zsh-plugins fzf atuin`, ardından `install`).
- `doctor`, MesloLGS NF kuruluyken "yok" diyordu: çok satırlı `fc-list` çıktısında `grep -q` erken çıkınca `pipefail` hattı başarısız sayıyordu. Aynı kalıp Alacritty yazı tipi ayarında, Oh My Zsh algılamasında ve defter sorgularında da düzeltildi; statik kontrol artık borulu `grep -q` kullanımını reddeder.
- Paket ya da giriş kabuğu değiştirmeyen bir kurulumun kaldırılması gereksiz yere yönetici şifresi istiyor, şifre verilemezse hiç başlamıyordu. Şifre artık yalnızca defterde paket veya kabuk kaydı varsa sorulur.
- `doctor` zsh açılışı yavaşken sürenin çoğu Terminal Setup parçalarından gelmiyorsa bunu söyler; daha önce 1,4 saniyelik açılışta "en çok zaman alan: atuin 12 ms" diyerek yanlış yere yönlendiriyordu.

## [6.2.1] - 2026-10-26

### Değişti
- Kurulum rehberi ve proje özeti `docs/` altına; katkı, destek ve güvenlik belgeleri `.github/` altına taşındı. Belge bağlantıları güncellendi, kullanılmayan Türkçe ana menü görseli kaldırıldı.
- Yerel Claude ayarları ve Python önbellekleri `.gitignore` kapsamına alındı; geliştirme özeti ve video hazırlık listesi kurulum paketinden çıkarıldı.

### Düzeltildi
- Tema listesinde açık/koyu eşler yan yana ve koyu tema önce gösterilir; uzun tema adları komut satırında hizalıdır. README görselleri yenilendi.
- Eksik `--profile`, `--theme`, `--components` ve `--lang` değerleri hata koduyla reddedilir; yanlışlıkla varsayılan kurulum başlamaz.
- Kurulum başarısızsa CLI ve sihirbaz tema uygulamasına devam etmez; CLI tema hatasını başarı olarak bildirmez.
- Temiz sistemde prova modu, kurulumla gelecek araçlara tema uygulamayı denemek yerine tema planını gösterir.
- Arşivleme ya da orijinal dosyayı yedekleme başarısızsa kullanıcı ayarının üzerine yazılmaz, kaynak veri ve geri alma kaydı korunur. Blok yazma hataları çağırana iletilir.
- Aynı saniyedeki ayrı kaldırma işlemleri benzersiz arşiv dizinleri kullanır; önceki kullanıcı verisinin üzerine yazılmaz.
- Kaldırma işleminin hata sayısı ve arşiv bilgileri alt kabukta kaybolmaz; başarısız tema sıfırlaması başarı sayılmaz ve seçili tema korunur.
- Paket kaldırma simülasyonu başarısızsa hiçbir paket kaldırılmaz. Hata veren apt kurulumunun getirdiği bağımlılıklar da değişiklik defterine eklenir.
- Kullanıcıya ait bozuk sembolik bağlantılar değiştirilmez; önceden var olan boş klasöre depo klonlanmaz. `..` ya da sembolik bağlantı içeren yollar silme korumasından önce çözülür.
- Başlatıcının dil testi, çağıran terminalin `LC_ALL` / `LC_MESSAGES` ayarlarından bağımsız çalışır. Bu hata senaryoları için 23 regresyon testi eklendi.

## [6.2.0] - 2026-10-25

### Eklendi
- **Araçlar da temaya uyar:** Tema değişince bat ve delta (söz dizimi teması), fzf (paletten renkler) ve btop (paletten üretilen tema) da değişir. Kullanıcının araç ayar dosyalarına dokunulmaz; btop.conf yoksa oluşturulur ve kullanıcı verisi sayılır.
- **Kısayollar ekranı** (menü ve `tips`): kurulan araçların kısayolları; bileşenler ne öğrettiğini `component_tip` ile bildirir.
- **Açılış ipucu** (Ayarlar ya da `tips --shell on`): her yeni zsh oturumunda bir kısayol.
- **Zsh açılış süresi** `doctor`'da; 300 ms'yi aşarsa en yavaş parçalar söylenir.
- **fzf-tab:** Tab tamamlaması aranabilir listede (developer ve full profillerinde).
- **5 yeni tema:** Rosé Pine, Kanagawa, Everforest ve açık temalar Catppuccin Latte, Gruvbox Light. Ptyxis'te eşli temalar sistemin açık/koyu tonunu izler.
- **Ghostty ve WezTerm** desteği.
- **Starship:** Powerlevel10k'ya seçenek olarak hızlı prompt (ikisi birlikte kurulamaz).
- **Yazı tipi seçimi:** JetBrains Mono ve Fira Code Nerd Font bileşenleri; Ayarlar'da ya da `font set` ile seçilir.

## [6.1.1] - 2026-10-25

### Eklendi
- README'de animasyonlu tanıtım: menü turu ve tema önizleme GIF'leri (Türkçe ve İngilizce). `scripts/demo/record.sh` görselleri sahte sistemde, gerçek sisteme dokunmadan yeniden üretir.

### Değişti
- `install.sh` mesajları programla aynı dil kuralına uyar (`--lang`, `TS_LANG`, ayar, sistem dili).
- CI: bats testleri ağ arayüzü olmayan bir ad alanında çalışır; ağa çıkan test düşer.

### Düzeltildi
- `update`, geçerli bir git deposu olmayan klasörü "değiştirilmiş dosyalar var" diye raporluyordu.
- Testlerdeki sahte `git`, `ls-remote`'u taklit etmediği için güncelleme testleri gerçek GitHub'a çıkıyordu.

## [6.1.0] - 2026-10-25

### Eklendi
- **İngilizce arayüz:** Sistem dili Türkçe değilse arayüz İngilizce açılır. Menüde "Ayarlar → Dil / Language", komut satırında `--lang en|tr`. Çeviriler `locale/en.sh`'de; eksik ya da Türkçe kalan metni testler yakalar.
- **`update` komutu** ve menüde "Güncelle": GitHub'dan kurulan araçlar son release'e, Oh My Zsh / Powerlevel10k / eklenti depoları son commit'e yükseltilir. Yalnızca Terminal Setup'ın kurduğu parçalar güncellenir; `--dry-run` ile önce plan görülebilir.
- CI: Ubuntu 26.04 gidiş-dönüş testi; üç sürümde gerçek dconf ile GNOME Terminal ve Ptyxis testi.

### Düzeltildi
- Ubuntu 25.10 ve sonrasında `tldr` paketi depoda olmadığı için kurulum başarısız oluyordu; 24.04 ve sonrasında aynı komutu sağlayan `tealdeer` kurulur.

## [6.0.0] - 2026-10-23

Mimari baştan yazıldı. Ana hedef: kurulan her şeyin iz bırakmadan geri alınabilmesi.

### Eklendi
- **Başlangıç fotoğrafı:** İlk kurulumdan önce paketler, giriş kabuğu, git ayarları, terminal profilleri ve izlenen dizinler bir kez kaydedilir.
- **Değişiklik defteri:** Kurulan her paket (bağımlılıklar dahil), oluşturulan her dosya, değiştirilen her ayar kaydedilir; kaldırma defteri sondan başa geri alır.
- **Kanıtlı kaldırma:** Kaldırmanın sonunda sistem fotoğrafla karşılaştırılır ve rapor arşive yazılır.
- **İki seviyeli kaldırma:** "Görünümü sıfırla" (yalnızca tema) ve "Tamamen kaldır" (plan + yazılı onay).
- Kullanımla oluşan veriler (komut geçmişi, prompt ayarı) silinmez, `~/terminal-setup-kaldirilan-TARİH/` arşivine taşınır.
- Güvenli paket kaldırma: silme öncesi apt simülasyonu; başka bir paketin ihtiyaç duyduğu paket atlanır.
- **Tema önizleme:** Temanın kendi renkleriyle çizilmiş bir terminal penceresi ve 16 renklik palet canlı gösterilir; ok tuşlarıyla gezilir.
- **Ptyxis** (Ubuntu 25.10+ varsayılan terminali) desteği; Alacritty için TOML biçimi.
- **ARM64** desteği: GitHub araçları mimariye göre indirilir.
- **Yeni arayüz (bağımlılıksız):** renk geçişli logo, durum ve öneri kartları, bölümlere ayrılmış menüler, adım göstergeli kurulum sihirbazı, iki sütunlu durum ekranı. 24 bit / 256 / 8 renkli terminallere ve `NO_COLOR`'a uyum sağlar; ekran titremeden ve alt süreç açmadan yeniden çizilir (tuş başına ~15 ms), uzun listeler kayar, pencere boyutu değişince düzen yenilenir. Hiçbir satır terminal genişliğini, hiçbir ekran terminal yüksekliğini aşmaz. Menü alternatif ekranda çalışır; işlemlerin çıktısı normal ekranda kaydırılabilir kalır; çıkışta ve Ctrl+C'de terminal ayarları her durumda geri yüklenir. Arayüz katmanı `lib/ui/` altında altı modüldür (docs/ARCHITECTURE.md).
- Etkileşimsiz komut satırı: `install`, `remove`, `theme`, `status`, `doctor`, `uninstall`, `verify`, `list`.
- Her komut için `--dry-run` (prova) modu.
- Hazır profiller: minimal, developer, full.
- Bileşen bazında kaldırma; yarıda kalan bileşenin değişiklikleri otomatik geri alınır.
- v5 kurulumları için adım adım onaylı temizlik.
- `install.sh` belirli bir sürümü indirip SHA-256 ile doğrular, programı geçici dizinden çalıştırır.
- Test altyapısı: sahte sistem üzerinde bats birim/entegrasyon testleri, temiz Ubuntu 22.04/24.04 konteynerlerinde Docker gidiş-dönüş testi.
- CI: ShellCheck, 600 satır sınırı, yan etki kuralı, testler.

### Değişti
- `.zshrc`'ye dağınık satır eklenmiyor; tek bir işaretli blok `~/.config/terminal-setup/init.zsh`'i yükler. `plugins=` satırınız ezilmiyor.
- Oh My Zsh kurulum betiği çalıştırılmıyor (`.zshrc`'yi yeniden yazıyordu); depo klonlanıyor.
- fzf, zoxide, eza, delta, lazygit, dust, procs, atuin GitHub release'lerinden `~/.local/bin` altına kuruluyor; sudo, rustup ya da snap gerekmiyor.
- Temalar yalnızca renk paleti; terminale özgü kod renderer'larda.
- Kutuların sağ kenarı kaldırıldı; Türkçe karakterlerde hizalama artık kaymıyor.
- Menü her çizimde ağa çıkmıyor.
- Desteklenen sürümler: Ubuntu 22.04, 24.04, 26.04.

### Düzeltildi
- apt komutlarındaki 30 sn zaman aşımı dpkg'yi yarıda bırakabiliyordu.
- Ctrl+C programı sonlandırmıyordu.
- Tema dosyaları script başka dizinden çalıştırılınca bulunamıyordu.
- Kaldırma, script'ten önce kurulu paketleri ve `~/.zsh_history`'yi siliyor, `core.pager delta` ayarını bırakıyordu.
- Orijinal yedek birkaç işlemde rotasyonla siliniyordu.
- lazygit'in yeni release adları (`linux_x86_64`) ve eza'nın GitHub yedek yolu.

### Kaldırıldı
- `smart-version-manager.sh` ve `smart-release-manager.sh` yerine `scripts/release.sh`.
- Pencere boyutunu zorla değiştiren 71x45 ayarı.

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
