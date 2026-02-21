# Changelog

Bu proje [Keep a Changelog](https://keepachangelog.com/tr/1.0.0/) formatını ve
[Semantic Versioning](https://semver.org/lang/tr/) prensiplerini takip etmektedir.

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

