# n8n — Workflow Automation

Bu dokümantasyon, Docker Service Stack içindeki **n8n** servisinin kurulumu, yapılandırması ve kullanımına ilişkin detayları içermektedir.

## 📦 Bileşenler

| Bileşen | Image | Açıklama |
|---------|-------|----------|
| **n8n** | `n8nio/n8n:latest` | Workflow otomasyon motoru + dahili Web UI |

## 🚀 Hızlı Başlangıç

```powershell
# .env dosyasını oluştur
Copy-Item n8n\environments\dev\.env.example n8n\environments\dev\.env

# Servisi başlat
.\manage.ps1 start dev n8n

# Web UI'a eriş
# http://localhost:5678
```

## 🔧 Yapılandırma

### Ortam Değişkenleri

| Değişken | Zorunlu | Varsayılan (Dev) | Açıklama |
|----------|:-------:|------------------|----------|
| `N8N_PORT` | EVET | `5678` | Web UI host port |
| `N8N_HOST` | EVET | `localhost` | Erişim host adı |
| `N8N_PROTOCOL` | EVET | `http` | `http` veya `https` |
| `WEBHOOK_URL` | EVET | `http://localhost:5678/` | Webhook temel URL'si |
| `N8N_BASIC_AUTH_ACTIVE` | EVET | `true` | Temel kimlik doğrulama |
| `N8N_BASIC_AUTH_USER` | EVET | `admin` | Web UI kullanıcı adı |
| `N8N_BASIC_AUTH_PASSWORD` | EVET | — | Web UI şifresi |
| `N8N_ENCRYPTION_KEY` | EVET | — | Kimlik bilgisi şifreleme anahtarı |
| `GENERIC_TIMEZONE` | HAYIR | `Europe/Istanbul` | Zamanlama (cron) zaman dilimi |

> ⚠️ **`N8N_ENCRYPTION_KEY`**: İlk çalıştırmadan sonra **asla değiştirmeyin**. Değiştirilirse kayıtlı tüm kimlik bilgileri çözülemez hale gelir.

### Şifreleme Anahtarı Üretme

```powershell
# Güvenli rastgele anahtar (64 karakter hex)
[System.Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)).ToLower()

# veya OpenSSL yüklüyse
openssl rand -hex 32
```

### Port Dağılımı

| Bileşen | Dev | Test | Prod |
|---------|-----|------|------|
| n8n Web UI | 5678 | 5679 | 5680 |

## 🌐 Arayüze Erişim

| Ortam | URL | Kullanıcı |
|-------|-----|-----------|
| Dev   | http://localhost:5678 | `.env` → `N8N_BASIC_AUTH_USER` |
| Test  | http://localhost:5679 | `.env` → `N8N_BASIC_AUTH_USER` |
| Prod  | http://localhost:5680 | `.env` → `N8N_BASIC_AUTH_USER` |

## 📖 n8n ile .NET Entegrasyonu

### HTTP Request Node ile REST API Çağrısı

n8n'de herhangi bir .NET Web API'ye **HTTP Request** node kullanılarak bağlanılabilir:

1. n8n Web UI → **New Workflow**
2. **+** → **HTTP Request** node ekle
3. Method: `GET` / `POST` / `PUT` / `DELETE`
4. URL: `http://host.docker.internal:5000/api/endpoint`
   > `host.docker.internal` — Docker container'dan host makinesine erişim

### Webhook ile .NET Uygulaması Tetikleme

```csharp
// .NET uygulamasından n8n webhook tetikleme
using var client = new HttpClient();

var payload = new { event = "order.created", orderId = 42 };
var json    = JsonSerializer.Serialize(payload);
var content = new StringContent(json, Encoding.UTF8, "application/json");

// Dev ortamı için
var webhookUrl = "http://localhost:5678/webhook/your-webhook-id";
var response   = await client.PostAsync(webhookUrl, content);
```

### n8n'den .NET API'ye İstek Göndermek

n8n HTTP Request node'unda header ekleyin:

```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer your-api-token"
}
```

## 🔁 Örnek Workflow Senaryoları

### Senaryo 1: RabbitMQ → n8n → Veritabanı

```
RabbitMQ Trigger Node
  → Mesajı al
  → Transform (Set node)
  → HTTP Request (PostgreSQL REST API veya doğrudan Postgres node)
  → Slack/Email bildirim
```

### Senaryo 2: Zamanlanmış Görev (Cron)

```
Cron Trigger (her gün 08:00)
  → HTTP Request (raporlama API)
  → MailHog / SMTP (e-posta gönder)
```

### Senaryo 3: Webhook Dinleyici

```
Webhook Trigger ('/order-created')
  → HTTP Request (stok servisi)
  → IF node (stok yeterliyse)
    → RabbitMQ'ya mesaj gönder
    → Fatura servisi çağır
```

## 🔌 Diğer Stack Servisleriyle Entegrasyon

n8n, aynı Docker host üzerindeki diğer servislere `host.docker.internal` veya `localhost` üzerinden bağlanabilir:

| Servis | n8n İçinden Erişim URL |
|--------|------------------------|
| PostgreSQL | `postgresql://user:pass@host.docker.internal:5432/db` |
| Redis | `redis://:password@host.docker.internal:6379` |
| RabbitMQ | `amqp://user:pass@host.docker.internal:5672` |
| Elasticsearch | `http://host.docker.internal:9200` |
| MongoDB | `mongodb://user:pass@host.docker.internal:27017` |
| MailHog SMTP | host: `host.docker.internal`, port: `1025` |
| Seq (log) | n8n loglarını Seq'e yönlendirmek için HTTP node kullanın |

> 💡 n8n'in kendi network'ü izoledir (`n8n_{ortam}_network`). Diğer stack servislerine container adı üzerinden değil, `host.docker.internal` üzerinden ulaşılır.

## 🛡️ Güvenlik

### Development / Test

- Basic auth aktif olmalı (`N8N_BASIC_AUTH_ACTIVE=true`)
- Basit şifreler kabul edilebilir
- `N8N_ENCRYPTION_KEY` yine de güçlü olmalı

### Production

- **Güçlü şifre**: `N8N_BASIC_AUTH_PASSWORD` minimum 20 karakter
- **Güçlü encryption key**: `openssl rand -hex 32` ile üretin
- `N8N_PROTOCOL=https` ve bir reverse proxy (nginx/Traefik) önerilir
- `WEBHOOK_URL` gerçek domain ile ayarlanmalı
- `N8N_ENCRYPTION_KEY` yedeklenmeli — kaybedilirse tüm kimlik bilgileri sıfırlanmak zorunda kalınır

## 🔄 Yedekleme ve Geri Yükleme

n8n tüm verilerini (workflow'lar, kimlik bilgileri, çalışma geçmişi) `/home/node/.n8n` dizininde tutar. Bu dizin `n8n_{ortam}_data` volume'üne bağlıdır.

### Manuel Yedekleme

```powershell
# Volume içeriğini tar olarak dışa aktar
docker run --rm `
  -v n8n_dev_data:/source `
  -v ${PWD}:/backup `
  alpine tar czf /backup/n8n_dev_backup_$(Get-Date -Format yyyyMMdd).tar.gz -C /source .
```

### Yedekten Geri Yükleme

```powershell
# Servisi durdur
.\manage.ps1 stop dev n8n

# Volume'ü geri yükle
docker run --rm `
  -v n8n_dev_data:/target `
  -v ${PWD}:/backup `
  alpine sh -c "cd /target && tar xzf /backup/n8n_dev_backup_20260223.tar.gz"

# Servisi yeniden başlat
.\manage.ps1 start dev n8n
```

### n8n Yerleşik Export/Import (Workflow'lar)

```powershell
# Tüm workflow'ları JSON olarak dışa aktar
docker exec n8n_dev n8n export:workflow --all --output=/home/node/.n8n/workflows_export.json

# Workflow'ları içe aktar
docker exec n8n_dev n8n import:workflow --input=/home/node/.n8n/workflows_export.json
```

## 📋 Yönetim Komutları

```powershell
# Başlat
.\manage.ps1 start dev n8n

# Durdur
.\manage.ps1 stop dev n8n

# Yeniden başlat
.\manage.ps1 restart dev n8n

# Canlı log izle
.\manage.ps1 logs dev n8n

# Durum kontrolü
.\manage.ps1 status dev n8n

# Veriyi silerek temizle ⚠️
.\manage.ps1 clean dev n8n

# Image dahil tüm varlıkları sil 💀
.\manage.ps1 purge dev n8n
```

## 🔍 Sorun Giderme

### Web UI Açılmıyor

```powershell
# Container durumunu kontrol et
.\manage.ps1 status dev n8n

# Logları incele
.\manage.ps1 logs dev n8n

# Healthcheck durumu
docker inspect n8n_dev --format='{{json .State.Health}}'
```

### Webhook'lar Çalışmıyor

`WEBHOOK_URL` değişkeninin dışarıdan erişilebilir bir adres olduğundan emin olun. Dev ortamında `ngrok` veya benzeri bir tünel aracı kullanabilirsiniz:

```powershell
# ngrok ile tünel aç
ngrok http 5678

# Sonra .env içinde WEBHOOK_URL'i güncelle:
# WEBHOOK_URL=https://xxxx.ngrok.io/
.\manage.ps1 restart dev n8n
```

### Kimlik Bilgileri Çözülemiyor

`N8N_ENCRYPTION_KEY` değiştirilmiş olabilir. Mevcut kimlik bilgileri artık çözülemez. Tüm kimlik bilgilerini n8n UI üzerinden sıfırlayın ve yeniden girin.

## 📚 Ek Kaynaklar

- [n8n Resmi Dokümantasyonu](https://docs.n8n.io/)
- [n8n Docker Kurulumu](https://docs.n8n.io/hosting/installation/docker/)
- [n8n Node Kütüphanesi](https://docs.n8n.io/integrations/)
- [n8n Şifreli Kimlik Bilgileri](https://docs.n8n.io/credentials/)
- [n8n Webhook Kullanımı](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
