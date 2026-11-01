# Kullanıcı Verisi ve Güvenlik Notları

Terminal Setup'ın kullanıcı verisine nasıl davrandığının özeti. Ayrıntılar: [ARCHITECTURE.md](ARCHITECTURE.md).

## Neye dokunur?

| Dosya / ayar | Nasıl |
|---|---|
| `~/.zshrc` | En üste tek bir işaretli blok eklenir. Orijinal dosya önce kopyalanır. |
| `~/.tmux.conf` | Sona tek bir işaretli blok (yalnızca tmux bileşeni seçilirse). |
| `~/.gitconfig` | Yalnızca delta bileşeni: `core.pager`, `interactive.diffFilter`, `delta.navigate`, `merge.conflictStyle`, `diff.colorMoved`. Önceki değerler kaydedilir. |
| GNOME Terminal / Ptyxis profili | Renk ve yazı tipi anahtarları (dconf). Önceki değerler kaydedilir. |
| `kitty.conf`, `alacritty.toml` | Tek satırlık işaretli blok; renkler ayrı dosyada. |
| Giriş kabuğu | Zsh bileşeni `chsh` ile zsh yapar; orijinali kaydedilir. |

## Kaldırmada ne olur?

- Script'in oluşturduğu her şey silinir; değiştirdiği her şey kurulum öncesi değerine döner.
- **Kurulumdan önce var olan hiçbir şey silinmez.** Paketler, dosyalar ve dizinler yalnızca script oluşturduysa kaydedilir.
- Kullanımla oluşan veriler silinmez, arşive taşınır: `~/.zsh_history`, `~/.p10k.zsh`, zoxide ve atuin veritabanları, lazygit, btop ve atuin'in ayar dosyaları.
- Kurulumdan sonra elle değiştirdiğiniz bir ayar dosyası orijinaline döndürülür; son hali arşive kopyalanır.
- Arşiv: `~/terminal-setup-kaldirilan-TARİH/`, İngilizce sistemde `~/terminal-setup-removed-DATE/` (kaldırma raporu ve log dahil).

## Durum dosyaları

```text
~/.terminal-setup/ledger     değişiklik defteri
~/.terminal-setup/baseline/  başlangıç fotoğrafı
~/.terminal-setup/files/     değiştirilen dosyaların orijinal kopyaları
~/.terminal-setup/logs/      log
```

Tam kaldırmadan sonra bu dizin de silinir. `status`, `list`, `doctor` gibi yalnızca okuyan komutlar hiçbir dosya oluşturmaz.
