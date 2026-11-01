# Changelog

## [Yayınlanmadı]

Terminal Setup 7 başladı: [plan](docs/V7_PLAN.md).

### Değişti
- **Oh My Zsh'siz zsh temeli.** Profiller artık Oh My Zsh kurmaz; Oh My Zsh isteğe bağlı bileşen olarak kalır. Sağladığı varsayılanlar küçük bir temel parçadan gelir: geçmiş, dizin ayarları, tamamlama (önbellekli `compinit`, menüden seçme, büyük/küçük harf duyarsız), tuşlar (↑ önek araması, Home/End/Delete, Ctrl+ok, Ctrl+X Ctrl+E), pencere başlığı ve **OSC 7**: GNOME Terminal ve Ptyxis'te yeni sekme aynı dizinde açılır (Ubuntu bunu yalnızca bash için yapıyor; Türkçe karakterli yollar doğru kodlanır). Eklentiler Oh My Zsh yoksa kendi klasörlerinden doğrudan ve doğru sırayla yüklenir; Oh My Zsh varsa onun listesine eklenir. Çıplak zsh + temel 16–31 ms'de açılıyor.
- **Varsayılan prompt Starship.** Üç profil de Powerlevel10k yerine Starship kurar; Powerlevel10k isteğe bağlı bileşen olarak kalır (projenin kendi notuna göre bakımı çok sınırlı, yeni özellik gelmiyor). Starship'in ayarı temanın renk rollerinden ve kişiliğinden üretilir, tema ya da kişilik değişince yeniden yazılır: altı kişilik altı farklı prompt biçimi verir (sade, tek satır, dolgu etiketler, hap etiketler, köşeli parantezler, ▸ oklar). Prompt projeyi tanır: git durumu, Node sürümü, Python sanal ortamı, Rust, Go, komut süresi ve hata kodu. Mevcut kurulumlardaki Powerlevel10k'ye dokunulmaz. Menüdeki durum etiketi hangi prompt'un kurulu olduğunu gösterir; yazı tipi teşhisi Starship'i de dikkate alır.
- Statik kontrol kaynakta ham Nerd Font karakterini reddeder; bu karakterler kaçış dizisiyle yazılır.

### Eklendi
- **Komut paleti (Ctrl+Space).** Bulunduğunuz projede çalıştırabileceklerinizi tek listede açar: `package.json` betikleri (npm, pnpm, yarn ya da bun), Makefile hedefleri, justfile tarifleri, Cargo, Go ve pytest testleri, Python sanal ortamı, git komutları ve son kullandığınız komutlar. Liste fzf ile süzülür ve temanın renklerini taşır; seçtiğiniz komut çalıştırılmaz, komut satırına yazılır. developer ve full profilleri kurar; mevcut kurulumda `install --components palette`.
- **Karşılama kartı.** Yeni terminalde yalnızca dikkat isteyenler gösterilir: bekleyen güncellemeler, yeniden başlatma, %90'ı dolan disk, kaydedilmemiş iş ve kaldığınız proje. Kaldığınız projeye `resume` ile dönülür; sizin kendi `resume` komutunuz varsa kart `ts-resume` önerir. Söylenecek bir şey yoksa kart çıkmaz; tmux içinde ve `TS_WELCOME=off` iken de çıkmaz. Kartın kenarı, başlığı, büyük/küçük harfi, tarihi ve işaretleri kişilikten, renkleri temadan gelir (yeni kişilik anahtarı `CARD_MARKS`). Kart çizilirken dış komut çalışmaz; güncelleme, disk ve git bilgisi arka planda, en çok saatte bir yenilenir. developer ve full profilleri kartı kurar; mevcut kurulumda `install --components welcome`.
- **Her şey sistemin dilinde.** Arayüz zaten Türkçe ve İngilizceydi; artık kurulumun ürettiği dosyalar da sistem dilinde yazılır: zsh parçaları (`10-base.zsh`'nin açıklamaları dahil), `init.zsh`, `.zshrc` bloğu, tmux, lazygit ve Starship ayarlarının başlıkları, WezTerm'ün başlangıç ayarı. Arşiv klasörü ve kaldırma raporu da sistem dilinde adlandırılır (`~/terminal-setup-removed-DATE/removal-report.txt`). İngilizce testler bütün bileşenler ve terminaller kurulduktan sonra üretilen dosyalarda Türkçe metin kalmadığını denetler. Mevcut kurulumda dosyalar bir sonraki `theme apply` ya da yeniden kurulumda yeni dile geçer.
- **Araçlar kişiliğe uyar.** Tema ya da kişilik değişince araçlar da biçim değiştirir. tmux durum çubuğu prompt'la aynı dili konuşur (dolgu, ok, hap, köşeli ya da ▸ etiketler), tarihi kişiliğin biçimiyle gösterir, bölme çizgileri kenar stilini izler. lazygit'in kenarı, dosya simgeleri ve renkleri temadan gelir; kullanıcının kendi `config.yml`'ı üstün kalır, dosyasına dokunulmaz. eza simgeleri ve tarih biçimini kişilikten alır; tarih ve noktalama rengi okunabilir soluk renkten gelir (eza'nın koyu grisi çoğu temada okunmuyordu). bat'ın çerçevesi kişilikten gelir; `cat` takma adı sade kalır. Yeni oluşturulan btop.conf'ta köşeler kişilikten gelir. Kenar stilinin araçlardaki karşılığı tek tabloda tanımlıdır. Uçtan uca testte her kişiliğin ayarları gerçek eza, bat, tmux ve lazygit ile denetlenir. lazygit, script kurmamış olsa bile temaya uyar. Mevcut kurulumda eza'nın yeni takma adlarını almak için eza'yı kaldırıp yeniden kurun (`remove eza`, ardından `install --components eza`); diğer araçlar bir sonraki `theme apply` ya da `style set` ile güncellenir.
- **Tema kişilikleri.** Tema artık palet ve kişilikten oluşur. Altı kişilik (modern, arctic, vivid, retro, soft, neon) `styles/` altında veri dosyası olarak durur. Kişilik; prompt simgesini, kenar stilini, büyük/küçük harfi, ayırıcıları, liste simgelerini ve tarih biçimini belirler. Her tema `STYLE=` ile bir kişiliğe bağlıdır. `style list` ve `style set AD|auto` ile başka bir kişilik seçilebilir, örneğin Nord renkleriyle retro. Kişilikten Starship prompt'u, fzf, eza, bat, tmux, lazygit ve btop okur.
- **Renk rolleri ve okunabilirlik garantisi.** Temanın 16 rengi değişmez; Terminal Setup'ın çizdiği her şey (fzf, btop, tmux, tema önizlemesi) anlamı olan rolleri kullanır. Soluk yazı her tema için 4.5:1 kontrasta ulaşacak şekilde hesaplanır; renkli roller en az 3:1, seçili satır en az 4.5:1 olur. Daha önce fzf başlıkları ve btop'un pasif yazıları 12 temanın 9'unda okunması güç renkteydi (Solarized'da arka planla aynı renk). Her temada bütün sınırlar testle denetlenir.

### Düzeltildi
- Tema uygulandıktan sonra kurulan lazygit'in tema dosyaları artık temaya ait: görünümü sıfırlayınca onlar da gider (önceden lazygit'e yazılıyordu, sıfırlamada kalıyordu).
- **Script'in kurduğu lazygit, btop ya da atuin kaldırılınca kullanıcının o araçlara yazdığı ayarlar da siliniyordu.** Bu araçların ayar dizini (`~/.config/lazygit`, `~/.config/btop`, `~/.config/atuin`) önbellek gibi kaydedilip bütünüyle siliniyordu. Artık ayar dosyası (`config.yml`, `btop.conf`, `config.toml`) arşive taşınır; günlük dosyası silinir; dizin yalnızca boş kalırsa silinir, kullanıcının oraya koyduğu başka dosyalar yerinde kalır. Lazygit'in ilk açılışta yazdığı boş `config.yml` gibi boş dosyalar arşive gitmez. 6.x ile yapılmış kurulumların defteri bir sonraki komutta kendiliğinden çevrilir; yeniden kurmak gerekmez.
- Tek bir bileşen kaldırıldıktan sonra yapılan tam kaldırma `~/.local/bin` gibi boş ortak dizinleri bırakıyordu. Hâlâ dolu olduğu için "core"a devredilen dizinler ilk turda içleri doluyken işlenip defterden düşüyordu; artık ikinci turda, alt dizinden başlanarak siliniyor.

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
