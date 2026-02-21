# Changelog

Bu proje [Keep a Changelog](https://keepachangelog.com/tr/1.0.0/) formatını ve
[Semantic Versioning](https://semver.org/lang/tr/) prensiplerini takip etmektedir.

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


