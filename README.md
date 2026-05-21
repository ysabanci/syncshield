# SyncShield

Kendi ev laboratuvarımda dağıtık mimarileri, Docker izolasyonunu ve Linux ağ güvenliğini uygulamalı olarak öğrenmek için geliştirdiğim P2P tabanlı bir siber güvenlik projesidir.

Sistem, düşük etkileşimli (low-interaction) bir honeypot mantığıyla çalışır. Ağdaki sunuculardan birine izinsiz bir SSH denemesi yapıldığında, sistemi korumaya alır, saldırganın konumunu tespit eder ve tüm ağdaki sunucularla bu bilgiyi eşzamanlı olarak paylaşarak IP adresini engeller.

## Geliştirme Motivasyonu
Bu projeyi, hazır siber güvenlik araçlarını kurup geçmek yerine, bir tehdit istihbarat ağının arka planda nasıl haberleştiğini ve Linux kernel seviyesindeki engellemelerin (iptables/ipset) nasıl otomatize edildiğini satır satır kodlayarak anlamak için tasarladım.

## Öne Çıkan Özellikler

* Dağıtık Mimari (P2P): Ağdaki konteynerlerden biri sahte portta bir sızma girişimi yakalarsa, inotifywait ve paylaşımlı hacimler (shared volumes) sayesinde milisaniyeler içinde diğer konteynerleri haberdar eder.
* O(1) Zaman Karmaşıklığı (IPSet): Binlerce IP adresini iptables ile satır satır engelleyip işlemciyi yormak yerine, veri merkezi standartlarında olan ipset karma tablolarını (hash table) kullandım. Bu sayede ağdaki paket kontrol süresi her zaman O(1) performansında kalır.
* GeoIP İstihbaratı: Yakalanan IP adresinin sadece numarasına bakmakla kalmaz, açık API'ler üzerinden ülkesini, şehrini ve internet servis sağlayıcısını (ASN) tespit eder.
* Telegram Entegrasyonu: Yakalanan tehditleri konum ve servis sağlayıcı bilgisiyle birlikte anında telefona NOC/SOC uyarısı olarak gönderir.
* Geliştirme ve Canlı Ortam Uyumluluğu: Projeyi ARM tabanlı Mac üzerinde Docker VM kısıtlamalarıyla geliştirdiğim için, iptables/ipset kernel modüllerinin desteklenmediği durumlarda sistemin çökmemesi amacıyla Bash scriptleri üzerinde fallback (simülasyon) mekanizmaları yazdım. Canlı ortamda (fiziksel Linux sunucuda) ise doğrudan network_mode: host ile fiziksel ağ kartını koruma altına alır.

## Kullanılan Teknolojiler
* Python 3: Soket programlama ile honeypot servisi.
* Bash Scripting: Asenkron dosya takibi, API entegrasyonu ve iptables/ipset yönetimi.
* Docker & Docker Compose: Servis izolasyonu ve sanal ağ yönetimi.

## Çalışma Mantığı
1. Honeypot servisi belirlenen sahte portta bağlantı bekler.
2. İzinsiz bağlantı geldiği an IP adresi ortak kara listeye yazılır.
3. Arka planda çalışan Watcher servisi dosya değişikliğini inotify ile yakalar.
4. Coğrafi veri API üzerinden çekilir, IPSet güncellenir ve Telegram botu tetiklenir.
