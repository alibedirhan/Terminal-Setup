# Güvenlik ve Kullanıcı Verisi Notları

Terminal Setup bazı kullanıcı yapılandırma dosyalarını değiştirebilir. Bu nedenle şu kurallar korunmalıdır:

- Root olarak çalıştırılmamalı.
- İşlem öncesi yedek alınmalı.
- `.zshrc`, `.bashrc`, `.tmux.conf`, `.p10k.zsh` gibi dosyalar doğrudan silinmemeli.
- İndirilen harici kurulum scriptleri mümkünse geçici dosyaya alınarak çalıştırılmalı.
- Loglar ve yedekler repoya eklenmemeli.
- Kullanıcıdan açık onay almadan shell değiştirme gibi işlemler yapılmamalı.

Kullanıcı logları varsayılan olarak şu dizindedir:

```text
~/.terminal-setup/logs
```

Yedekler:

```text
~/.terminal-setup/backups
```
