# Katkıda Bulunma

Katkı göndermeden önce lütfen statik kontrolleri çalıştırın.

```bash
git clone https://github.com/alibedirhan/Terminal-Setup.git
cd Terminal-Setup

bash scripts/check_static.sh
bash scripts/check_repo_links.sh
```

## Basit akış

```bash
git checkout -b fix/kisa-aciklama
# değişiklikleri yap
git add .
git commit -m "fix: kisa aciklama"
git push origin fix/kisa-aciklama
```

Sonra GitHub üzerinden Pull Request açın.

## Dikkat edilmesi gerekenler

- Kullanıcının shell/config dosyalarına dokunan her işlem yedekli olmalı.
- Yeni indirme URL'leri açık ve okunabilir olmalı.
- `curl | bash` tarzı doğrudan pipe kullanımı mümkün olduğunca tercih edilmemeli.
- Ubuntu dışı sistemler için garanti vermeyin; destek durumunu açık yazın.
- Kişisel isim, yerel dosya yolu veya özel bilgi commit etmeyin.
