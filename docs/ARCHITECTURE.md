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

`init.zsh`, `zsh.d/` altındaki parçaları sıra numarasıyla yükler (`05-p10k-instant`, `15-ohmyzsh-base`, `40-ohmyzsh-load`, `60-fzf` ...).

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
- GitHub release'inden araç için: `act_gh_binary owner/repo 'x86_64-deseni' 'aarch64-deseni' ikili`.
- İstenirse `profiles/*.profile` dosyalarına eklenir.

## Tema eklemek

`themes/<ad>.theme`: `NAME`, `DESC`, `BACKGROUND`, `FOREGROUND`, `CURSOR`, `SELECTION_BG`, `SELECTION_FG`, `ACCENT`, `BORDER`, `COLOR0`–`COLOR15`. Dosya kaynak olarak yüklenmez (source edilmez), satır satır ayrıştırılır.

## Terminal eklemek

`renderers/<ad>.sh`: `renderer_register`, `rend_<ad>_available`, `rend_<ad>_apply` ve isteğe bağlı `rend_<ad>_font`. Renkler `THEME[...]` dizisinden okunur, değişiklikler `act_*` ile yapılır.

## Testler

| Katman | Nerede | Ne doğrular |
|---|---|---|
| Statik | `scripts/check_static.sh` | sözdizimi, ShellCheck, 600 satır, yan etki kuralı, `curl \| sh` yasağı |
| Birim | `tests/unit/*.bats` | defter, bloklar, paketler, ayarlar, temalar, çalıştırıcı, arayüz yapı taşları, her ekranın her boyutta yerleşimi |
| Etkileşim | `tests/integration/tui_pty.bats` | tmux içinde gerçek terminalde tuşlarla gezinme, pencere boyutu değişimi, hızlı tuşta çöp olmaması, çıkışta ve Ctrl+C'de terminalin geri gelmesi |
| Entegrasyon | `tests/integration/*.bats` | CLI üzerinden kur → kaldır → fotoğrafla aynı mı |
| Uçtan uca | `tests/e2e/container.sh` | temiz Ubuntu 22.04/24.04 konteynerinde gerçek apt ve indirmelerle aynı döngü |

Birim ve entegrasyon testleri sahte bir sistemde çalışır (`tests/helpers/`): `apt-get`, `dpkg-query`, `sudo`, `chsh`, `dconf`, `git clone` ve `curl` taklitleri geçici bir dizinde durum tutar; gerçek sisteme dokunulmaz, ağa çıkılmaz.
