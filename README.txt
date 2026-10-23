KASIRKU + SUPABASE — GITHUB PAGES

ISI:
- public/index.html: aplikasi web kasir, pendaftaran email, setup toko, dan cetak struk
- public/manifest.json: metadata PWA
- supabase-schema.sql: tabel, RLS, RPC transaksi/stok, dan RPC setup owner dari web
- .github/workflows/pages.yml: deploy otomatis dari folder public

SETUP:
1. Untuk proyek Supabase baru, jalankan seluruh supabase-schema.sql sekali di SQL Editor. Proyek KasirKu yang sudah dibuat telah menerima fungsi onboarding ini.
2. Buka https://shopppit1-tech.github.io/kasirku/.
3. Tekan “Buat akun”, masukkan email dan password, lalu konfirmasi email dari inbox.
4. Kembali ke website, masuk dengan email/password, lalu isi nama toko. Alamat, nomor telepon, dan nama pemilik bersifat opsional.
5. Setelah masuk, tambahkan produk dan uji transaksi.
6. Tambahkan foto acuan pada setiap produk melalui menu Produk.
7. Untuk mengenali produk dari foto, tekan “📷 Foto” di Kasir, arahkan kamera ke kemasan, lalu ambil foto. Nama, harga, dan stok kandidat paling mirip akan ditampilkan; cocokkan produk lalu tekan “Pilih” untuk menambahkannya ke keranjang. Pencocokan foto berjalan di perangkat dan memerlukan koneksi internet untuk memuat model. Fitur ini menggunakan foto acuan, jadi hasil perlu diperiksa untuk produk dengan kemasan serupa.
8. Untuk transaksi lebih cepat, pemindai barcode USB/Bluetooth bisa langsung dipakai pada kolom Kasir; setelah kode cocok, nama, harga, qty, dan stok tampil, item ditambahkan, lalu kolom siap untuk scan berikutnya. Nominal tunai cepat muncul otomatis sesuai total.

PENGGUNA KASIR:
Untuk menambahkan kasir, buat akun Auth untuk email kasir, lalu buat profile role `cashier` dengan store_id toko yang sama. Jangan pernah memakai service_role/secret key di frontend. Publishable key di HTML aman hanya selama kebijakan RLS tetap aktif.

DEPLOY:
Perubahan pada branch main otomatis diterbitkan ke GitHub Pages dari folder public. Repository GitHub saat ini publik sesuai permintaan pemilik.

CETAK STRUK:
- Setelah transaksi berhasil, struk ditampilkan dan pengguna dapat memilih Thermal 58 mm, Thermal 80 mm, atau kertas biasa.
- Tombol Cetak Struk membuka dialog print browser. Di Android, pasangkan printer pada pengaturan HP dan pilih printer dari dialog cetak jika didukung.
- Untuk printer thermal Bluetooth klasik yang tidak muncul di dialog browser, perlu aplikasi Android/bridge ESC-POS khusus model printer. Web statis tidak bisa menjamin akses Bluetooth langsung ke semua printer.

PENTING:
- Uji dengan akun dan transaksi uji sebelum dipakai pada toko aktif.
- Jangan menonaktifkan RLS. Email confirmation wajib pada konfigurasi Auth proyek ini.
- Tidak ada sinkronisasi saat perangkat offline; realtime berjalan saat koneksi tersedia.
