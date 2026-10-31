# Mimari

Terminal Setup küçük bir **motor** ve onun üzerinde veri gibi yazılan **bileşenlerden** oluşur. Temel vaadi şudur: script'in yaptığı her değişiklik kaydedilir ve tek komutla geri alınır; kurulumdan önce sistemde olan hiçbir şeye dokunulmaz.

## Katmanlar

```
frontends/   Menü (tui/) ve komut satırı (cli.sh). Ekran çizer, soru sorar;
     │       sistemi kendisi değiştirmez.
     ▼
lib/runner.sh   Profili ve bileşen sırasını belirler; dry-run, idempotency,
     │          hata halinde bileşen bazında geri alma.
     ▼
components/  themes/  renderers/   NE kurulacağını tarif eder.
     │
     ▼
lib/actions/   Sisteme dokunan TEK katman: act_pkg, act_path, act_rc_block,
     │         act_gitcfg, act_dconf_key, act_login_shell ... ve geri alma
     │         işleyicileri (undo_*).
     ├──────────────► Sistem (paketler, dosyalar, ayarlar)
     └──────────────► Defter (~/.terminal-setup/ledger)
```

Çağrılar yalnızca yukarıdan aşağı akar. Kaldırma, `lib/undo.sh`'nin defteri sondan başa okuyup her satırı ilgili `undo_*` işleyicisine göndermesidir.

## Üç temel parça

**Başlangıç fotoğrafı** (`lib/baseline.sh`): İlk kurulumdan hemen önce bir kez alınır, hiçbir zaman rotasyona girmez. Paket listesi, giriş kabuğu, git ayarları, terminal profilleri (dconf) ve ev dizinindeki izlenen konumları içerir. Kaldırmanın sonunda sistem bununla karşılaştırılır (`lib/verify.sh`).

**Değişiklik defteri** (`lib/ledger.sh`): Her eylem bir satır yazar:

```
bileşen <TAB> tür <TAB> arg1 [<TAB> arg2]
```

| Tür | Anlamı | Geri alma |
|---|---|---|
| `pkg` | script'in kurduğu apt paketi (bağımlılıklar dahil, kurulum öncesi/sonrası farkından) | `apt-get purge`, önce simülasyonla güvenlik kontrolü |
| `path` | tamamen script'e ait dosya/dizin | silinir |
| `dir` | paylaşılan dizin (`~/.local/bin` gibi) | yalnızca boşsa silinir |
| `glob` | önbellek kalıbı (`~/.zcompdump*`) | eşleşenler silinir |
| `userdata` | kullanımla oluşan veri (komut geçmişi, prompt ayarı) | silinmez, arşive taşınır |
| `rcblock` | kullanıcı dosyasındaki işaretli blok | blok çıkarılır |
| `rcfile` | kullanıcı dosyasının orijinal kopyası | son blok kalkınca orijinal geri konur |
| `gitcfg` / `dconf` | ayarın önceki değeri | önceki değere dönülür ya da silinir |
| `shell` | orijinal giriş kabuğu | `chsh` ile geri |
| `note` | bilgi (ör. "bu bileşen kullanıcıda zaten vardı") | — |

İlk satır sürüm başlığıdır (`# terminal-setup ledger v1`); biçim değişirse eski defterler taşınabilir.

**Yönetilen bloklar** (`lib/actions/rc.sh`): `~/.zshrc` gibi kullanıcı dosyalarına dağınık satır eklenmez. Her bileşen kendi işaretli bloğunu ekler; asıl ayarlar `~/.config/terminal-setup/` altında durur:

```
# >>> terminal-setup:zsh >>>
[[ -r "~/.config/terminal-setup/init.zsh" ]] && source "~/.config/terminal-setup/init.zsh"
# <<< terminal-setup:zsh <<<
```

`init.zsh`, `zsh.d/` altındaki parçaları sıra numarasıyla yükler (`10-base`, `18-fzf-tab`, `20-zsh-plugins`, `60-fzf`, `90-starship`, `98-zsh-highlight` ...).

**Zsh temeli** (`zsh/base.zsh`, zsh bileşeninin `10-base` parçası): Oh My Zsh'in sessizce sağladığı varsayılanların özü. Geçmiş ayarları; `auto_cd` ve dizin yığını; `compinit` (önbellek `~/.cache/terminal-setup`, günde bir kez tam denetim); tamamlama stilleri; tuşlar (↑ önek araması, Home/End/Delete, Ctrl+ok, Shift+Tab, Ctrl+X Ctrl+E); pencere başlığı; **OSC 7** (bulunulan dizin terminale bildirilir, yeni sekme aynı dizinde açılır; yol UTF-8 baytlarıyla URL kodlanır, `İ` → `%C4%B0`). Ubuntu bu bildirimi yalnızca bash için yapar.

v7 profilleri Oh My Zsh kurmaz. Eklentiler (`zsh-plugins`, `fzf-tab`) Oh My Zsh kullanılmıyorsa `~/.local/share/terminal-setup/plugins` altına klonlanıp doğrudan yüklenir: fzf-tab `compinit`'ten sonra (18), öneriler 20'de, sözdizimi renklendirme bütün widget'lar tanımlandıktan sonra (98). Oh My Zsh kullanılıyorsa (script kurduysa ya da kullanıcının `.zshrc`'si yüklüyorsa) eklentiler onun klasörüne ve `plugins` listesine eklenir; liste sonradan yeniden yazılırsa ilk istemde doğrudan yüklenir (`zsh_late_load`).

Oh My Zsh'i kullanıcı kurmuşsa onu blok değil, `~/.zshrc`'deki kendi satırları ve bloktan *sonra* yükler. Bu durumda `plugins=(...)` ataması parçaların eklediği eklentileri düşürür, Oh My Zsh'in `key-bindings.zsh` dosyası da Ctrl+R'yi düz aramaya bağlar. `zsh_late_load` ve `zsh_late_rebind` (`lib/actions/rc.sh`) parçaya, ilk istemde bir kez çalışıp kendini silen bir `precmd` kancası ekler: eklenti hâlâ yüklenmemişse doğrudan yüklenir; Ctrl+R düz aramadaysa geri alınır, kullanıcının seçtiği widget'a dokunulmaz. Oh My Zsh'i script kurduysa kancalar bir şey yapmaz (`tests/unit/zsh_late.bats`).

## Arayüz katmanı

Menü bağımlılıksız saf bash ile çizilir. `lib/ui/` altındaki modüller tek yönlü bağımlıdır; her biri yalnızca soldakileri kullanır:

```
style.sh → text.sh → term.sh → draw.sh → prompt.sh → widgets.sh → frontends/tui/
renk       ölçü       terminal   çerçeve    sorular     döngü, menü,   ekranlar
paleti     kesme      oturumu    kartlar                liste
```

| Modül | Sorumluluk |
|---|---|
| `style.sh` | 24 bit / 256 / 8 renk algılama; ekranlar renk kodu değil anlamlı ad kullanır (`U_ACC`, `U_MUTED`, `U_OK` ...) |
| `text.sh` | Görünen genişlik (renk kodları sayılmaz), doldurma, kısaltma, renk koruyarak kesme |
| `term.sh` | Terminal kipine dokunan tek yer: alternatif ekran, yankı kapalı tuş okuma, işlem için normal kipe geçiş, çıkışta koşulsuz geri yükleme |
| `draw.sh` | Çerçeve tamponu ve yapı taşları (kart, bölüm, tuş ipuçları) |
| `prompt.sh` | Evet/hayır, yazarak onay, "devam için Enter"; menü açıkken de doğru çalışır |
| `widgets.sh` | Ortak etkileşim döngüsü (`ui_loop ÇİZ İŞLE`), menü ve çoklu seçim |

Arayüz kuralları:

1. **Çizim alt kabuk açmaz.** Çizimde kullanılan yardımcılar sonucu `REPLY`'ye yazar; `$(...)` her tuşta gecikme demektir. Durum bilgisi (bileşenler, tema) her tuşta değil, ekran açılırken ve bir işlemden sonra okunur (`UI_HEADER_STALE`).
2. **Çerçeve sözleşmesi:** hiçbir satır terminal genişliğini, hiçbir çerçeve terminal yüksekliğini aşmaz; tuş ipuçları hep en altta görünür. `tests/unit/tui_layout.bats` her ekranı 40x12'den 200x60'a kadar altı boyutta denetler.
3. **Çiz ve işle ayrıdır.** Ekranın çizim fonksiyonu terminal okumaz; `UI_DRAW_ONCE=1` ile testte tek kare çizilebilir. Tuş işleyici yalnızca durumu değiştirir.
4. **İşlemler menü dışında çalışır.** Sistemi değiştiren ya da çıktı üreten her şey `tui_run` ile çağrılır: terminal normal kipe ve ana ekrana döner, çıktı kaydırılabilir geçmişte kalır.
5. **Ekran seçenekleri sızmaz.** Alt başlık, alt bilgi, büyük logo gibi seçenekler parametreyle verilir (`ui_menu --subtitle ... --footer ... --hero`) ve `local` tanımlanır.
6. **Yalnızca tek hücre genişliğinde simgeler** (emoji yok); aksi halde hizalama terminale göre kayar.

Yeni bir menü ekranı eklemek:

```bash
tui_ornek() {
    ui_menu --subtitle "Açıklama" "Başlık" \
        "#Bölüm" "Birinci|Ne yaptığı|✦" "İkinci|Ne yaptığı|◎" || return 0
    case "$UI_CHOICE" in
        0) tui_run birinci_islem ;;
        1) tui_run ikinci_islem ;;
    esac
}
```

Özel çizim gereken ekranlar (tema tarayıcı gibi) bir çizim ve bir tuş fonksiyonu yazıp `ui_loop` ile birleştirir.

## Dil desteği

Arayüz Türkçe ve İngilizcedir (`lib/i18n.sh`). Kaynak dil Türkçedir: metinler kodda Türkçe yazılır ve çeviri anahtarı olarak kullanılır; İngilizce karşılıklar `locale/en.sh` içindeki `I18N_EN` dizisindedir.

- Dil sırası: `--lang`, `TS_LANG`, `language` ayarı (`tr|en|auto`), sistem dili (`LC_ALL`, `LC_MESSAGES`, `LANG`; `tr*` ise Türkçe, değilse İngilizce).
- `_t "Biçim %s" ARG...` çevirip `TR` değişkenine yazar; alt kabuk açmaz, `REPLY`'yi bozmaz. Zaten çevrilmiş bir metne uygulanırsa ona dokunmaz.
- **Değişkenler metnin içine yazılmaz**, printf argümanı olur: `log_err "Bilinmeyen bileşen: %s" "$id"`. Böylece anahtar sabit kalır.
- Metin alan arayüz fonksiyonları çeviriyi kendisi yapar: `log_*`, `ui_title`, `ui_section`, `ui_card_top`, `ui_confirm`, `ui_type_confirm`, `ui_menu`, `ui_checklist`, `ui_keys`, `diag_say`, `_verify_*`. Hazır satır alanlar (`ui_line`, `ui_center`, `ui_badge`, `ui_card_row`) ham metin alır; çeviriyi çağıran yapar.
- Bileşen, tema ve profil adları/açıklamaları kayıtta Türkçe tutulur, gösterilirken çevrilir (`comp_label`). Dil menüden değişince ekran hemen yeni dilde çizilir.
- Kullanıcının dosyalarına yazılan içerik (zsh parçalarındaki yorumlar) dile bağlı değildir; dil değişince dosyalar değişmez.

Testler: `tests/unit/i18n.bats` katalogdaki her çevirinin `%s` sayısını denetler. `tests/integration/english.bats` tüm akışı İngilizce çalıştırır; `TS_I18N_MISSING` dosyasına düşen eksik çeviri ya da çıktıda kalan Türkçe metin (Türkçe harf veya katalogdaki bir cümle) testi düşürür. `tests/unit/tui_layout.bats` her ekranı İngilizce de her boyutta çizer.

## Güncelleme

`update` komutu (`lib/upgrade.sh`) yalnızca script'in kurduğu parçaları yükseltir: GitHub'dan indirilen araçları son release'e, klonlanan depoları (Oh My Zsh, Powerlevel10k, eklentiler) son commit'e. apt paketleri sistemin işidir.

Neyin güncelleneceği ayrıca yazılmaz, bileşen dosyalarından okunur: bileşenin kurulum fonksiyonu prova modunda `ACT_RECIPE_CAPTURE=1` ile çalıştırılır ve `act_gh_binary` / `act_clone` ne kurduklarını tarif olarak bırakır. Yeni bir GitHub aracı eklemek, güncellemesini de kendiliğinden getirir.

- Kurulan sürümler `~/.terminal-setup/versions` dosyasında tutulur (`ad<TAB>etiket`).
- Deftere satır eklenmez: yollar zaten script'e ait (`path`) kayıtlıdır; kaldırma sürümden bağımsız siler.
- İkili dosya yanına kurulup yer değiştirilir; çalışan bir araç güncellenirken "Text file busy" olmaz.
- İzlenen dosyaları elle değiştirilmiş bir depo güncellenmez.

## Mimari kurallar

1. **Yan etki yalnızca `lib/actions/` içinde.** Başka bir yerde doğrudan `apt-get`, `sudo`, `chsh`, `gsettings set`, `dconf write`, `git config --global` kullanılamaz. `scripts/check_static.sh` bunu denetler.
2. **Bağımlılık tek yönlü:** frontends → runner → components → actions → ledger.
3. **Tema = veri, terminal = renderer.** Yeni tema tek palet dosyası, yeni terminal tek renderer.
4. **Idempotent:** Bir bileşeni iki kez kurmak hiçbir şeyi değiştirmez.
5. **Önceden var olana dokunma:** Yol yalnızca script onu oluşturduysa kaydedilir; paket yalnızca script kurduysa kaydedilir.
6. **Dosya başına en fazla 600 satır**, CI'da denetlenir. Fonksiyonlar 50 satırın altında tutulur.
7. **Kod standardı:** `set -uo pipefail`, isim alanlı fonksiyonlar (`ledger_*`, `act_*`, `undo_*`, `rend_*`, `comp_*`, `diag_*`), ShellCheck sıfır uyarı.

## Bileşen eklemek

`components/<kategori>/<ad>.sh`:

```bash
component_register bat "bat" tools "Renkli cat" ""

comp_bat_install() {
    act_pkg bat || return 1
    act_zsh_snippet 60 bat "alias cat='bat --paging=never'"
}

comp_bat_verify() { has_cmd batcat || has_cmd bat; }
```

- Kaldırma fonksiyonu yazılmaz; defter geri almayı genel olarak yapar.
- `verify`, bileşen sistemde varsa 0 döner. Script kurmadan önce `verify` başarılıysa bileşen "dış kurulum" sayılır ve dokunulmaz.
- GitHub release'inden araç için: `act_gh_binary owner/repo 'x86_64-deseni' 'aarch64-deseni' ikili`. Arşivden birden çok dosya (ör. yazı tipleri) için: `act_gh_extract owner/repo 'desen' HEDEF-DİZİN 'glob'...`.
- Kullanıcının sonradan değiştireceği bir ayar dosyası (btop.conf, wezterm.lua) yalnızca yoksa `act_seed_file` ile oluşturulur: kullanıcı verisi sayılır, üzerine yazılmaz, kaldırırken arşive taşınır.
- Aracın öğrettiği kısayollar `component_tip <ad> "Tuş ya da komut" "Ne yapar"` ile bildirilir; "Kısayollar" ekranı ve açılış ipucu yalnızca kurulu araçlarınkini gösterir.
- Kurulum ya da kaldırmadan sonra bir şey yenilenecekse (açılış ipucu, yazı tipi seçimi) çalıştırıcıya kanca eklenir: `RUNNER_AFTER_CHANGE+=(fonksiyon)`. Çalıştırıcı üst katmanları tanımaz.
- İstenirse `profiles/*.profile` dosyalarına eklenir.

## Tema eklemek

`themes/<ad>.theme`: `NAME`, `DESC`, `BACKGROUND`, `FOREGROUND`, `CURSOR`, `SELECTION_BG`, `SELECTION_FG`, `ACCENT`, `BORDER`, `COLOR0`–`COLOR15`. Dosya kaynak olarak yüklenmez (source edilmez), satır satır ayrıştırılır.

İsteğe bağlı alanlar:

| Alan | Anlamı |
|---|---|
| `BAT_THEME` | bat ve delta'nın söz dizimi teması; bat'ta yerleşik karşılığı yoksa `ansi` (terminalin 16 rengini kullanır). Gerçek Ubuntu'daki bat'ta adın bulunduğu CI'da denetlenir. |
| `VARIANT` | `dark` ya da `light` |
| `PAIR` | diğer tondaki eşi (`catppuccin` ↔ `catppuccin-latte`). Ptyxis paletine iki ton birlikte yazılır, terminal sistemin tonunu izler. |

## Renk rolleri

Temanın 16 rengi terminale olduğu gibi gider; temanın kimliği korunur. Terminal Setup'ın kendi çizdiği her şey (fzf, btop, tmux, tema önizlemesi) ise numaralı renkleri değil rolleri kullanır. `theme_load` rolleri `ROLE[...]` dizisine hesaplar (`lib/palette.sh`):

| Rol | Kaynak | Garanti (WCAG 2 kontrastı, arka plana karşı) |
|---|---|---|
| `fg`, `bg`, `border`, `cursor` | temadan olduğu gibi | `fg` en az 4.5:1 (testte denetlenir) |
| `accent` | `ACCENT` | en az 3:1 |
| `accent2`, `info`, `ok`, `warn`, `err` | `COLOR5`, `COLOR6`, `COLOR2`, `COLOR3`, `COLOR1` | en az 3:1 |
| `muted` | hesaplanır: arka plandan ön plana 4.5:1'e ulaşan ilk karışım | en az 4.5:1 |
| `sel`, `sel_fg` | `SELECTION_BG`, `SELECTION_FG` | seçim zemininde en az 4.5:1 |

Sınırın altında kalan renkli rol ön plana doğru gerektiği kadar kaydırılır. Seçim yazısı yetmiyorsa önce ön plan ya da arka plan rengi denenir, o da yetmiyorsa seçim zemini açılır.

`muted` temadan alınmaz, çünkü temaların "soluk" rengi (`COLOR8`) çoğu zaman okunmaz: 12 temanın 9'unda 3:1'in altında, Solarized'da 1,0:1. Sabit bir karışım oranı da yetmez: %55 karışım One Dark'ta 3,1:1, Nord'da 4,0:1 verir.

Hesap tek bir awk çağrısıdır ve gawk eklentisi kullanmaz; Ubuntu'nun varsayılanı mawk'tır. `tests/unit/palette.bats` her temada bütün sınırları ve mawk ile aynı sonucu denetler.

## Kişilikler

Tema = palet + kişilik. Palet renkleri, kişilik biçimi belirler: prompt simgesi ve yerleşimi, segment biçimi, kenar stili, büyük/küçük harf, ayırıcı, liste simgeleri, tarih biçimi, bat çerçevesi, git simgeleri. Kişilikler `styles/<ad>.style` veri dosyalarıdır; temalar gibi kaynak olarak yüklenmez, her değer `STYLE_CHOICES` listesiyle denetlenir (`lib/styles.sh`).

| Anahtar | Değerler |
|---|---|
| `PROMPT_SYMBOL` | prompt ve fzf imleci (`❯ › λ $ ▶`) |
| `PROMPT_LAYOUT` | `two-line`, `one-line` |
| `SEGMENTS` | `plain`, `minimal`, `powerline`, `pills`, `brackets`, `arrows` |
| `BORDER` | `rounded`, `sharp`, `heavy`, `double`, `none` (ince sol çizgi) |
| `TITLE_CASE`, `TEXT_CASE` | `normal`, `lower`, `upper` (Türkçede i/İ, ı/I doğru dönüşür) |
| `SEPARATOR`, `DATE_FORMAT`, `BAT_STYLE` | ayırıcı, `+strftime` biçimi, bat `--style` değeri |
| `ICONS`, `GIT_SYMBOLS` | `on`/`off`; `unicode`, `ascii`, `minimal` |

Temanın kişiliği `STYLE=` anahtarıdır. Kullanıcı başka birini seçebilir (`style set retro`, ayar: `style`); `auto` temanınkine döner. `theme_load` geçerli kişiliği `STYLE[...]` dizisine yükler; tüketiciler oradan okur. Kişilikten okuyanlar: Starship prompt'u, fzf (kenar, imleç, istem). Karşılama kartı ve diğer araçlar v7'nin sonraki adımlarında bağlanır ([plan](V7_PLAN.md)).

**Starship** (`renderers/starship.sh`, araç renderer'ı): ayar dosyası `~/.config/terminal-setup/starship.toml` rollerden ve kişilikten üretilir, tema ya da kişilik değişince yeniden yazılır; Starship onu `STARSHIP_CONFIG` ile okur, kullanıcının `~/.config/starship.toml`'una dokunulmaz. `SEGMENTS` prompt biçimini seçer (`plain`, `minimal`, `powerline`, `pills`, `brackets`, `arrows`). Tema uygulanmamışsa renkler terminalin kendi 16 renginin adlarından gelir. Nerd Font karakterleri dosyaya TOML kaçışı olarak yazılır; kaynakta ham Nerd Font karakteri bulunamaz (statik kontrol 7). Uçtan uca testte her kişilik gerçek Starship ile denetlenir.

Yeni kişilik: `styles/` altına bir dosya; kod gerekmez. `tests/unit/styles.bats` her dosyayı ve her temanın bağlantısını denetler.

## Terminal eklemek

`renderers/<ad>.sh`: `renderer_register <ad> "Ad" [terminal|tool]`, `rend_<ad>_available`, `rend_<ad>_apply` ve isteğe bağlı `rend_<ad>_font`. Terminal renderer'ları temanın 16 rengini `THEME[...]`'dan, araç renderer'ları metin renklerini `ROLE[...]`'dan okur; değişiklikler `act_*` ile yapılır.

Tür `terminal` (varsayılan) ya da `tool`'dur. Araç renderer'ları (tmux, bat/delta/fzf, btop) temayı bir araca uygular; durum ekranında ve teşhiste terminal sayılmazlar. Kullanıcının araç ayar dosyalarına dokunulmaz: bat/delta/fzf, Terminal Setup'ın kendi zsh parçasındaki ortam değişkenleriyle (`BAT_THEME`, `FZF_DEFAULT_OPTS`) ayarlanır.

Yazı tipi `rend_<ad>_font` ile uygulanır; hangi yazı tipinin uygulanacağını `lib/fonts.sh` belirler (`font` ayarı; seçili yazı tipinin bileşeni kaldırılırsa MesloLGS NF'ye dönülür).

## Testler

| Katman | Nerede | Ne doğrular |
|---|---|---|
| Statik | `scripts/check_static.sh` | sözdizimi, ShellCheck, 600 satır, yan etki kuralı, `curl \| sh` yasağı |
| Birim | `tests/unit/*.bats` | defter, bloklar, paketler, ayarlar, temalar, çalıştırıcı, arayüz yapı taşları, her ekranın her boyutta yerleşimi |
| Etkileşim | `tests/integration/tui_pty.bats` | tmux içinde gerçek terminalde tuşlarla gezinme, pencere boyutu değişimi, hızlı tuşta çöp olmaması, çıkışta ve Ctrl+C'de terminalin geri gelmesi |
| Entegrasyon | `tests/integration/*.bats` | CLI üzerinden kur → kaldır → fotoğrafla aynı mı |
| Uçtan uca | `tests/e2e/container.sh` | temiz Ubuntu 22.04/24.04/26.04 konteynerinde gerçek apt ve indirmelerle aynı döngü |
| Dil | `tests/unit/i18n.bats`, `tests/integration/english.bats` | katalog tutarlılığı, dil seçimi, tüm akışın İngilizce çalışması ve Türkçe metin sızmaması |
| GNOME | `tests/e2e/gnome.sh` | gerçek dconf + gsettings: yazılan her anahtar şemada var ve doğru tipte mi, kullanıcının ayarları korunuyor mu, kaldırınca `dconf dump /` aynı mı |

Birim ve entegrasyon testleri sahte bir sistemde çalışır (`tests/helpers/`): `apt-get`, `dpkg-query`, `sudo`, `chsh`, `dconf`, `git clone` ve `curl` taklitleri geçici bir dizinde durum tutar; gerçek sisteme dokunulmaz, ağa çıkılmaz.
