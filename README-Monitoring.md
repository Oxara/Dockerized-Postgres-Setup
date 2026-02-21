# Prometheus + Grafana Multi-Environment Monitoring Setup

Modern, best-practice yaklaşımıyla hazırlanmış multi-environment Monitoring kurulumu.

## 📁 Klasör Yapısı

```
monitoring/
├── environments/
│   ├── dev/
│   │   ├── docker-compose.yml
│   │   ├── prometheus.yml
│   │   └── .env
│   ├── test/
│   │   ├── docker-compose.yml
│   │   ├── prometheus.yml
│   │   └── .env
│   └── prod/
│       ├── docker-compose.yml
│       ├── prometheus.yml
│       └── .env
```

## ✨ Özellikler

- ✅ **Prometheus**: Time-series database ve metrics collection
- ✅ **Grafana**: Powerful visualization ve dashboards
- ✅ **Tamamen İzole Ortamlar**: Her ortam kendi klasöründe
- ✅ **Güvenli**: Authentication enabled, .env dosyaları Git'e yüklenmiyor
- ✅ **Kolay Yönetim**: Hazır scriptler ile tek komutla yönetim
- ✅ **Çakışma Yok**: Her ortam farklı portlarda çalışır
- ✅ **Persistence**: Volume'ler ile veri kalıcılığı
- ✅ **Health Checks**: Container durumu otomatik kontrol
- ✅ **Auto-configured**: Prometheus Grafana'ya otomatik data source olarak eklenir

## 🚀 Hızlı Başlangıç

### 1️⃣ Kurulum

**Depoyu klonladıktan sonra her ortam için `.env` dosyasını oluşturun:**

```powershell
# Her ortam için .env.example'dan kopyala
Copy-Item environments\dev\.env.example environments\dev\.env
Copy-Item environments\test\.env.example environments\test\.env
Copy-Item environments\prod\.env.example environments\prod\.env
```

**Güvenlik için Grafana şifresini değiştirin:**

```powershell
# environments/dev/.env
GRAFANA_ADMIN_PASSWORD=güçlü_dev_şifresi

# environments/test/.env
GRAFANA_ADMIN_PASSWORD=güçlü_test_şifresi

# environments/prod/.env
GRAFANA_ADMIN_PASSWORD=ÇOK_GÜÇLÜ_PROD_ŞİFRESİ_123!@#
```

### 2️⃣ Ortamı Başlatma

**Yönetim Scripti (Önerilen):**

```powershell
# Windows PowerShell
.\manage.ps1 start dev monitoring
```

**Manuel Yol:**

```powershell
# Development ortamını başlat
Set-Location monitoring\environments\dev
docker-compose up -d

# veya kök dizinden
docker-compose -f monitoring/environments/dev/docker-compose.yml up -d
```

### 3️⃣ Erişim

**Development (dev):**
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000
  - Username: `admin`
  - Password: `.env` dosyasındaki `GRAFANA_ADMIN_PASSWORD`

**Test:**
- **Prometheus**: http://localhost:9091
- **Grafana**: http://localhost:3001

**Production (prod):**
- **Prometheus**: http://localhost:9092
- **Grafana**: http://localhost:3002

## 📋 Komutlar

### Yönetim Scripti ile

```powershell
# Başlatma
.\manage.ps1 start dev monitoring
.\manage.ps1 start test monitoring
.\manage.ps1 start prod monitoring

# Durdurma
.\manage.ps1 stop dev monitoring

# Yeniden başlatma
.\manage.ps1 restart dev monitoring

# Logları görüntüleme
.\manage.ps1 logs dev monitoring

# Durum kontrolü
.\manage.ps1 status dev monitoring

# Temizleme (TÜM VERİLER SİLİNİR!)
.\manage.ps1 clean dev monitoring
```

### Manuel Docker Compose Komutları

```powershell
# Ortama git
Set-Location monitoring\environments\dev

# Başlat
docker-compose up -d

# Durdur
docker-compose down

# Logları göster
docker-compose logs -f

# Durum kontrol
docker-compose ps

# Yeniden başlat
docker-compose restart

# Temizle (volumes dahil)
docker-compose down -v
```

## 🔧 Yapılandırma

### Port Dağılımı

| Ortam       | Prometheus | Grafana |
|-------------|------------|---------|
| Development | 9090       | 3000    |
| Test        | 9091       | 3001    |
| Production  | 9092       | 3002    |

### Ortam Değişkenleri

```env
# Prometheus Settings
PROMETHEUS_PORT=9090

# Grafana Settings
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your_password_here
GRAFANA_PORT=3000
```

## 📊 Prometheus Yapılandırması

### Temel prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

### Servis Ekleme

Her servis için `prometheus.yml` dosyasına yeni bir job ekleyin:

```yaml
scrape_configs:
  # Prometheus kendisi
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # PostgreSQL Exporter
  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']

  # Node Exporter
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  # MongoDB Exporter
  - job_name: 'mongodb'
    static_configs:
      - targets: ['mongodb-exporter:9216']
```

### Config Reload

```powershell
# prometheus.yml değiştirdikten sonra restart edin
.\manage.ps1 restart dev monitoring

# Veya sadece Prometheus container'ını yeniden başlatın
Set-Location monitoring\environments\dev
docker-compose restart prometheus
```

## 🎨 Grafana Yapılandırması

### İlk Giriş

1. http://localhost:3000 adresine gidin
2. Username: `admin`
3. Password: `.env` dosyasındaki şifre
4. İlk girişte şifre değiştirmeniz istenebilir

### Prometheus Data Source Ekleme

Grafana otomatik olarak Prometheus'u data source olarak ekler. Manuel eklemek için:

1. Configuration → Data Sources
2. Add data source
3. Prometheus seçin
4. URL: `http://prometheus:9090`
5. Save & Test

### Dashboard İçe Aktarma

Hazır dashboardlar için:

1. Create → Import
2. Dashboard ID girin (örn: 1860 - Node Exporter Full)
3. Prometheus data source seçin
4. Import

**Popüler Dashboard ID'leri:**
- **1860**: Node Exporter Full
- **7362**: PostgreSQL Database
- **763**: Redis Dashboard
- **2949**: MongoDB Dashboard
- **11159**: RabbitMQ Overview

## 💾 Veri Yönetimi

### Volume'ler

Her ortamın kendine ait volume'leri var:

```
prometheus_dev_data       # Dev metrics
grafana_dev_data          # Dev dashboards
prometheus_test_data      # Test metrics
grafana_test_data         # Test dashboards
prometheus_prod_data      # Prod metrics
grafana_prod_data         # Prod dashboards
```

### Retention Policy

Production için data retention ayarlayın:

```yaml
# prometheus.yml (prod)
command:
  - '--storage.tsdb.retention.time=30d'  # 30 gün sakla
```

### Backup

```powershell
# Grafana backup
docker exec grafana_dev tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana
docker cp grafana_dev:/tmp/grafana-backup.tar.gz ./grafana-backup_$(Get-Date -Format 'yyyyMMdd').tar.gz

# Prometheus backup
docker exec prometheus_dev tar czf /tmp/prometheus-backup.tar.gz /prometheus
docker cp prometheus_dev:/tmp/prometheus-backup.tar.gz ./prometheus-backup_$(Get-Date -Format 'yyyyMMdd').tar.gz
```

## 🔍 Monitoring Örnekleri

### Temel PromQL Sorguları

```promql
# CPU kullanımı
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory kullanımı
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk kullanımı
100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"})

# HTTP request rate
rate(http_requests_total[5m])
```

### Alert Rules

`prometheus.yml` içine alert rules ekleyin:

```yaml
rule_files:
  - "alerts.yml"

# alerts.yml dosyası oluşturun
groups:
  - name: example
    rules:
    - alert: HighMemoryUsage
      expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected"
```

## 🎯 Exporter Ekleme

### Node Exporter (Sunucu Metrikleri)

```yaml
# docker-compose.yml'e ekleyin
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter_dev
    restart: unless-stopped
    ports:
      - "9100:9100"
    networks:
      - monitoring_network
```

### PostgreSQL Exporter

```yaml
  postgres-exporter:
    image: prometheuscommunity/postgres-exporter:latest
    container_name: postgres-exporter_dev
    restart: unless-stopped
    environment:
      DATA_SOURCE_NAME: "postgresql://user:pass@postgres:5432/db?sslmode=disable"
    ports:
      - "9187:9187"
    networks:
      - monitoring_network
```

### Redis Exporter

```yaml
  redis-exporter:
    image: oliver006/redis_exporter:latest
    container_name: redis-exporter_dev
    restart: unless-stopped
    environment:
      REDIS_ADDR: "redis:6379"
      REDIS_PASSWORD: "your_password"
    ports:
      - "9121:9121"
    networks:
      - monitoring_network
```

## 🔐 Güvenlik

### Öncelikli Güvenlik Adımları

1. **Grafana Şifresini Değiştirin**: İlk girişte güçlü şifre belirleyin
2. **Anonymous Access**: Production'da kapatın
3. **SSL/TLS**: Production'da reverse proxy ile HTTPS kullanın
4. **Network İzolasyonu**: Her ortam kendi network'ünde

### Grafana Güvenlik Ayarları

Grafana için `grafana.ini` dosyası mount edebilirsiniz:

```yaml
volumes:
  - grafana_data:/var/lib/grafana
  - ./grafana.ini:/etc/grafana/grafana.ini
```

## 🔍 Sorun Giderme

### Prometheus metrics toplayamıyor

```powershell
# Configuration kontrolü
docker exec prometheus_dev promtool check config /etc/prometheus/prometheus.yml

# Target'ları kontrol edin
# http://localhost:9090/targets
```

### Grafana dashboard görünmüyor

```powershell
# Grafana logları
docker logs grafana_dev

# Prometheus data source test edin
# Configuration → Data Sources → Prometheus → Test
```

### Port çakışması

```powershell
# Kullanılan portları kontrol edin
netstat -ano | findstr :9090
netstat -ano | findstr :3000

# .env dosyasında farklı port ayarlayın
PROMETHEUS_PORT=9093
GRAFANA_PORT=3003
```

## 📊 Dashboard Örnekleri

### Kritik Metrikler Dashboard

1. System Overview
   - CPU Usage
   - Memory Usage
   - Disk Usage
   - Network I/O

2. Application Metrics
   - HTTP Request Rate
   - Response Time
   - Error Rate
   - Active Connections

3. Database Metrics
   - Query Performance
   - Connection Pool
   - Cache Hit Rate
   - Transaction Rate

## 🎯 Best Practices

1. **Scrape Interval**: Development için 15s, Production için 30s
2. **Retention**: Development için 7 gün, Production için 30+ gün
3. **Alerting**: Kritik metrikler için alert kuralları tanımlayın
4. **Dashboards**: Her servis için dedicated dashboard
5. **Labels**: Metrics'lere anlamlı label'lar ekleyin

## 📚 Ek Kaynaklar

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Tutorial](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)
- [Exporters List](https://prometheus.io/docs/instrumenting/exporters/)

## 🆘 Destek

Sorun yaşıyorsanız:

1. Container loglarını kontrol edin
2. Prometheus targets sayfasını kontrol edin
3. Grafana data source bağlantısını test edin
4. prometheus.yml syntax'ını kontrol edin
5. Port çakışması olmadığından emin olun

## 🚀 İleri Seviye

### AlertManager Ekleme

```yaml
  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager_dev
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
    networks:
      - monitoring_network
```

### Grafana Plugins

```yaml
environment:
  - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
```

### External Networks

Diğer servisleri monitoring etmek için external network kullanın:

```yaml
networks:
  monitoring_network:
    external: true
    name: postgres_dev_network
```

---

**Hazırlayan:** Docker Monitoring Multi-Environment Setup  
**Son Güncelleme:** 2026-02-21  
**Versiyon:** 1.0.0
