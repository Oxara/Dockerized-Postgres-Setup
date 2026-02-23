# Changelog

Bu proje [Keep a Changelog](https://keepachangelog.com/tr/1.0.0/) formatını ve
[Semantic Versioning](https://semver.org/lang/tr/) prensiplerini takip etmektedir.

---

## [1.3.0] - 2026-02-23

### Eklendi
- **n8n** (Workflow Automation) — dev / test / prod ortamları
  - `n8nio/n8n:latest` image, SQLite backend, dahili Web UI
  - Basic auth ve `N8N_ENCRYPTION_KEY` desteği
  - MailHog (SMTP), RabbitMQ, PostgreSQL, Redis ve diğer stack servisleriyle entegrasyon örnekleri
  - Webhook kullanımı ve zamanlanmış görev (cron) senaryoları
  - Backup / restore ve n8n CLI export/import dokümantasyonu
- `manage.ps1` güncellendi: `n8n` servisi eklendi (`start`, `stop`, `restart`, `logs`, `status`, `clean`, `purge`, `pull`)
- `README-n8n.md` oluşturuldu
- `BRD.md` güncellendi: §2.12 n8n servis gereksinimleri, port tabloları ve Ek B karşılaştırma tablosu eklendi
- `README.md` güncellendi: servis kataloğu, port tablosu ve dokümantasyon linkleri güncellendi

### Port Atamaları
| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| n8n Web UI | 5678 | 5679 | 5680 |

---

## [1.2.0] - 2026-02-21

### Eklendi
- `manage.ps1` — `pull` komutu eklendi: `docker-compose pull` ile image'ları indirir
  - **Akıllı pull**: Tüm image'lar lokalde mevcutsa pull atlanır (`= Already exists` gösterilir)
  - `all` ile `start`, `stop`, `restart`'ın yanı sıra `pull` da artık **paralel** çalışır

### Değişti
- `manage.ps1` — `all` komutu için anlık servis listesi ve sonuç tablosu **birleştirildi**:
  - İşlem sırasında servisler canlı olarak güncellenen liste şeklinde gösterilir
  - İşlem bitince liste, geçen süre (`(1s)`, `(3s)`) dahil özet tablo ile değiştirilir
- `manage.ps1` — sonuç tablosundan Container, Volume ve Image sütunları kaldırıldı; tablo yalnızca **Service / Environment / Status** gösteriyor
- `manage.ps1` — `NotFound` durumu artık tabloda kırmızı renkte gösteriliyor
- `manage.ps1` — sequential `start` / `stop` fonksiyonlarında container ID hex filtreleme düzeltildi (paralel versiyon ile tutarlı hale getirildi)
- `README.md` — yeni `pull` komutu, akıllı pull davranışı ve paralel çalışma dokümante edildi
- `README.md` — "Image Güncelleme" bölümü `manage.ps1 pull` kullanımına yönlendirildi

---

## [1.1.0] - 2026-02-21

### Eklendi
- **MSSQL (SQL Server 2022)** + Adminer — dev / test / prod ortamları
  - EF Core ve Microsoft.Data.SqlClient .NET örnekleri
  - Migration yönetimi ve backup/restore dokümantasyonu
- **Keycloak 26** + PostgreSQL sidecar — dev / test / prod ortamları
  - OAuth2 / OIDC JWT token doğrulama (ASP.NET Core)
  - Blazor Server OIDC entegrasyonu
  - Admin API kullanım örnekleri
- **Seq** (Structured Log Server) — dev / test / prod ortamları
  - Serilog ve NLog sink entegrasyonu
  - FilterExpressions sorgulama örnekleri
  - Production API key ve şifre desteği
- **MailHog** (Fake SMTP Server) — dev / test / prod ortamları
  - MailKit ile e-posta servisi (.NET)
  - Integration test için MailHog REST API kullanımı
- `manage.ps1` güncellendi: `mssql`, `keycloak`, `seq`, `mailhog` servisleri eklendi
- `README-MSSQL.md`, `README-Keycloak.md`, `README-Seq.md`, `README-MailHog.md` oluşturuldu
- `README.md` yeni servis port tabloları, örnek komutlar ve dokümantasyon linkleri ile güncellendi

---

## [1.0.0] - 2026-02-21

İlk public sürüm.

### Servisler
- **PostgreSQL** + pgAdmin — dev / test / prod ortamları
- **Redis** + RedisInsight — dev / test / prod ortamları
- **RabbitMQ** + Management UI — dev / test / prod ortamları
- **Elasticsearch** + Kibana — dev / test / prod ortamları
- **MongoDB** + Mongo Express — dev / test / prod ortamları
- **Monitoring**: Prometheus + Grafana — dev / test / prod ortamları

### Özellikler
- `manage.ps1` ile tek komutla tüm servisleri veya seçili servisi yönetme (`start`, `stop`, `restart`, `logs`, `status`, `clean`)
- Her servis ve ortam tamamen izole; çakışan port yok
- `.env.example` şablon dosyaları — gerçek `.env` dosyaları `.gitignore` ile korunuyor
- Health check yapılandırması tüm servislerde aktif
- Named volume ve network ile veri kalıcılığı
- Windows + .NET Core odaklı kapsamlı dokümantasyon (her servis için ayrı README)


